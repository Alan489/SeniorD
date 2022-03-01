import cc.arduino.*;
import org.firmata.*;
import grafica.*;
import g4p_controls.*;
import processing.serial.*;


int guiFrameRate=40; //refresh rate of plots and controls
Arduino arduino; // Arduino class, arduino instance?
int timeelapsed;
float xpos, ypos, zpos; 
boolean plotted =false;
boolean resetLimit=false;
int next=0;
float R=10000;
float RT=5000;
int BC = 3950;
Table table;
//ArrayList<String> tableHeadings= new ArrayList<String>(); //not used yet, likely unnecessary to change live
GPlot MSEplot, radiusplot;
GPointsArray MSEpoints1, MSEpoints2;
GPointsArray radiuspoints1, radiuspoints2;
GLayer layer1, layer2;

int A0=540;
int A1, A2;
float A12;
int A8;
float freq;
float newfreq;
float avefreq;
float measuredPeriod;
boolean touch;
boolean moving;
float lastDepth; //used for radius measurement assuming non uniform velocity
float pumpPeriod=0.0; 
float pumpDelay=0.0;
boolean pumpReverse=false;
float touchDownHeight=500;  //extractor starting point
float heightIce=500; //initial guess at ice location

// microstepping and kinematic values for the stepper motors (physical DIP switch setup) FOR KNOWING MAPPING FROM STEPS->MM OR INCH
int extractorMicroStepping=400; //physical DIP switch setting 
int drillMicroStepping=800; //physical DIP switch setting
int xMicroStepping=400; //physical DIP switch setting 
int yMicroStepping=400; //physical DIP switch setting
int pulleyCircumf=60; //circumference of pulley in mm, used to determine rotary to linear motion so 60mm travel per revolution
int extractorScrewPitch =5; //pitch in mm, used to determine rotary to linear motion in extractor
float drillScrewPitch = 3.175; //pitch in mm, used to determine rotary to linear motion in drill 
float stepsPerMmX=(float)xMicroStepping/pulleyCircumf; //for 1600PPR stepPerMm = 26.67, 200PPR stepPerMm = 3.33
float stepsPerMmY=(float)yMicroStepping/pulleyCircumf; //for 1600PPR stepPerMm = 26.67, 200PPR stepPerMm = 3.33
float stepsPerMmDrill=(float)drillMicroStepping/drillScrewPitch; //for 1600PPR stepPerMm = 504, 200PPR stepPerMm = 63
float stepsPerMmExtractor=(float)extractorMicroStepping/extractorScrewPitch; //for 1600PPR stepPerMm = 320, 200PPR=40 stepsPerMm
GTimer xStepperUpdate = new GTimer(this, this, "xStepperUpdate_event", 200);
GTimer yStepperUpdate= new GTimer(this, this, "yStepperUpdate_event", 200);
GTimer pumpDelayTimer= new GTimer(this, this, "pumpDelayTimer_event", 7700); //initial state of timer, can be updated in gui using calculator

//setup steppers using Stepper and MultiStepper classes
static final int XSTEPPER1 =0;
static final int YSTEPPER = 1;
static final int DRILL =2; // integers used for switch case under reporting
static final int EXTRACTOR = 3;

Stepper xStepper1 = new Stepper(XSTEPPER1, 6, 7, stepsPerMmX); //device, pulPin, dirPin, lowLimit, highLimit
Stepper yStepper = new Stepper(YSTEPPER, 10, 11, stepsPerMmY); //device, pulPin, dirPin, lowLimit, highLimit
Stepper drillStepper = new Stepper(DRILL, 9, 8, stepsPerMmDrill); //device, pulPin, dirPin, lowLimit, highLimit
Stepper extractorStepper = new Stepper(EXTRACTOR, 12, 13, stepsPerMmExtractor); //device, pulPin, dirPin, lowLimit, highLimit
int homingstep=-1;
boolean flip=true;
//int xToGo, yToGo, extractorToGo, drillToGo; // remaining steps from current location to desired location, calculated on change events for desired x, y, z
int drillRPMpin = 2; //interrupt at pin 2 for measuring RPM of drill, used during drilling for control
int pumpRPMpin = 3; //interrupt at pin 3 for measuring RPM of pump just to verify setting
int extractorTouchPin = 53; 
float lastTouch;
float desiredLoad;
int waterSensorPin = 49;
int SCL = 21;
int SDA = 20;
/*
Analog inputs
 */
int loadCellPin = 0; 
int thermistorPin = 8; 
int overallCurrentPin = 12;
int acDrillCurrentPin = 10; //need to add to gui
int dcDrillCurrentPin = 6; //change  
int acDrillVoltagePin = 4; //change from 15
/*
limit switch pins
 */
int drillHomePin = 46;
//int drillLimitPin = 47;
int pumpReversePin = 35;

int xHomePin = 42;
//int xLimitPin = 44;
int yHomePin = 40;
int yLimitPin = 41;
int extractorHomePin = 45;
int extractorLimitPin = 43; 


/*
  values used to calculate MSE from sensor data
 */
float HP;
float T; 
float ROP;
float eff = 0.427f;
float PF = 0.94f;
float loadCellValue;
float acDrillVoltage;
float acDrillCurrent;
float dcDrillCurrent;
float torqueValue;
float MSE;

//relay pins and states used to restrict devices during startup / other processes
Relay drillRelay = new Relay(25); 
Relay extraRelay = new Relay(24);
Relay pumpRelay = new Relay(26); //relays are energized low instead of high 
SolidStateRelay heaterRelay = new SolidStateRelay(27); //solid state relay is energized high instead of low

float extTemp=0;
int tablename = 0;  // used to specify the timestamp for csv files
ArrayList<Hole> previousHoles = new ArrayList<Hole>();
int hour; //placeholder for the current hour
String ampm ="AM"; //variable for the display of AM vs PM
int minutesRemain; //used for determining extractor feed
float xOffset=132.6f; //offset distance between drill and extractor
float yOffset=12.1f; //offset distance between drill and extractor
float currentX;
float currentY;
float desiredX;
float desiredY;
int desiredDepth; 
float drillFeed;
float extractorFeed;
float extractorTouchSpeed;
float xSpeed;
float ySpeed;
float drillRPM;
float flowRate;
int reportDevice=-1; // used to hold the device that was reported by the accelStepper report
int reportSteps=0; // used as a placeholder for the reported steps from accelStepper
int stepperComplete=-1; // used as a placeholder for the previous stepper to complete a move (could be used to automate movements)
int lastStepperComplete = -1; // saves last completed move
int moveFlag=-1;

public void setup() {
  size(1750, 800, JAVA2D);
  surface.setLocation(100, 0);

  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0]); //instantiates an arduino class on the first element in list of COM ports

  for (int i = 4; i < 54; i++) {    //must start after the TX and RX digital pins. Their pinmode cannot be changed as they are used for communication
    arduino.pinMode(i, Arduino.OUTPUT);
  }

  arduino.pinMode(extractorTouchPin, Arduino.INPUT); // used for extractor touch sensor
  arduino.pinMode(waterSensorPin, Arduino.INPUT); // used for water level sensor
  arduino.pinMode(20, Arduino.I2C); //used for DAC pump / drill control
  arduino.pinMode(21, Arduino.I2C); //used for DAC pump / drill control
  arduino.pinMode(2,Arduino.INPUT);
  arduino.pinMode(3,Arduino.INPUT);
  /*
  configures the relays by sending commands to arduino
   */
  heaterRelay.off();
  drillRelay.off();
  pumpRelay.off();
  //extraRelay.off();  

  println("Steps per mm: x, y, drill, extractor");
  println(nf(stepsPerMmX)+","+nf(stepsPerMmY)+","+nf(stepsPerMmDrill)+","+nf(stepsPerMmExtractor));

  createGUI();
  customGUI();
}

public void draw() {
  background(255); 
  frameRate(guiFrameRate); //refresh rate in Hz for both graphs and captured files

  //  read data from Arduino
  measuredPeriod=arduino.periodRead();

  freq=arduino.freqRead(); //checks for updates from sysex messages from the arduino for both drill RPM and pump RPM

  //if (newfreq!=freq) {
  //  avefreq=(newfreq+freq)/2; //takes average of values when there is change in reporting, should only run when value changes
  //}
  //freq=newfreq; //

  reportSteps=arduino.stepsRead(); //checks for updates from sysex messages from the arduino
  reportDevice = arduino.deviceRead(); // gets the most recent value from the report
  moveFlag = arduino.checkMoveFlag();
  arduino.pinMode(SCL, Arduino.I2C); //used for DAC pump / drill control
  arduino.pinMode(SDA, Arduino.I2C); //used for DAC pump / drill control

  loadCellValue = map(arduino.analogRead(loadCellPin), 218, 350, 0.0, 91.14); 

  A8 = arduino.analogRead(thermistorPin); //need to wire in to controller
  //A12 = map(arduino.analogRead(dcDrillCurrentPin), 380, 657, -5.0f, 5.0f); //overall current sensor
  dcDrillCurrent = map(arduino.analogRead(dcDrillCurrentPin), 380, 657, -5.0f, 5.0f); //drill current sensor
  acDrillCurrent = map(arduino.analogRead(acDrillCurrentPin), 196, 982, 0.0, 10.0);
  acDrillVoltage = map(arduino.analogRead(acDrillVoltagePin), 196, 982, 0.0, 120.0);
  drillFeed=drillFeed_textbox.getValueF();
  desiredDepth=desiredDepth_textbox.getValueI();
  extractorFeed=extractorFeed_textbox.getValueF()/60.0;
  xSpeed=xSpeed_textbox.getValueF();
  ySpeed=ySpeed_textbox.getValueF();
  extractorTouchSpeed=extractorTouchSpeed_textbox.getValueF();
  currentX=map(slider2d1.getValueXF(), -140, 140, 0.0f, 500f); //used for offset calculation later
  currentY=map(slider2d1.getValueXF(), -20.0, 20.0, 0.0f, 75f);
  drillRPM=drillRPM_textbox.getValueF();
  flowRate=flowRate_textbox.getValueF();
  desiredX=desiredX_textbox.getValueF();
  desiredY=desiredY_textbox.getValueF();
  desiredLoad=desiredLoad_textbox.getValueF();

  //println(currentX);
  /*
  this part calculates MSE based on data from drill / steppers
   */
  HP=(acDrillVoltage*acDrillCurrent*eff*PF*1.73)/746; //horsepower of drilling operation NEED to figure out efficiency of motor controller
  T=HP*63025.0/drillRPM; //this uses the user setting for RPM not the sensed value NEED to test
  ROP=60*drillScrewPitch/25.4*drillFeed; //ROP is in/hour
  MSE=(loadCellValue/4.448/0.994)+(2*PI*drillRPM*T)/(0.994*ROP);
  /*
  this part checks the temperature sensor. it is set to A0 because I was testing at home. robot should be A8
   */
  RT = R/(1023.0/A8-1.0);
  extTemp = log(RT/R)/BC+1/(25+273.15);
  extTemp = 1/extTemp-273.15; //if we see -273.15 on the display it means we are getting zero volts or a short across thermistor
  temperature.setText(nf(extTemp, 0, 1));
  /*
  this is where the extractor is running, 
   
   first block controls heater
   second block controls z position
   third block controls pump
   
   NEED TO TEST
   */
  if (engageExtractor.isSelected()) {
    if (extTemp>90 | !heater_checkbox.isSelected()) { //measured in degrees Celcius
      heaterRelay.off();
    } else if (extTemp<80 & heaterRelay.state==0) { //This caused a ton of oscillation and potential fatigue of heater
      heaterRelay.on();
    }
    // extractor engage starts with: motors stopped, touch==true, moving==false
    if (arduino.digitalRead(extractorTouchPin)==0 & !moving) { //after it melts down
      extractorStepper.setSpeed(extractorFeed); //converted to mm/s 
      extractorStepper.to(desiredDepth); //converted to mm/s using steps/mm
      moving=true;
      touch=false;
    } else if (arduino.digitalRead(extractorTouchPin)==1 & moving) { //when it touches
      message.setText("Extractor has touched down, stopping motor");
      touchDownHeight=extractorZ.getValueF();
      heightIce=1000.0-touchDownHeight;
      extractorStepper.halt();
      moving=false;
      touch=true;
    }

    // this bit controls pump and calculates radius
    //if (arduino.digitalRead(waterSensorPin)== 1 & pumpRelay.getState()==0) { //first pump event when first reading
    //  timeelapsed=millis(); //store time when water level sensor reads water for the first time
    //  pumpRelay.on(); // first time pump is turned on and it will run until water sensor triggers then the if statement above will run for remainder of extraction
    //  lastDepth=extractorZ.getValueF();
    //} else if (arduino.digitalRead(waterSensorPin)== 0 & pump_checkbox.isSelected() &!pumpDelayTimer.isRunning()) { //pump trigger
    //  //pump delay timer is not running initially 
    //  pumpPeriod=(millis()-timeelapsed)/1000.0;
    //  periodMeasured.setText(nf(pumpPeriod, 0, 1)); //measure period in seconds using previous value of timeelapsed and current millis
    //  radiusMeasured.setText(nf(sqrt(flowRate*(pumpPeriod-pumpDelay)/PI/(extractorZ.getValueF()-lastDepth))));
    //  timeelapsed=millis(); //get time when sensor changes to measure period next time
    //  pumpRelay.off();
    //  lastDepth=extractorZ.getValueF();
    //  pumpDelayTimer.setInterval(floor(pumpDelay*1000)); // interval for pump delay. measured in milliseconds
    //  pumpDelayTimer.start(1); // run timer to delay the turn on of pump
    //  //pumpDelayTimer_event turns pump on after pump delay
    //} else { //do nothing with water sensor until pump timer runs out
    //}
  }


  /*
  This sends a message in the console when a stepper completes motion
   */
  if (stepperComplete!=arduino.moveComplete()) {
    stepperComplete=arduino.moveComplete(); //checks for completed step sequence
    println("Stepper "+ stepperComplete + " completed its steps"); //this only prints when there is a change to this value. Useful to see last stepper
  }

  /*
  Only check for updates for _______ if we expect that to change. This reduces unnecessary messages between arduino and processing
   */
  if (touchDrill.isSelected() | engageDrill.isSelected() | Homing.isSelected() | removeDrill.isSelected()) {
    if (!drillStepper.reported) {
      drillStepper.report();
    }
    //println("drillstepper report");
  }
  if (touchExtractor.isSelected() | engageExtractor.isSelected() | Homing.isSelected() | removeExtractor.isSelected()) {
    if (!extractorStepper.reported) {
      extractorStepper.report();
    }
    //println("extractorstepper report");
  }
  if (positionDrill.isSelected() | positionExtractor.isSelected() | Homing.isSelected()) {
    if (!xStepper1.reported) {
      xStepper1.report();
    }
    if (!yStepper.reported) {
      yStepper.report();
    }
  }
    measuredDrillRPM.setText(nf(60.0*freq, 0, 0)); 
  //if (engageDrill.isSelected()) {  
  //  measuredDrillRPM.setText(nf(60.0*avefreq, 0, 0)); 
  //  torque.setText(nf(T, 0, 1)); //NEED TORQUE CALCULATION
  //} else {
  //  measuredDrillRPM.setText("N/A");
  //}
    //periodMeasured.setText(nf(measuredPeriod, 0, 2));
    pumpRPM.setText(nf(60.0*freq, 0, 0));
  //if (engageExtractor.isSelected()) {  
  //  periodMeasured.setText(nf(measuredPeriod, 0, 2));
  //  pumpRPM.setText(nf(60.0*avefreq, 0, 0));
  //} else {
  //  periodMeasured.setText("N/A");
  //  pumpRPM.setText("N/A");
  //}

  /*
  this next block of code checks limit switches and stops motors as end stops are reached
   NEED TEST
   
   */
  if (!Homing.isSelected() & !startup.isSelected() & !resetLimit) {

    if (arduino.digitalRead(yLimitPin)==0) {
      yStepper.halt();
      message.setText("Y limit reached, must reset limit by clicking reset limit button");
      println("Y limit reached, must reset limit by clicking reset limit button");
      resetLimit=false;
    }
    //if (arduino.digitalRead(xLimitPin)==0) {
    //  xStepper1.halt();
    //  resetLimit=false;
    //  message.setText("X limit reached, must reset limit by clicking reset limit button");
    //}
    //if (arduino.digitalRead(drillLimitPin)==0) {
    //  drillStepper.halt();
    //  resetLimit=false;
    //  message.setText("drill limit reached, must reset limit by clicking reset limit button");
    //}
    if (arduino.digitalRead(extractorLimitPin)==0) {
      extractorStepper.halt();
      resetLimit=false;
      message.setText("extractor limit reached, must reset limit by clicking reset limit button");
      println("extract limit reached, must reset limit by clicking reset limit button");
    }
  }

  for (int i=40; i<54; i++) { // not necessary, but shows a good way to visualize which limit switches. Adding a label or moving them to their locations could help
    arduino.pinMode(i, Arduino.INPUT);
    if (arduino.digitalRead(i)==1) {
      fill(0xFF00FF00);
    } else {
      fill(0xFFFF0000);
    }
    ellipse(790+20*(i-40), 560, 12, 12);
    fill(0);
    text(i, 782+20*(i-40), 550);
  }

  /*
  Homing sequence. Need to check limit switches and verify specific limit switches are hit before moving on to next stepper
   */
  if (Homing.isSelected()) {
    if (homingstep==0) { //checks to see if drill is home and what step of homing we are on
      homeDrill(); // run motor until limit switch gets hit
      homingstep=1; // makes sure that we only run homeDrill() once!
    } else if (arduino.digitalRead(drillHomePin)==0 & homingstep==1) { //verifies drill is home, extractor is not an d
      drillStepper.halt(); //this is required to stop drill at top of travel
      drillStepper.zero(); //this resets position of drill to home (zero)
      homeExtractor();
      homingstep=2; //makes sure we only run homeExtractor() once!
    } else if (arduino.digitalRead(extractorHomePin)==0 & arduino.digitalRead(drillHomePin)==0 & homingstep==2) {
      extractorStepper.halt();
      extractorStepper.zero();
      homeX();
      homingstep=3; //makes sure we only run homeX() once!
    } else if (arduino.digitalRead(extractorHomePin)==0 & arduino.digitalRead(drillHomePin)==0 & arduino.digitalRead(xHomePin)==0 & homingstep==3) {
      xStepper1.halt();
      xStepper1.zero();
      homeY();
      homingstep=4; //makes sure we only run homeY() once!
    } else if (arduino.digitalRead(extractorHomePin)==0 & arduino.digitalRead(drillHomePin)==0 & arduino.digitalRead(xHomePin)==0 & arduino.digitalRead(yHomePin)==0 & homingstep==4) {
      yStepper.zero();
      println("ALL MOTORS HAVE BEEN HOMED!");
      message.setText("ALL MOTORS HAVE BEEN HOMED!");
      homingstep=-1;
    }
  }
  /*
touchdown for drill
   */
  if (touchDrill.isSelected() & loadCellValue>desiredLoad & !touch) { //assumes drill is already moving down from touchDrill_requested under gui tab
    drillStepper.halt(); //stop drill when drill load is at the desiredload (overshoot may be possible)
    // this sets the flag so that this won't run again unless touchDrill_event is clicked again
    //should we rezero here? this will tell us the dimension measured from the top of the regolith
    message.setText("Drill has touched down, you can now engage drill");
    touch = !touch;
  }
  /*
touchdown for extractor
   */
  if (touchExtractor.isSelected() & arduino.digitalRead(extractorTouchPin)==1 & !touch) { // assumes extractor is already moving from touchExtractor_requested in gui tab
    extractorStepper.halt(); // stop drill when sensor is triggered

    //should we rezero here? this should tell us the dimension measured at the point of the ice ( check with drill feedback?)
    message.setText("Extractor has touched down at "+extractorZ+", you can now engage extractor");
    println(extractorZ);
    lastTouch= extractorZ.getValueF(); // define value for the first touchdown location
    touch= !touch;
  }
  // this command does formatting for the GUI frames
  drawBorders();

  fill(255);
  // update the clock 
  if (hour()<12) {
    ampm="AM"; 
    hour=hour();
  } else if (hour()>12) {
    hour=hour()-12; 
    ampm="PM";
  } else {
    hour=hour(); 
    ampm="PM";
  }
  currentTime.setText(nf(hour, 2)+":"+nf(minute(), 2)+ampm);
  //  minutesRemain = (15-hour())*60-minute(); //assuming a 3pm end to the day, uncomment this line for competition
  minutesRemain = 360; // used for testing, comment out for competition

  // update the GUI with values from Arduino  
  current.setText(nf(acDrillCurrent));     //gets value from current sensor and sets display value
  systemcurrent.setText(nf(dcDrillCurrent));
  loadcell.setText(nf(loadCellValue, 0, 1));     //gets value from load cell and sets display value
  torque.setText(nf(T, 0, 1));
  MSE_textbox.setText(nf(MSE, 0, 1));


  /*
  This is where the GUI display is updated when a stepper position is reported. 
   */

  switch (reportDevice) {
  case DRILL:
    drillZ.setText(nf(reportSteps/stepsPerMmDrill, 0, 1));
    //println("Drill reported "+reportSteps+" steps");
    break;
  case EXTRACTOR:
    extractorZ.setText(nf(reportSteps/stepsPerMmExtractor, 0, 1));
    //println("Extractor reported "+reportSteps+" steps");
    break;
  case YSTEPPER:
    stepperY.setText(nf(reportSteps/stepsPerMmY, 0, 1));
    //println("yStepper reported "+reportSteps+" steps");
    break;
  case XSTEPPER1:
    stepperX.setText(nf(reportSteps/stepsPerMmX, 0, 1));
    //println("xSteppers reported "+reportSteps+" steps");
    break;
  default:
    break;
  }


  // plot MSE data if "engage drilling" is selected and drill relay is on
  if ((engageDrill.isSelected() == true) | (removeDrill.isSelected()==true)) {
    if (!plotted & (engageDrill.isSelected() == true)) {
      MSEplot.addPoint(MSE, -reportSteps/stepsPerMmDrill, " ", "layer1");
      updateMSEtable();
      plotted=true;
    }

    plot(MSEplot, reportSteps, stepsPerMmDrill, MSE); //only plot points at timer interval
  }

  // plot radius / extraction data if "engage extractor" is selected  and heater relay is on (maybe change?)   
  if ((engageExtractor.isSelected() == true) | (removeExtractor.isSelected()==true)) {
    if (!plotted & (engageExtractor.isSelected() == true)) {
      radiusplot.addPoint(radiusMeasured.getValueF(), -reportSteps/stepsPerMmExtractor, " ", "layer1");
      radiusplot.addPoint(-radiusMeasured.getValueF(), -reportSteps/stepsPerMmExtractor, " ", "layer2");
      updateRadiusTable();
      plotted=true;
    }
    plot(radiusplot, reportSteps, stepsPerMmExtractor, radiusMeasured.getValueF(), -radiusMeasured.getValueF());
  }
  /*
   // need to add a variable which attempts to sum up the total fluid that has been collected. 
   
   we can then use this to predict and correct for errors / check for leaks / clogs in tubing. 
   we could also measure pressure in lines but... we they need to get a pressure sensor with the right sensitivity and range
   
   */
}//END OF DRAW DO NOT REMOVE

public void xStepperUpdate_event(GTimer source) {
  xStepper1.reported=false;
}
public void yStepperUpdate_event(GTimer source) {
  yStepper.reported=false;
}
public void pumpDelayTimer_event(GTimer source) {
  pumpRelay.on();
  message.setText("pump turned on after pump delay");
}

public void customGUI() { //only run once at beginning of loop
  fill(250);
  timeRemain.setNumeric(0.0f, 360.0f, 1.0f);
  heightIce_textbox.setNumeric(0.0f, 500.0f, 0.0f);
  hres.setNumeric(0.0f, 10.0f, 5.0f);
  drillZ.setNumeric(0.0f, 500f, 0.0f);
  desiredX_textbox.setNumeric(0.0f, 508f, 0.0f);
  desiredY_textbox.setNumeric(0.0f, 127f, 0.0f);
  pumpDelay_textbox.setNumeric(0f, 300.0f, 0.1f);
  loadcell.setNumeric(0, 1023, 0);
  drillRPM_textbox.setNumeric(0, 540.0, 360.0); 
  flowRate_textbox.setNumeric(0, 540, 150); //flow rate as integer
  xSpeed_textbox.setNumeric(1.0f, 30.f, 1.0f); //need to set reasonable limits to the stepper speed based on in/min or some other limit
  ySpeed_textbox.setNumeric(1.0f, 30.f, 1.0f); //need to set reasonable limits to the stepper speed based on in/min or some other limit and specific kinematics
  drillFeed_textbox.setNumeric(0.0f, 30.f, 5.f); //need to set reasonable limits to the stepper speed based on in/min or some other limit and specific kinematics
  maxRadius.setNumeric(0.0f, 19.0f, 17.5f); //in cm
  periodMeasured.setNumeric(0.0f, 100000.0f, 1.f); 
  measuredDrillRPM.setNumeric(0.0f, 540.0f, 0.0f);
  extractorFeed_textbox.setNumeric(0.000f, 100.f, 1.4f);
  desiredDepth_textbox.setNumeric(-1000, 1000, 0); //can only be positive after homed, negative values indicate homing is required
  stepperX.setNumeric(0.0f, 590.0f, 0.0f); //after homed this can only be positive , negative values indicate homing is required
  stepperY.setNumeric(0.0f, 64.0f, 64.0f); //after homed this can only be positive , negative values indicate homing is required
  desiredLoad_textbox.setNumeric(0.0f, 120.0f, 5.0f); //sets the default value of load to 5N if outside the range 0-120N
  meltRate.setNumeric(0.0f, 140.f, 135.0f);
  torque.setNumeric(0.0, 200.0, 0.0);
  desiredLoad_textbox.setText(nf(5.0));
  extractorFeed_textbox.setText(nf(500 / 360, 0, 3));
  MSE_textbox.setNumeric(0.0, 10000.0, 0.0);
  pumpDelay=5*60*360 / 500*(1-135/140); // set pump delay value based on GUI values
  pumpDelay_textbox.setText(nf(pumpDelay, 0, 1));  //calculates delay for radius measurement based on melt rate, period and flow rate
  hdot.setText(nf(500 / 360, 0, 3)); // calculates the rate of descent for the extractor based on time remaining and height of ice
  maxRadius.setText(nf(1/10.0*floor(sqrt(1000*135*360/500/PI)), 0, 1)); //calculates the maximum radius assuming 100% melt efficiency  
  //select frequency of updates in ms from accelstepper library
  drillStepperUpdate.setInterval(200);
  yStepperUpdate.setInterval(200);
  xStepperUpdate.setInterval(200);
  yStepperUpdate.setInitialDelay(100);
  extractorStepperUpdate.setInterval(500);  // 1 reading per second gives us 360*60=21600 data points for 6 hours
  pumpDelayTimer.setInterval(floor(pumpDelay*1000)); // interval for pump delay. measured in milliseconds
  message.setText("Startup mode. Go through homing before attempting \n");
  message.appendText(" any additional functions. If you recieve an error \n");
  message.appendText("verify that end limits are not triggered or ");
}

/*  
 This is where I define a few methods which help control the state of the arduino and the GUI as well as generate and control plots and files created by application
 */
public int timestamp() {
  int tablename=parseInt(nf(hour(), 2)+nf(minute(), 2)+nf(second(), 2));
  return tablename;
}
public void drilltouchmode() {

  drillStepperUpdate.start();
  drillStepper.setSpeed(drillFeed); //throw an error if drill speed doesn't change or stepper cannot be found in AccelStepper
  drillStepper.to(desiredDepth); //assuming we'll hit something before 0.5m down from top,
}
public void extractortouchmode() {
  drillStepperUpdate.stop();
  extractorStepperUpdate.start();
  extractorStepper.setSpeed(extractorFeed); //throw an error if drill speed doesn't change or stepper cannot be found in AccelStepper
  extractorStepper.to(desiredDepth); //assuming we'll hit something before 0.5m down from top,
}
public void extractormode() {
  heater_checkbox.setSelected(true);  
  heaterRelay.on();
  drill_checkbox.setSelected(false); 
  drillRelay.off(); 
  moving=false;
}
public void updateRadiusCalculator() {
  hdot.setText(nf(heightIce_textbox.getValueF() / timeRemain.getValueF(), 0, 3)); // calculates the rate of descent for the extractor based on time remaining and height of ice
  maxRadius.setText(nf(1/10.0*floor(sqrt(1000*meltRate.getValueF()*timeRemain.getValueF()/heightIce_textbox.getValueF()/PI)))); //calculates the maximum radius assuming 100% melt efficiency
  pumpDelay=hres.getValueF()*60*timeRemain.getValueF() / heightIce_textbox.getValueF()*(1-meltRate.getValueF()/flowRate);
  pumpDelay_textbox.setText(nf(pumpDelay, 0, 1));  //calculates delay for radius measurement based on melt rate, period and flow rate
}
public void positionX() {
  xStepper1.setSpeed(xSpeed); 
  xStepper1.to(desiredX);
}
public void positionY() {
  yStepper.setSpeed(ySpeed);
  yStepper.to(desiredY);
}

public void homeDrill() {
  drillStepperUpdate.start();
  drillStepper.setSpeed(30);
  drillStepper.to(-1000);
}

public void homeExtractor() {
  drillStepperUpdate.stop();
  extractorStepperUpdate.start();
  extractorStepper.setSpeed(5);
  extractorStepper.to(-1000);
}

public void homeX() {
  extractorStepperUpdate.stop();
  xStepperUpdate.start();
  xStepper1.setSpeed(30);
  xStepper1.to(-1000);
}

public void homeY() {
  xStepperUpdate.stop();
  yStepperUpdate.start();
  yStepper.setSpeed(30);
  yStepper.to(-500);
}

public void drillmode() {
  arduino.freqConfig(2, 3, 500); //configure the frequency measurement on pin 2 with a rising condition (3) and set the measurement interval to 0.5s
  engageDrill.setSelected(true);  
  heater_checkbox.setSelected(false);  
  heaterRelay.off();
  drill_checkbox.setSelected(true);  
  drillRelay.on();
  drillStepper.setSpeed(drillFeed);
  drillStepper.to(desiredDepth);
  println("Drill sent to " + nf(desiredDepth));
  drillStepperUpdate.start(); // start the frequency measurement
}

public void drawBorders() {
  strokeWeight(3);
  noFill();
  rect(0, 0, 1200, 800);
  rect(0, 0, 508, 300);
  rect(0, 0, 270, 300);
  rect(0, 300, 1200, 230);  
  rect(0, 300, 809, 230);
  rect(0, 300, 420, 230);
  rect(0, 300, 210, 230);
  rect(0, 530, 1200, 300);
  rect(0, 530, 770, 300);
  rect(0, 530, 440, 300);
  strokeWeight(3);
  fill(255);

  rectMode(CENTER);
  rect(940, 135, 500, 250); // Test bed outline
  noFill();
  // ellipse that follows drill location and scales to the size of the calculated radius
  ellipse(slider2d1.getValueXF()+940, slider2d1.getValueYF()+135, 2*maxRadius.getValueF()*500/2.54/36, 2*maxRadius.getValueF()*500/2.54/36); 
  /*
  ellipse marking previous drill location, we can expand this to include additional holes upon day 2. we can even save and load a file here
   additionally we can have it get the maximum radius from the previous extraction data
   */
  for (Hole hole : previousHoles) {
    hole.display();
  }
  rectMode(CORNER);
  fill(250);
  strokeWeight(1);
}

public void allOff() {
  drillStepper.halt();
  extractorStepper.halt();
  yStepper.halt();
  xStepper1.halt();
  drillStepperUpdate.stop();
  extractorStepperUpdate.stop();
  yStepperUpdate.stop();
  xStepperUpdate.stop();
  drill_checkbox.setSelected(false);
  heater_checkbox.setSelected(false);  // maybe have the relay state affect the checkbox?
  pump_checkbox.setSelected(false);
  heaterRelay.off();
  drillRelay.off();
  pumpRelay.off();
  //extraRelay.off();
}

public void reportStepper() {
  stepperComplete=-1;
}

public void plot(GPlot source, int steps, float scale, int value) {
  //source.addPoint(value, -steps/scale, "  ", "layer1");
  source.beginDraw(); 
  source.drawBackground(); 
  source.drawBox(); 
  source.drawXAxis(); 
  source.drawYAxis(); 
  source.drawTitle(); 
  source.drawGridLines(GPlot.BOTH); 
  source.drawLines(); 
  source.endDraw();
}
// overloaded method for the option for two plot series
public void plot(GPlot source, int steps, float scale, int value1, int value2) {
  source.addPoint(value1, -steps/scale, " ", "layer1");
  source.addPoint(value2, -steps/scale, " ", "layer2");
  source.beginDraw(); 
  source.drawBackground(); 
  source.drawBox(); 
  source.drawXAxis(); 
  source.drawYAxis(); 
  source.drawTitle(); 
  source.drawGridLines(GPlot.BOTH); 
  source.drawLines(); 
  source.endDraw();
}
public void plot(GPlot source, int steps, float scale, float value) {
  //source.addPoint(value, -steps/scale, "  ", "layer1");
  source.beginDraw(); 
  source.drawBackground(); 
  source.drawBox(); 
  source.drawXAxis(); 
  source.drawYAxis(); 
  source.drawTitle(); 
  source.drawGridLines(GPlot.BOTH); 
  source.drawLines(); 
  source.endDraw();
}
// overloaded method for the option for two plot series
public void plot(GPlot source, int steps, float scale, float value1, float value2) {
  source.addPoint(value1, -steps/scale, " ", "layer1");
  source.addPoint(value2, -steps/scale, " ", "layer2");
  source.beginDraw(); 
  source.drawBackground(); 
  source.drawBox(); 
  source.drawXAxis(); 
  source.drawYAxis(); 
  source.drawTitle(); 
  source.drawGridLines(GPlot.BOTH); 
  source.drawLines(); 
  source.endDraw();
}
public void updateMSEtable() {
  TableRow newRow = table.addRow();
  newRow.setString("timestamp", nf(hour(), 2)+":"+nf(minute(), 2)+":"+nf(second(), 2)+"."+nf(millis()%1000, 3));
  newRow.setFloat("xpos", stepperX.getValueF());
  newRow.setFloat("ypos", stepperY.getValueF());
  newRow.setFloat("depth", drillZ.getValueF()); //accessing form values until available 
  newRow.setFloat("load", loadCellValue);
  newRow.setFloat("torque", T);
  newRow.setFloat("current", acDrillCurrent);
  newRow.setFloat("voltage", acDrillVoltage);
  newRow.setFloat("RPM", drillRPM);  //accessing form values until available
  newRow.setFloat("MSE", MSE);
  saveTable(table, "data/mse_data_"+tablename+".csv");
}
public void updateRadiusTable() {
  TableRow newRow = table.addRow();
  newRow.setString("timestamp", nf(hour(), 2)+":"+nf(minute(), 2)+":"+nf(second(), 2)+"."+nf(millis()%1000, 3));
  newRow.setFloat("xpos", stepperX.getValueF());
  newRow.setFloat("ypos", stepperY.getValueF());
  newRow.setFloat("depth", extractorZ.getValueF()); //accessing form values until available 
  newRow.setFloat("temperature", extTemp);
  newRow.setInt("heaterstate", heaterRelay.getState());
  newRow.setInt("pumpstate", pumpRelay.getState());
  newRow.setFloat("current", dcDrillCurrent);
  newRow.setFloat("radius", radiusMeasured.getValueF());  //accessing form values until available
  saveTable(table, "data/radius_data_"+tablename+".csv");
}
public void guiPositionEntry() {
  slider2d1.setValueX(map(desiredX, -132.6f, 500f, -140, 140));
  slider2d1.setValueY(map(desiredY, 0.0f, 75f, -20, 20));
  xStepper1.to(desiredX);
  yStepper.to(desiredY);
}

public void offsetExtractor() { //used to move extractor into position after removing drill
  //map(slider2d1.getValueXF(), -140, 140, 0.0f, 500f)
  slider2d1.setValueX(map(currentX+xOffset, 0.0f, 500.0f, -140, 140));
  slider2d1.setValueY(map(currentY+yOffset, 0.0f, 75f, -20, 20));
  println("currentY = " + currentY);
  println("yOffset = " + yOffset);
  println("Drill moved to ("+nf(currentX+xOffset) +","+nf(currentY+yOffset)+"), so extractor should be over drill hole");
  xStepper1.to(currentX+xOffset);
  yStepper.to(currentY+yOffset);
}

void exit() {
  println();

  allOff();

  println();
  println("=======================================================");
  println("========== MAIN WINDOW CLOSING ========================");
  println("=======================================================");
  super.exit();
}
