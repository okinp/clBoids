/*
 *  Flock.cpp
 *  clBoids_final
 *
 *  Created by Nikolas Psaroudakis on 4/6/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "Flock.h";
#include "ofMain.h"
#include "ofxOpenCL.h"
#include "ofxVectorMath.h"
#define numBoids 300
//#define nthread

typedef struct{
	float4 pos;
	float4 vel;
	float4 acc;
} Boid;


ofxOpenCL opencl;
ofxOpenCLKernel *kernelUpdate;
Boid boidsIn[numBoids];
Boid boidsOut[numBoids];
ofxDoubleBuffer<ofxOpenCLBuffer> clMemBoids;

Flock::Flock(){
	opencl.setupFromOpenGL();
	for(int i=0; i<numBoids; i++) {
		Boid &bIn = boidsIn[i];
		Boid &bOut = boidsOut[i];
		bIn.pos.set(ofRandomWidth(), ofRandomHeight(), 0, 0);
		bIn.vel.set(ofRandom(-1,1),ofRandom(0,2),0,0);
		bIn.acc.set(0, 0, 0, 0);
		bOut.pos.set(ofGetWidth()/2, ofGetHeight()/2, 0, 0);
		bOut.vel.set(0, 0, 0, 0);
		bOut.acc.set(0, 0, 0, 0);
	}
	opencl.loadProgramFromFile("flocking.cl");
	kernelUpdate = opencl.loadKernel("updateBoid");
	
	clMemBoids.getFront().initBuffer(sizeof(Boid) * numBoids, CL_MEM_READ_WRITE, boidsIn);
	clMemBoids.getBack().initBuffer(sizeof(Boid) * numBoids, CL_MEM_READ_WRITE, boidsOut);



}
void Flock::update(){
	kernelUpdate->setArg(0, clMemBoids.getFront().getCLMem());
	kernelUpdate->setArg(1, clMemBoids.getBack().getCLMem());
//	clarg_set_local(kernelUpdate,2, nthread * sizeof(Boid));
	//kernelUpdate->setArg(2, nthread*Boid.getCLMem());
	//kernelUpdate->run1D(numBoids,32);
	kernelUpdate->run1D(numBoids);

	clMemBoids.getFront().read(boidsIn, 0 ,sizeof(Boid) * numBoids  );
	clMemBoids.getBack().read(boidsOut, 0 ,sizeof(Boid) * numBoids  );
	clMemBoids.swap();   // ping-pong swapping takes place here	

}
void Flock::render(){
	opencl.finish();
	//glPointSize(3);
	//glColor3f(1.0f, 1.0f, 1.0f);
	//glBegin(GL_POINTS);
	int r=4;
	for(int i=0; i<numBoids; i++){
		glVertex2f(boidsOut[i].pos.x, boidsOut[i].pos.y);
		ofxVec3f vel=ofxVec3f(boidsOut[i].vel.x, boidsOut[i].vel.y, boidsOut[i].vel.z);
		float heading=-atan2(-vel.y, vel.x);
		float theta=heading+ofDegToRad(90);
		theta=ofRadToDeg(theta);
		ofFill();
		ofSetColor(175, 175, 175);
		ofPushMatrix();
		ofTranslate(boidsOut[i].pos.x,boidsOut[i].pos.y);
		ofRotateZ(theta);
		ofBeginShape();
		ofVertex(0, -r*2);
		ofVertex(-r, r*2);
		ofVertex(r, r*2);
		ofEndShape();
		ofPopMatrix();
		//
		ofNoFill();
		ofSetColor(0, 0, 0);
		ofPushMatrix();
		ofTranslate(boidsOut[i].pos.x,boidsOut[i].pos.y);
		ofRotateZ(theta);
		glBegin(GL_LINE_LOOP);
		glVertex2d(0, -r*2);
		glVertex2d(-r, r*2);
		glVertex2d(r, r*2);
		glEnd();
		ofPopMatrix();
		
		
		
		
	}
	//glEnd();
}