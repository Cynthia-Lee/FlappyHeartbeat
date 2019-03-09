/*
THIS PROGRAM WORKS WITH PulseSensorAmped_Arduino ARDUINO CODE
THE PULSE DATA WINDOW IS SCALEABLE WITH SCROLLBAR AT BOTTOM OF SCREEN
PRESS 'S' OR 's' KEY TO SAVE A PICTURE OF THE SCREEN IN SKETCH FOLDER (.jpg)
PRESS 'R' OR 'r' KEY TO RESET THE DATA TRACES
MADE BY JOEL MURPHY AUGUST, 2012
UPDATED BY JOEL MURPHY SUMMER 2016 WITH SERIAL PORT LOCATOR TOOL
UPDATED BY JOEL MURPHY WINTER 2017 WITH IMPROVED SERIAL PORT SELECTOR TOOL

THIS CODE PROVIDED AS IS, WITH NO CLAIMS OF FUNCTIONALITY OR EVEN IF IT WILL WORK
      WYSIWYG
*/

import processing.serial.*;  // serial library lets us talk to Arduino
PFont font;
PFont portsFont;
Scrollbar scaleBar;

PImage sprite;

Serial port;

int Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawY;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledY;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rate;      // USED TO POSITION BPM DATA WAVEFORM
float zoom;      // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
float offset;    // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
color eggshell = color(255, 253, 248);
int heart = 0;   // This variable times the heart image 'pulse' on screen
//  THESE VARIABLES DETERMINE THE SIZE OF THE DATA WINDOWS
int PulseWindowWidth = 1350;
int PulseWindowHeight = 850;
int BPMWindowWidth = 300;
int BPMWindowHeight = 650;
boolean beat = false;    // set when a heart beat is detected, then cleared when the BPM graph is advanced
Player p;

// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

void setup() {
  size(1800, 950);  // Stage size
  frameRate(100);
  noSmooth();
  font = loadFont("Arial-BoldMT-24.vlw");
  p = new Player();
  sprite = loadImage("heart.png");
  textFont(font);
  textAlign(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);
// Scrollbar constructor inputs: x,y,width,height,minVal,maxVal
  scaleBar = new Scrollbar (700, 925, 180, 12, 0.5, 1.0);  // set parameters for the scale bar
  RawY = new int[PulseWindowWidth];          // initialize raw pulse waveform array
  ScaledY = new int[PulseWindowWidth];       // initialize scaled pulse waveform array
  rate = new int [BPMWindowWidth];           // initialize BPM waveform array
  zoom = 0.5;                               // initialize scale of heartbeat window

 // set the visualizer lines to 0
 resetDataTraces();

 background(255,204,0);
 // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES
 drawDataWindows();
 drawHeart();

// GO FIND THE ARDUINO
  fill(eggshell);
  text("Select Your Serial Port",245,30);
  listAvailablePorts();

}

void draw() {
if(serialPortFound){
  // ONLY RUN THE VISUALIZER AFTER THE PORT IS CONNECTED
  background(255,204,0);
  noStroke();
  drawDataWindows();
  drawPulseWaveform();
  drawPulseMirrorform();
  drawBPMwaveform();
  drawHeart();
  image(sprite, 50, p.ycor, 50, 50);
  p.checkCollisions();
  p.move();
  p.drag();
  if(p.dead){
    noLoop();
    fill(0);
    textFont(font,40);
    text("Press R to restart", 650,500);
    textFont(font,25);
  }
// PRINT THE DATA AND VARIABLE VALUES
  fill(50,50,50);                                       // get ready to print text
  text("Flappy Heartbeat",150,30);    // tell them what you are
  fill(255);
  text("IBI " + IBI + "mS",1525,890);  // print the time between heartbeats in mS
  textFont(font,40);
  fill(0);
  text(BPM + " BPM",1600,230);// print the Beats Per Minute
  textFont(font,25);
  text(" Scale " + nf(zoom,1,2), 525, 925); // show the current scale of Pulse Window

//  DO THE SCROLLBAR THINGS
  scaleBar.update (mouseX, mouseY);
  scaleBar.display();
} else { // SCAN BUTTONS TO FIND THE SERIAL PORT

  autoScanPorts();

  if(refreshPorts){
    refreshPorts = false;
    drawDataWindows();
    drawHeart();
    listAvailablePorts();
  }

  for(int i=0; i<numPorts+1; i++){
    button[i].overRadio(mouseX,mouseY);
    button[i].displayRadio();
  }

}

}  //end of draw loop


void drawDataWindows(){
    // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES
    noStroke();
    fill(eggshell);  // color for the window background
    rect(725,475,PulseWindowWidth,PulseWindowHeight);
    fill(50,50,50);
    rect(1600,575,BPMWindowWidth,BPMWindowHeight);
    
}

void drawPulseWaveform(){
  // DRAW THE PULSE WAVEFORM
  // prepare pulse data points
  RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
  zoom = scaleBar.getPos();                      // get current waveform scale value
  offset = map(zoom,0.5,1,150,0);                // calculate the offset needed at this scale
  for (int i = 0; i < RawY.length-1; i++) {      // move the pulse waveform by
    RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawY[i] * zoom + offset;       // adjust the raw data to the selected scale
    ScaledY[i] = constrain(int(dummy),44,400);   // transfer the raw data array to the scaled array
  }
  stroke(255,0,1);                               // red is a good color for the pulse waveform
  noFill();
  strokeWeight(5);
  beginShape();                                  // using beginShape() renders fast
  for (int x = 1; x < ScaledY.length-1; x++) {
    vertex(x+50,ScaledY[x]+400);                    //draw a line connecting the data points
  }
  endShape();
}

void drawPulseMirrorform(){
  // DRAW THE PULSE WAVEFORM
  // prepare pulse data points
  RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
  zoom = scaleBar.getPos();                      // get current waveform scale value
  offset = map(zoom,0.5,1,150,0);                // calculate the offset needed at this scale
  for (int i = 0; i < RawY.length-1; i++) {      // move the pulse waveform by
    RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawY[i] * zoom + offset;       // adjust the raw data to the selected scale
    ScaledY[i] = constrain(int(dummy),44,400);   // transfer the raw data array to the scaled array
  }
  stroke(0,0,250);                               // bloo
  noFill();
  strokeWeight(5);
  beginShape();                                  // using beginShape() renders fast
  for (int x = 1; x < ScaledY.length-1; x++) {
    vertex(x+50,(ScaledY[x]*-1)+550);                    //draw a line connecting the data points
  }
  endShape();
}

void drawBPMwaveform(){
// DRAW THE BPM WAVE FORM
// first, shift the BPM waveform over to fit then next data point only when a beat is found
 if (beat == true){   // move the heart rate line over one pixel every time the heart beats
   beat = false;      // clear beat flag (beat flag waset in serialEvent tab)
   for (int i=0; i<rate.length-1; i++){
     rate[i] = rate[i+1];                  // shift the bpm Y coordinates over one pixel to the left
   }
// then limit and scale the BPM value
   BPM = min(BPM,200);                     // limit the highest BPM value to 200
   float dummy = map(BPM,0,200,555,215);   // map it to the heart rate window Y
   rate[rate.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
 }
 // GRAPH THE HEART RATE WAVEFORM
 stroke(250,0,0);                          // color of heart rate graph
 strokeWeight(2);                          // thicker line is easier to read
 noFill();
 beginShape();
 for (int i=0; i < rate.length-1; i++){    // variable 'i' will take the place of pixel x position
   vertex(i+1450, rate[i]+300);                 // display history of heart rate datapoints
 }
 endShape();
}

void drawHeart(){
  // DRAW THE HEART AND MAYBE MAKE IT BEAT
    fill(250,0,0);
    stroke(250,0,0);
    // the 'heart' variable is set in serialEvent when arduino sees a beat happen
    heart--;                    // heart is used to time how long the heart graphic swells when your heart beats
    heart = max(heart,0);       // don't let the heart variable go into negative numbers
    if (heart > 0){             // if a beat happened recently,
      strokeWeight(8);          // make the heart big
    }
    smooth();   // draw the heart with two bezier curves
    bezier(width-200,70, width-110,0, width-110,160, width-200,180);
    bezier(width-200,70, width-300,0, width-290,160, width-200,180);
    strokeWeight(1);          // reset the strokeWeight for next time
}

void listAvailablePorts(){
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();
  fill(0);
  textFont(font,16);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  int yPos = 0;
  int xPos = 35;
  for(int i=serialPorts.length-1; i>=0; i--){
    button[i] = new Radio(xPos, 95+(yPos*20),12,color(180),color(80),color(255),i,button);
    text(serialPorts[i],xPos+15, 100+(yPos*20));

    yPos++;
    if(yPos > height-30){
      yPos = 0; xPos+=200;
    }
  }
  int p = numPorts;
   fill(233,0,0);
  button[p] = new Radio(35, 95+(yPos*20),12,color(180),color(80),color(255),p,button);
    text("Refresh Serial Ports List",50, 100+(yPos*20));

  textFont(font);
  textAlign(CENTER);
}

void autoScanPorts(){
  if(Serial.list().length != numPorts){
    if(Serial.list().length > numPorts){
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;	// was serialPorts.length
      serialPorts = expand(serialPorts,diff);
      numPorts = Serial.list().length;
    }else if(Serial.list().length < numPorts){
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
}

void resetDataTraces(){
  for (int i=0; i<rate.length; i++){
     rate[i] = 555;      // Place BPM graph line at bottom of BPM Window
    }
  for (int i=0; i<RawY.length; i++){
     RawY[i] = height/2; // initialize the pulse window data line to V/2
  }
}
  
