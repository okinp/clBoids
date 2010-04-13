/*
 *  flocking.cl
 *  clBoids_final
 *
 *  Created by Nikolas Psaroudakis on 4/7/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#define	numBoids 300
#define separateDist 14  //separateDist 
#define alignDist 40 //alignDist 
#define cohereDist 15   //cohereDist
#define maxspeed 10.0f
#define maxforce 2
#define width 1024
#define height 768
 
typedef struct{
	float4 pos;
	float4 vel;
	float4 acc;
} Boid;

float getMagnitudeSquared(float4 In){
	return In.x*In.x+In.y*In.y+In.z*In.z;
}
float4 limit(float4 In, float max){
	float mag = sqrt(getMagnitudeSquared(In));
	if (mag > max && mag >0){
		float scale=max/sqrt(3.0)/mag;
		In=scale*In;
		return In;
	} else {
		return In;
		}
}
float4 steer(float4 target, Boid bInA, bool slowdown){
	float4 steer= (float4)(0.0f,0.0f,0.0f,0.0f);
	float4 desired = target - bInA.pos;
	float d= sqrt(getMagnitudeSquared(desired));
	if (d>0){
		desired=desired/sqrt(getMagnitudeSquared(desired)); //normalise
		if (slowdown && d<100.0){
		float scale=maxspeed*d/100;
		desired=scale*desired;
	} else {
		float max=maxspeed;
		desired=max*desired;
		}
	steer=desired-bInA.vel;
	steer=limit(steer,maxforce);
} else {
	steer.x=0;
	steer.y=0;
	steer.z=0;
	steer.w=0;
}
return steer;
}

float4 seperate(float dist, Boid bInA, Boid bInB, float4 steer){
	if (dist>0 && dist<separateDist){
		float4 diff=bInA.pos-bInB.pos;
		float mag=getMagnitudeSquared(diff);
		diff=diff/sqrt(mag); //Normalize
		diff=diff/dist;
		diff.w=1;   //needed since we want steer.w to increment by 1 and act as a counter
		steer=steer+diff;
	}
	return steer;
}

float4 align(float dist, Boid bInA, Boid bInB, float4 steer){
	if (dist>0 && dist < alignDist){
		bInB.vel.w=1;
		steer+=bInB.vel;
	}
	return steer;
}
float4 cohere(float dist, Boid bInA, Boid bInB, float4 steerCoh){
	if (dist>0 && dist < cohereDist){
		bInA.pos.w=1; //used as counter increment
		steerCoh=steerCoh+bInA.pos;
	}
	return steerCoh;
}


//__kernel void updateBoid(__global Boid* boidsIn, __global Boid* boidsOut, __local Boid* pblock) {
__kernel void updateBoid(__global Boid* boidsIn, __global Boid* boidsOut) {

	int id = get_global_id(0);
	int ti = get_local_id(0);
	int n = get_global_size(0);
	int nt = get_local_size(0);
	int nb = n/nt;
	
	
	
	
	
	float4 steerSeperate=(float4)(0.0f,0.0f,0.0f,0.0f);
	float4 steerCohere=(float4)(0.0f,0.0f,0.0f,0.0f);
	float4 steerAlign=(float4)(0.0f,0.0f,0.0f,0.0f);
	steerSeperate.w=0; //reset counter
	steerCohere.w=0;	//reset counter
	steerAlign.w=0; //reset counter
	
	
	for (int i=id+1; i<numBoids; i++){
	//for(int jb=0; jb < nb; jb++) {    //**
		//pblock[ti]=boidsIn[jb*nt+ti]; //cache 1 boid  //*
		//barrier(CLK_LOCAL_MEM_FENCE); //wair for others  //*
		//for(int j=0; j<nt; j++) { //*
		//Boid b2=pblock[j]; //*
		//float4 d= boidsIn[id].pos-b2.pos;
		float4 d=boidsIn[id].pos-boidsIn[i].pos;//
		float dist=sqrt(getMagnitudeSquared(d));
		steerAlign=align(dist, boidsIn[id],boidsIn[i], steerAlign);//*
		//steerAlign=align(dist, boidsIn[id],b2, steerAlign);
		//steerSeperate=seperate(dist, boidsIn[id],b2, steerSeperate);
		steerSeperate=seperate(dist, boidsIn[id],boidsIn[i], steerSeperate);
		//steerCohere=cohere(dist, boidsIn[id],b2, steerCohere);
		steerCohere=cohere(dist, boidsIn[id],boidsIn[i], steerCohere);
		//barrier(CLK_LOCAL_MEM_FENCE);
		}
	//barrier(CLK_LOCAL_MEM_FENCE);
	//}
	//Seperation Code outside the loop follows
	if (steerSeperate.w>0){
		steerSeperate=steerSeperate/steerSeperate.w;
		}
	float magSep=getMagnitudeSquared(steerSeperate);
	if (magSep>0){
		steerSeperate=steerSeperate/sqrt(magSep); //normalise
		float max=maxspeed;
		steerSeperate=max*steerSeperate;
		steerSeperate=steerSeperate-boidsIn[id].vel;
		steerSeperate=limit(steerSeperate,maxforce);
		}
	//Coherence Code outside the loop follows
	if (steerCohere.w>0){
		steerCohere=steerCohere/steerCohere.w;
		steerCohere=steer(steerCohere,boidsIn[id],false);
	} 
	//Aligment Code outside loop follows
	if (steerAlign.w>0) {
		steerAlign=steerAlign/steerAlign.w;
	}
	float magAli=getMagnitudeSquared(steerAlign);
	if (magAli>0){
		steerAlign=steerAlign/sqrt(magAli); //normalise
		steerAlign=maxspeed*steerAlign;
		//float max= maxspeed;
		steerAlign=steerAlign-boidsIn[id].vel;
		steerAlign=limit(steerAlign,maxforce);
	}
	
	//
	boidsOut[id].acc=steerCohere+steerSeperate+steerAlign;
	boidsOut[id].vel=boidsIn[id].vel+boidsOut[id].acc;
	boidsOut[id].vel=limit(boidsOut[id].vel,10);  //limit velocity
	boidsOut[id].pos=boidsIn[id].pos+boidsOut[id].vel;
	if(boidsOut[id].pos.x>width) {boidsOut[id].pos.x=0;}
	if(boidsOut[id].pos.x<0) {boidsOut[id].pos.x=width;}
	if(boidsOut[id].pos.y>height) {boidsOut[id].pos.y=0;}
	if(boidsOut[id].pos.y<0) {boidsOut[id].pos.y=height;}
}
	
	

