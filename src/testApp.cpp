#include "testApp.h"


//--------------------------------------------------------------
void testApp::setup(){
	ofSetWindowTitle("template project");

	//ofSetFrameRate(60); // if vertical sync is off, we can go a bit fast... this caps the framerate at 60fps.
	ofBackground(0, 0, 0);
	//ofSetBackgroundAuto(false);
}

//--------------------------------------------------------------
void testApp::update(){
	myFlock.update();
}

//--------------------------------------------------------------
void testApp::draw(){
	myFlock.render();
	glColor3f(1, 1, 1);
	string info = "fps: " + ofToString(ofGetFrameRate());
	ofDrawBitmapString(info, 20, 20);
	
}


//--------------------------------------------------------------
void testApp::keyPressed  (int key){
	if (key == 'f'){
		ofToggleFullscreen();
	}
}

//--------------------------------------------------------------
void testApp::keyReleased  (int key){

}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){
}


//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}
