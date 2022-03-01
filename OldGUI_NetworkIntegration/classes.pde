class Stepper {
  boolean state;
  float stepsPerMm; // used to scale float inputs
  int deviceNum;
  int pulPin;
  int dirPin;
  boolean reported;
  boolean configured;
  boolean homed;

  Stepper(int _deviceNum, int _pulPin, int _dirPin, float _stepsPerMm) { //second constructor to be used with MultiStepper class which specifies its own limit pins
    this.deviceNum=_deviceNum;
    this.pulPin=_pulPin;
    this.stepsPerMm = _stepsPerMm;
    this.dirPin=_dirPin;
    this.reported = false;
    this.configured = false;
  }
  void config() { //should config go inside constructor? I"m not sure on this one...
    arduino.pinMode(pulPin, Arduino.OUTPUT);
    arduino.pinMode(dirPin, Arduino.OUTPUT);
    arduino.asConfig(deviceNum, pulPin, dirPin);
    this.configured=true;
    this.homed=false;
  }

  void step(float relative) {
    arduino.asStep(deviceNum, (int)(relative*stepsPerMm));
  }
  void to(float location) {
    println("Stepper "+deviceNum+" move to: " + (int)(location*stepsPerMm));
    arduino.asTo(deviceNum, (int)(location*stepsPerMm));
  }
  void to(int location) {
    println("Stepper "+deviceNum+" move to: " + (int)(location*stepsPerMm));
    arduino.asTo(deviceNum, (int)(location*stepsPerMm));
  }

  void report() {
    if (this.reported==false) {
      arduino.asReport(deviceNum);
      this.reported=true;
    }
  }
  void setSpeed(float speed) {
    arduino.asSetSpeed(deviceNum, speed*stepsPerMm);
    println("Stepper " +deviceNum+" was set to a speed of "+speed*stepsPerMm);
  }

  void halt() { //command for stopping stepper ( stop() is taken by system)
    arduino.asStop(deviceNum);
    this.state=false;
  }

  void zero() {
    arduino.asZero(deviceNum); //sets the zero location for the stepper. we'll call this when we home.
    this.homed = true;
  }
}

class MultiStepper {
  boolean state; //use this to see if move is complete and add a getState() method to increment movements
  int groupNum;
  int deviceNum1;
  int deviceNum2;
  float stepsPerMm;
  boolean reported;

  MultiStepper(int _groupNum, int _stepper1, int _stepper2, float _stepsPerMm) { //minimum constructor given two steppers for a multistepper group
    deviceNum1 = _stepper1;
    deviceNum2 = _stepper2;
    groupNum = _groupNum;
    stepsPerMm=_stepsPerMm;
  }
  MultiStepper(int _groupNum, int _stepper1, int _stepper2) { //minimum constructor given two steppers for a multistepper group
    deviceNum1 = _stepper1;
    deviceNum2 = _stepper2;
    groupNum = _groupNum;
  }
  void config() { 
    arduino.asMultiConfig(groupNum, deviceNum1, deviceNum2);
  }

  void to(float loc) {
    arduino.asMultiTo(groupNum, (int)(loc*stepsPerMm)); // multiStep is not a command oddly. this is fine after homing, however at start the motors do not know their location
    println("Multistepper move to: "+(loc));  //check to see command is sent
  }
  void to(int loc) {
    arduino.asMultiTo(groupNum, (int)(loc*stepsPerMm)); // multiStep is not a command oddly. this is fine after homing, however at start the motors do not know their location
    println("Multistepper move to: "+(int)(loc*stepsPerMm));  //check to see command is sent
  }
  void report() {
    arduino.asReport(deviceNum1); //since the steppers are grouped their report should be the same as the indidual steppers
    //println("deviceNum1 was sent a report request");
    this.reported=true;
  }
  void setSpeed(float speed) {
    arduino.asSetSpeed(deviceNum1, speed*stepsPerMm);  
    arduino.asSetSpeed(deviceNum2, speed*stepsPerMm);
    println("Multistepper "+ groupNum+ " was set to a speed of "+speed*stepsPerMm);
  }
  void halt() {
    arduino.asMultiStop(groupNum);
    this.state=false;
  }

  void zero() {
    arduino.asZero(deviceNum1);  
    arduino.asZero(deviceNum2);
  }
}

class Hole {
  int xPixel;
  int yPixel;
  int diameter;

  Hole(int _xPixel, int _yPixel, int _diameter) {
    xPixel=_xPixel;
    yPixel=_yPixel;
    diameter=_diameter;
  }

  void display() {
    noFill();
    ellipse(xPixel, yPixel, diameter, diameter);
    fill(255);
  }
}
class Relay {
  //boolean state;
  int state;
  int pin;

  Relay(int _pin) {
    pin=_pin;
    state=0; //make the relay initially off
  }


  void off() {
    state=0;
    arduino.pinMode(pin, Arduino.OUTPUT);
    arduino.digitalWrite(pin, Arduino.HIGH);
  }
  void on() {
    state=1;
    arduino.pinMode(pin, Arduino.OUTPUT);
    arduino.digitalWrite(pin, Arduino.LOW);
  }
  int getState() {
    return state;
  }
}

class SolidStateRelay {
  //boolean state;
  int state;
  int pin;

  SolidStateRelay(int _pin) {
    pin=_pin;
    state=0; //make the relay initially off
  }
  void off() {
    state=0;
    arduino.pinMode(pin, Arduino.OUTPUT);
    arduino.digitalWrite(pin, Arduino.LOW);
  }
  void on() {
    state=1;
    arduino.pinMode(pin, Arduino.OUTPUT);
    arduino.digitalWrite(pin, Arduino.HIGH);
  }
  int getState() {
    return state;
  }
}
