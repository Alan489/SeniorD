/**
 * Firmata.java - Firmata library for Java
 * Copyright (C) 2006-13 David A. Mellis
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 *
 * Java code to communicate with the Arduino Firmata 2 firmware.
 * http://firmata.org/
 *
 * $Id$
 */

package org.firmata; // hope this is okay!

/**
 * Internal class used by the Arduino class to parse the Firmata protocol.
 */
public class Firmata {
  /**
   * Constant to set a pin to input mode (in a call to pinMode()).
   */
  public static final int INPUT = 0;
  /**
   * Constant to set a pin to output mode (in a call to pinMode()).
   */
  public static final int OUTPUT = 1;
  /**
   * Constant to set a pin to analog mode (in a call to pinMode()).
   */
  public static final int ANALOG = 2;
  /**
   * Constant to set a pin to PWM mode (in a call to pinMode()).
   */
  public static final int PWM = 3;
  /**
   * Constant to set a pin to servo mode (in a call to pinMode()).
   */
  public static final int SERVO = 4;
  /**
   * Constant to set a pin to shiftIn/shiftOut mode (in a call to pinMode()).
   */
  public static final int SHIFT = 5;
  /**
   * Constant to set a pin to I2C mode (in a call to pinMode()).
   */
  public static final int I2C = 6;
  /**
   * Constant to set a pin as a one wire communication pin (DS18b20 for example).
   */
  public static final int ONEWIRE = 7;
  /**
   * Constant to set a pin to input mode and enable the pull-up resistor (in a call to pinMode()).
   */
  public static final int STEPPER = 8;
  /**
   * Constant to set a pin to input mode and enable the pull-up resistor (in a call to pinMode()).
   */
  public static final int ENCODER = 9;
  /**
   * Constant to set an interrupt to a frequency measurement pin
   */
  public static final int FREQUENCY = 0x10;
  /**
   * Constant to set a pin to input mode and enable the pull-up resistor (in a call to pinMode()).
   */
  public static final int INPUT_PULLUP = 11;

  /**
   * Constant to write a high value (+5 volts) to a pin (in a call to
   * digitalWrite()).
   */
  public static final int LOW = 0;
  /**
   * Constant to write a low value (0 volts) to a pin (in a call to
   * digitalWrite()).
   */
  public static final int HIGH = 1;

  private final int MAX_DATA_BYTES = 4096; //changed from 4096

  private final int DIGITAL_MESSAGE        = 0x90; // send data for a digital port
  private final int ANALOG_MESSAGE         = 0xE0; // send data for an analog pin (or PWM)
  private final int REPORT_ANALOG          = 0xC0; // enable analog input by pin #
  private final int REPORT_DIGITAL         = 0xD0; // enable digital input by port
  private final int SET_PIN_MODE           = 0xF4; // set a pin to INPUT/OUTPUT/PWM/etc
  private final int REPORT_VERSION         = 0xF9; // report firmware version
  private final int SYSTEM_RESET           = 0xFF; // reset from MIDI
  private final int START_SYSEX            = 0xF0; // start a MIDI SysEx message
  private final int END_SYSEX              = 0xF7; // end a MIDI SysEx message

  // extended command set using sysex (0-127/0x00-0x7F)
  /* 0x00-0x0F reserved for user-defined commands */
  private final int FREQUENCY_COMMAND			= 0x63; //
  private final int FREQUENCY_SUBCOMMAND_CLEAR	= 0x00; //
  private final int FREQUENCY_SUBCOMMAND_QUERY	= 0x01; //
  private final int FREQUENCY_SUBCOMMAND_REPORT	= 0x02; //
  private final int ACCELSTEPPER_DATA           = 0x62; //
  private final int ACCELSTEPPER_ZERO           = 0x01; //
  private final int ACCELSTEPPER_STEP           = 0x02; //
  private final int ACCELSTEPPER_CONFIG         = 0x00; //
  private final int ACCELSTEPPER_TO             = 0x03; //
  private final int ACCELSTEPPER_ENABLE         = 0x04; //
  private final int ACCELSTEPPER_STOP           = 0x05; //
  private final int ACCELSTEPPER_REPORT  		= 0x06; //
  private final int ACCELSTEPPER_MOVECOMPLETE   = 0x0A; //
  private final int ACCELSTEPPER_SETACCEL       = 0x08; //
  private final int ACCELSTEPPER_SETSPEED       = 0x09; //
  private final int ACCELSTEPPER_MULTICONF      = 0x20; //
  private final int ACCELSTEPPER_MULTI_TO       = 0x21; //
  private final int ACCELSTEPPER_MULTI_STOP     = 0x23; //
  private final int ACCELSTEPPER_MULTI_MOVECOMPLETE       = 0x24; //
  private final int SERVO_CONFIG           = 0x70; // set max angle, minPulse, maxPulse, freq
  private final int STRING_DATA            = 0x71; // a string message with 14-bits per char
  private final int SHIFT_DATA             = 0x75; // a bitstream to/from a shift register
  private final int I2C_REQUEST            = 0x76; // send an I2C read/write request
  private final int I2C_REPLY              = 0x77; // a reply to an I2C read request
  private final int I2C_CONFIG             = 0x78; // config I2C settings such as delay times and power pins
  private final int EXTENDED_ANALOG        = 0x6F; // analog write (PWM, Servo, etc) to any pin
  private final int PIN_STATE_QUERY        = 0x6D; // ask for a pin's current mode and value
  private final int PIN_STATE_RESPONSE     = 0x6E; // reply with pin's current mode and value *see FirmataExt.cpp
  private final int CAPABILITY_QUERY       = 0x6B; // ask for supported modes and resolution of all pins
  private final int CAPABILITY_RESPONSE    = 0x6C; // reply with supported modes and resolution
  private final int ANALOG_MAPPING_QUERY   = 0x69; // ask for mapping of analog to pin numbers
  private final int ANALOG_MAPPING_RESPONSE= 0x6A; // reply with mapping info
  private final int REPORT_FIRMWARE        = 0x79; // report name and version of the firmware
  private final int SAMPLING_INTERVAL      = 0x7A; // set the poll rate of the main loop
  private final int SYSEX_NON_REALTIME     = 0x7E; // MIDI Reserved for non-realtime messages
  private final int SYSEX_REALTIME         = 0x7F; // MIDI Reserved for realtime messages
  
  int waitForData = 0;
  int executeMultiByteCommand = 0;
  int multiByteChannel = 0;
  int[] storedInputData = new int[MAX_DATA_BYTES];
  boolean parsingSysex;
  int sysexBytesRead;

  int[] digitalOutputData = new int[54]; //{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  int[] digitalInputData  = new int[54]; //{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  int[] analogInputData   = new int[16]; //{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

  private final int MAX_PINS = 128;

  int[] pinModes = new int[MAX_PINS];
  int[] analogChannel = new int[MAX_PINS];
  int[] pinMode = new int[MAX_PINS];

  int majorVersion = 0;
  int minorVersion = 0;
  
  int[] accelStepperChannel = new int[8];
  int lastTime =0;
  int lastCount=0;
  float period=1f;
  float freq=1f;
  int reportDevice=-1; //starts at -1 and is requested from GUI
  int reportSteps=0; //may need to use long for this 1m/60mm*200=3333 steps without microstepping
  int completeMove=0; //used to stop reporting once completed so we dont have traffic problems
  int moveDeviceNum=-1; //set to -1 when move starts and then to deviceNum or groupNUm that completes
  
  /**
   * An interface that the Firmata class uses to write output to the Arduino
   * board. The implementation should forward the data over the actual
   * connection to the board.
   */
  public interface Writer {
    /**
     * Write a byte to the Arduino board. The implementation should forward
     * this using the actual connection.
     *
     * @param val the byte to write to the Arduino board
     */
    public void write(int val);
  }

  Writer out;

  /**
   * Create a proxy to an Arduino board running the Firmata 2 firmware.
   *
   * @param writer an instance of the Firmata.Writer interface
   */
  public Firmata(Writer writer) {
    this.out = writer;
  }
/**
 * Enable all ports 
 */
  public void init() {
     //enable all ports; firmware should ignore non-existent ones
    for (int i = 0; i < 16; i++) { //ports not pins! 8 pins /port A-K on mega
      out.write(REPORT_DIGITAL | i); 
      out.write(1);
    }
    
    //queryCapabilities(); // request pin capabilities from arduino, generates a capability response which contains data
//    pinStateQuery();
    queryAnalogMapping();

    for (int i = 0; i < 16; i++) {
      out.write(REPORT_ANALOG | i);
      out.write(1);
    }
  }
  /**
   * Reset the arduino to stop all motion /sensing
   * */
  public void restartArduino() {
	  out.write(START_SYSEX);
	  out.write(SYSTEM_RESET);
	  out.write(END_SYSEX);
  }
  /**
   * Returns the last known value read from the digital pin: HIGH or LOW.
   *
   * @param pin the digital pin whose value should be returned (from 2 to 13,
   * since pins 0 and 1 are used for serial communication)
   * @return state of selected pin
   */
  public int digitalRead(int pin) {
	  return (digitalInputData[pin >> 3] >> (pin & 0x07)) & 0x01; // digitalInputData[i]
  }
  /**
   * 
   * Returns portwide data of digital pins
   * @param port to be read
   * @return port integer (only 7 LSB bits)
   * */
  public int portRead(int port) {
	  return (digitalInputData[port]);
  }
  /**
   * Returns the last known value read from the analog pin: 0 (0 volts) to
   * 1023 (5 volts).
   *
   * @param pin the analog pin whose value should be returned (from 0 to 5)
   * @return integer value representing ADC (0-1023)
   */
  public int analogRead(int pin) {
    return analogInputData[pin];
  }

  /**
   * Set a digital pin to input or output mode.
   *
   * @param pin the pin whose mode to set (from 2 to 53)
   * @param mode either Arduino.INPUT or Arduino.OUTPUT
   */
  public void pinMode(int pin, int mode) { 
    out.write(SET_PIN_MODE);
    out.write(pin);
    out.write(mode);
//    try {
//        Thread.sleep(1);
//      } catch (InterruptedException ex) {}
  }

  /**
   * Write to a digital pin (the pin must have been put into output mode with
   * pinMode()).
   *
   * @param pin the pin to write to (from 2 to 13)
   * @param value the value to write: Arduino.LOW (0 volts) or Arduino.HIGH
   * (5 volts)
   */
  public void digitalWrite(int pin, int value) {
    int portNumber = (pin >> 3) & 0x0F; // 

    if (value == 0)
      digitalOutputData[portNumber] &= ~(1 << (pin & 0x07));
    else
      digitalOutputData[portNumber] |= (1 << (pin & 0x07));

    out.write(DIGITAL_MESSAGE | portNumber);
    out.write(digitalOutputData[portNumber] & 0x7F);
    out.write(digitalOutputData[portNumber] >> 7);
  }

  /**
   * Write an analog value (PWM-wave) to a digital pin.
   *
   * @param pin the pin to write to (must be 9, 10, or 11, as those are they
   * only ones which support hardware pwm)
   * @param value the value: 0 being the lowest (always off), and 255 the highest
   * (always on)
   */
  public void analogWrite(int pin, int value) {
    pinMode(pin, PWM);
    out.write(ANALOG_MESSAGE | (pin & 0x0F));
    out.write(value & 0x7F);
    out.write(value >> 7);
  }

  /**
   * Write a value to a servo pin.
   *
   * @param pin the pin the servo is attached to
   * @param value the value: 0 being the lowest angle, and 180 the highest angle
   */
  public void servoWrite(int pin, int value) {
    out.write(ANALOG_MESSAGE | (pin & 0x0F));
    out.write(value & 0x7F);
    out.write(value >> 7);
  }
  /**
   * I2C config
   * 
   * */
  public void mcp4725config() {
	  out.write(START_SYSEX);
	  out.write(I2C_CONFIG);
	  out.write(END_SYSEX);
  }
  
  /**
   * I2C write value to an mcp4725 DAC
   * 
   * @param address i2c address of device
   * @param value 12 bit voltage value as integer (0-4096)
   * */
  public void mcp4725(int address, int value) {
	  int writemode = 96; //64 for regular write, 96 for EEPROM write
	  int msb = (value>>4);
	  int lsb = (value<<4);
//	  System.out.println(msb<<4|lsb>>4);
	  out.write(START_SYSEX);
	  out.write(I2C_REQUEST);
	  out.write(address); //I2C address of the DAC, varies between devices 0x60 here
	  out.write(0x00);  //specifies write and restart transmission but we'll put this in loop
	  out.write(writemode & 127); //sets mcp to write mode
	  out.write(writemode >> 7);
	  out.write(msb & 127); //LSB of data
	  out.write(msb >> 7); //MSB of data
	  out.write(lsb & 127); //LSB of data
	  out.write(lsb >> 7); //MSB of data
	  out.write(END_SYSEX);
	  }
  /**
   * I2C communication between arduino nano with an HX711 load cell amplifier attached. The nano handles
   * the library for the HX711 and all of the communication. We simply have these custom functions to write messages
   * to the arduino nano for it to collect data from or configure the HX711
   * @param 
   * @returns
   * */
//  public void hx711(int address) {
//	  out.write(START_SYSEX);
//	  out.write(I2C_REQUEST);
//	  out.write(address); //I2C address of the arduino nano hosting the HX711, default is 0x08
//	  out.write(0x00);  //specifies write and restart transmission but we'll put this in loop
//	  out.write(writemode & 127); //sets mcp to write mode
//	  out.write(writemode >> 7);
//	  out.write(msb & 127); //LSB of data
//	  out.write(msb >> 7); //MSB of data
//	  out.write(lsb & 127); //LSB of data
//	  out.write(lsb >> 7); //MSB of data
//	  out.write(END_SYSEX);
//  }
  /**
   * Measure frequency events on a pin
   *
   * @param pin the pin used for frequency measurement
   * @param mode the type of interrupt used to measure frequency (3->RISING, 4->FALLING, 5->CHANGE)
   * @param period the interval used for measuremnt (period of reporting data)
   */
  public void freqConfig(int pin, int mode, int period) {
  		out.write(START_SYSEX);
  		out.write(FREQUENCY_COMMAND);
  		out.write(FREQUENCY_SUBCOMMAND_QUERY);
  		out.write(pin);
  		out.write(mode); //rising, falling or change
  		out.write(period & 0x7F);
  		out.write(period >> 7);
  		out.write(END_SYSEX);
  		}
  /**
   * Returns the last known value of frequency measured on pin 2
   * @return frequency float
   * */
  public float freqRead() {
	  return freq;
  }
  /**
   * 
   * read a period from the frequency counter
   *  @return period as float
   * 
   * */
  public float periodRead() {
	  return period;
  }
  /**
   * read the current steps from the sysex message after a report request
   * @return current steps
   * */
  public int stepsRead() {
	  return reportSteps;
  }
  /**
   * read the stepper motor number from the sysex message after a report request
   * @return reportDevice
   * */
  public int deviceRead() {
	  return reportDevice;
  }
  /**
   * gets the devicenumber for a stepper who has completed its steps
   * @return moveDeviceNum
   * */
  public int moveComplete() {
	  return moveDeviceNum;
  }
  /**
   * gets the devicenumber for a stepper who has completed its steps
   * @return moveDeviceNum
   * */
  public int checkMoveFlag() {
	  return completeMove;
  }
  /**
   * Configure frequency measurement on an arduino pin with interrupt
   *
   * @param pin used for interrupt based frequency measurements
   */
  public void freqDisable(int pin) {
		out.write(START_SYSEX);
		out.write(FREQUENCY_COMMAND);
		out.write(FREQUENCY_SUBCOMMAND_CLEAR);
		out.write(pin);
		out.write(END_SYSEX);
		lastTime=0;
		lastCount=0;
		}
  
  /**
   * Configure a stepper motor using
   * 	
   * @param deviceNum the number identifying the specific stepper motor 0-9
   * @param stepPin pin connected to stepper motor step pin
   * @param dirPin pin connected to stepper motor direction pin
   */
  public void asConfig(int deviceNum, int stepPin, int dirPin) {
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_CONFIG);
	    out.write(deviceNum);
	    out.write(16); //driver configuration, full steps, no enable pin
	    out.write(stepPin);
	    out.write(dirPin);
	    out.write(END_SYSEX);
	    System.out.println("Stepper "+deviceNum+" configured on pins " + stepPin + " & " + dirPin);
	  }
  /**
   * Set the zero position on a stepper motor
   * 
   *  @param deviceNum the number identifying the specific stepper motor 0-9
   * */
  
  public void asZero(int deviceNum) {
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_ZERO);
	    out.write(deviceNum);
	    out.write(END_SYSEX);
	    //System.out.println("Stepper "+deviceNum+" has be re-zeroed and must be homed before absolute position commands");
	  }
  /**
   * Drive a stepper motor with a given number of steps
   * 
   *  @param deviceNum the number identifying the specific stepper motor 0-9
   *  @param steps the number of steps to drive stepper motor (signed 32bit integer)
   * */
  public void asStep(int deviceNum, int steps) {
	  completeMove=0; 
	  int[] arg= encode32bit(steps);
	  	out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_STEP);
	    out.write(deviceNum);
	    out.write(arg[0]);  //samples from 0-6
	    out.write(arg[1]);  //samples from 7-13
	    out.write(arg[2]); //samples from 14-20
	    out.write(arg[3]); //samples from 21 to 27
	    out.write(arg[4]);	    
	    out.write(END_SYSEX);
	    //System.out.println("Stepper "+deviceNum+" has been called to move"+steps+" steps");
  }
  /**
   * Drive a stepper motor to a step location (must have been zeroed during homing to be accurate)
   * 
   *  @param deviceNum the number identifying the specific stepper motor 0-9
   *  @param moveto the desired step location (signed 32bit integer)
   * */
  public void asTo(int deviceNum, int moveto) {
	    int[] arg= encode32bit(moveto);
	    completeMove=0;
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_TO);
	    out.write(deviceNum);
	    out.write(arg[0]);  //samples from 0-6
	    out.write(arg[1]);  //samples from 7-13
	    out.write(arg[2]); //samples from 14-20
	    out.write(arg[3]); //samples from 21 to 27
	    out.write(arg[4]);	    
	    out.write(END_SYSEX);
	    //System.out.println("Stepper "+deviceNum+" has be called to "+moveto+"absolute position");
  }
  /**
   * Stop a stepper motor 
   * 
   *  @param deviceNum the specific stepper motor to stop
   *  
   * */
  public void asStop(int deviceNum) {
	    completeMove=1;
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_STOP);
	    out.write(deviceNum);	    
	    out.write(END_SYSEX);
	    System.out.println("Stepper "+deviceNum+" sent a stop command");
  }
  /**
   * Report the position of a stepper motor 
   * 
   *  @param deviceNum the stepper motor which we want a report
   *  
   * */
  public void asReport(int deviceNum) {
	  	out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA); //98
	    out.write(ACCELSTEPPER_REPORT); //6
	    out.write(deviceNum);	    
	    out.write(END_SYSEX);
//	    try {
//	        Thread.sleep(1);
//	      } catch (InterruptedException ex) {}
//	    System.out.println(START_SYSEX+","+ACCELSTEPPER_DATA+","+ACCELSTEPPER_REPORT+","+deviceNum+","+END_SYSEX);
}
  /**
   * Set the maximum speed of a stepper motor in steps/second 
   * 
   *  @param deviceNum the stepper motor which we want to set speed
   *  @param speed the maximum speed in steps/second
   * */
  public void asSetSpeed(int deviceNum, float speed) {
	    int args = encodeCustomFloat(speed);
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_SETSPEED);
	    out.write(deviceNum);
	    out.write((args) & 127); //samples from 21 to 27
	    out.write((args>>7) & 127); //samples from 14-20
	    out.write((args>>14) & 127);  //samples from 7-13
	    out.write((args>>21) & 127);  //samples from 0-6
	    out.write(END_SYSEX);
	    //System.out.println("set to "+speed+" steps/s on stepper " + deviceNum);
	  }
  /**
   * Set the acceleration/deceleration of a stepper motor in steps/second^2 
   * 
   *  @param deviceNum the stepper motor which we want a report
   *  @param accel the acceleration in steps/second^2
   * */
  public void asSetAccel(int deviceNum, float accel) {
	    int args = encodeCustomFloat(accel);
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_SETACCEL);
	    out.write(deviceNum);
	    out.write((args) & 127); //samples from 21 to 27
	    out.write((args>>7) & 127); //samples from 14-20
	    out.write((args>>14) & 127);  //samples from 7-13
	    out.write((args>>21) & 127);  //samples from 0-6
	    out.write(END_SYSEX);
	    //System.out.println("accelstepper accel set to "+accel+" steps/s^2 on stepper " + deviceNum);
	  }
  /**
   * Setup a group of steppers using Multistepper
   * 
   * @param groupNum the group number you would like to setup
   * @param deviceNum1 the first stepper number which we want to add to group
   * @param deviceNum2 the second stepper number which we want to add to group
   * 
   * */
  public void asMultiConfig(int groupNum, int deviceNum1, int deviceNum2) {
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_MULTICONF);
	    out.write(groupNum);
	    out.write(deviceNum1); //samples from 21 to 27
	    out.write(deviceNum2); //samples from 14-20
	    out.write(END_SYSEX);
	    //System.out.println("multistepper group "+groupNum+" was setup with steppers " + deviceNum1 + " and " + deviceNum2);
	  }
  /**
   * Drive a Multistepper group to a step location (must have been zeroed during homing to be accurate)
   * 
   *  @param groupNum the number identifying the specific Multistepper group we want to move
   *  @param moveto the desired step location (signed 32bit integer)
   * */
  public void asMultiTo(int groupNum, int moveto) {
	    completeMove=0;
	    int[] arg= encode32bit(moveto);
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_MULTI_TO);
	    out.write(groupNum);
	    out.write(arg[0]);  //samples from 0-6
	    out.write(arg[1]);  //samples from 7-13
	    out.write(arg[2]); //samples from 14-20
	    out.write(arg[3]); //samples from 21 to 27
	    out.write(arg[4]);
	    out.write(END_SYSEX);
	    //System.out.println("multistepper group "+groupNum+"was moved "+steps +"steps");
	  }
  /**
   * Stop a Multistepper group
   * 
   *  @param groupNum the number identifying the specific Multistepper group we want to move
   * 
   * */
  public void asMultiStop(int groupNum) {
	    completeMove=1;
	    out.write(START_SYSEX);
	    out.write(ACCELSTEPPER_DATA);
	    out.write(ACCELSTEPPER_MULTI_STOP);
	    out.write(groupNum);
	    out.write(END_SYSEX);
	    System.out.println("multistepper group "+groupNum+"was stopped");
	  }
  /**
   * Encode a signed 32 bit integer to use in other functions
   * 
   *  @param val the number (signed 32 bit integer)
   *  @return integer array of the encoded message
   * */
  
	public static int[] encode32bit(int val) {
		boolean inv=false;
		if(val<0) {inv=true;val=-val;}
		int[] args = new int[5];
		args[0] = val & 0x7F;
		args[1] = ((val >> 7) & 0x7F);
		args[2] = ((val >> 14) & 0x7F);
		args[3]= ((val >> 21) & 0x7F);
		args[4]= ((val >> 28) & 0x7F);
		if(inv) {args[4]=args[4] | 0x08;}
		return args;
	}
	  /**
	   * Decode a signed 32 bit integer to use in other functions
	   * 
	   *  @param arg0 bits (0-6)
	   *  @param arg1 bits (7-13)
	   *  @param arg2 bits (14-20)
	   *  @param arg3 bits (21-27) 
	   *  @param arg4 bits (28-31, ignore 32-34)
	   *  @return 32 bit decoded value
	   * */
	public static int decode32bit(int arg0, int arg1, int arg2, int arg3, int arg4) {
		int value = arg0 | (arg1<<7) | (arg2<<14) | (arg3<<21) | ((arg4 << 28) & 0x07);
		if (arg4 >> 3 == 0x01) {
		    value = value*-1;
		  }
		return value;
	}
	  /**
	   * Decode an unsigned 32 bit integer to use in other functions
	   * 
	   *  @param arg0 bits (0-6)
	   *  @param arg1 bits (7-13)
	   *  @param arg2 bits (14-20)
	   *  @param arg3 bits (21-27) 
	   *  @param arg4 bits (28-31, ignore 32-34)
	   *  @return 32 bit decoded value
	   * */
	public static int freqDecode(int arg0, int arg1, int arg2, int arg3, int arg4) {
		int value = arg0 | (arg1<<7) | (arg2<<14) | (arg3<<21) | ((arg4 << 28) & 0x0F);
		return value;
	}
	  /**
	   * Encode a custom float to communicate with Accelstepper
	   * 
	   *  @param decimal the float we would like to encode as a custom float
	   *  @return the encoded array
	   * */
	public static int encodeCustomFloat(float decimal){    
		int exp = (int)(Math.log10(8388608/Math.abs(decimal))); //maximum precision of 23bit
		int placeholder=(int)(Math.abs(decimal)*Math.pow(10, exp));
		int power = 11-exp; //power is shifted down by 11 on the interpreter
		int sgn =0; int args=0;
		if (Math.signum(decimal)==-1) {
			sgn =1; args = (placeholder)|power<<23|sgn<<27;} 
		else {
			sgn =0; args = (placeholder)|power<<23;}
		//uses bit shifting to generate a 28bit number representing the custom float
		return args;
	}  
	  /**
	   * Decode a custom float to communicate with Accelstepper
	   * 
	   *  @param encoded the float we would like to decode from a custom float
	   *  @return decoded float
	   * */
	public static float decodeCustomFloat(int encoded) {
		int significand = encoded & (1 << 23)-1;
//		System.out.println(significand);
		int exponent = (encoded >> 23) & 15;
//		System.out.println(exponent);
		int sign = (encoded >> 27 & 1); 
//		System.out.println(sign);
		float decimal = (float)significand*(float)Math.pow(10.0f, exponent - 11);
		if(sign == 1) {decimal=-1.0f*decimal;}
		return decimal;
	}
  private void setDigitalInputs(int portNumber, int portData) {
    //System.out.println("digital port " + portNumber + " is " + portData);
    digitalInputData[portNumber] = portData;
  }

  private void setAnalogInput(int pin, int value) {
    //System.out.println("analog pin " + pin + " is " + value);
    analogInputData[pin] = value;
  }

  private void setVersion(int majorVersion, int minorVersion) {
    //System.out.println("version is " + majorVersion + "." + minorVersion);
    this.majorVersion = majorVersion;
    this.minorVersion = minorVersion;
  }

  private void queryCapabilities() {
    out.write(START_SYSEX);
    out.write(CAPABILITY_QUERY);
    out.write(END_SYSEX);
  }
  private void pinStateQuery() {
	    out.write(START_SYSEX);
	    out.write(PIN_STATE_QUERY);
	    out.write(END_SYSEX);
	  }

  private void queryAnalogMapping() {
    out.write(START_SYSEX);
    out.write(ANALOG_MAPPING_QUERY);
    out.write(END_SYSEX);
  }

  private void processSysexMessage() {
//    System.out.print("[ ");
//    for (int i = 0; i < sysexBytesRead; i++) System.out.print(storedInputData[i] + ", ");
//    System.out.println("]");
//	  System.out.println(sysexBytesRead);
    switch(storedInputData[0]) { 
    	
    
    	case REPORT_FIRMWARE: //0x78
//    		System.out.println("REPORT_FIRMWARE called");
//    		System.out.println(sysexBytesRead);
    		System.out.println("Firmata Version "+storedInputData[1]+"."+storedInputData[2] );
    		System.out.print("Arduino sketch name: ");
    		for(int i=3;i<sysexBytesRead;i+=2) {
    			char msgChar = (char)(storedInputData[i]|storedInputData[i+1]<<7);
    		System.out.print(msgChar);}
    		System.out.println();
    	break;
    	case STRING_DATA:
//    		System.out.println("STRING_DATA called");
//    		System.out.println(sysexBytesRead);
    		for(int i=1;i<sysexBytesRead;i+=2) {
    			char msgChar = (char)(storedInputData[i]|storedInputData[i+1]<<7);
    		System.out.print(msgChar);}
    		System.out.println();
    		break;
    	case PIN_STATE_RESPONSE:
    		System.out.println("pin state response received");
    		break;
//    	case CAPABILITY_RESPONSE:
//          for (int pin = 0; pin < pinModes.length; pin++) { //loop through pins
//            pinModes[pin] = 0;
//          }
//          for (int i = 1, pin = 0; pin < pinModes.length; pin++) {
//            for (;;) {
//              int val = storedInputData[i++];
//              if (val == 127) break;
//              pinModes[pin] |= (1 << val);
//              i++; // skip mode resolution for now
//            }
//            if (i == sysexBytesRead) break;
//          }
//          for (int port = 0; port < pinModes.length>>3; port++) {
//            boolean used = false;
//            for (int i = 0; i < 8; i++) { //loop through pins in each port
//              if (pinModes[port * 8 + i] & (1 << INPUT) != 0) used = true;
//            }
//            if (used) {
//              out.write(REPORT_DIGITAL | port);
//              out.write(1);
//            }
//          }
//          break;
    	case ANALOG_MAPPING_RESPONSE:
//    		System.out.println("ANALOG_MAPPING_RESPONSE called");
//          System.out.println(sysexBytesRead);
    		for (int pin = 0; pin < analogChannel.length; pin++)
            analogChannel[pin] = 127;
    		for (int i = 1; i < sysexBytesRead; i++)
    		analogChannel[i - 1] = storedInputData[i];
    		for (int pin = 0; pin < analogChannel.length; pin++) {
    			if (analogChannel[pin] != 127) {
    				out.write(REPORT_ANALOG | analogChannel[pin]);
    				out.write(1);
    			}
    		}
    	break;
    	case FREQUENCY_COMMAND:  //0x63
      		int thisTime = freqDecode(storedInputData[2],storedInputData[3],storedInputData[4],storedInputData[5],storedInputData[6]);
      		int thisCount = freqDecode(storedInputData[7],storedInputData[8],storedInputData[9],storedInputData[10],storedInputData[11]);
//      		if(thisCount>lastCount) {
      			 
      			if(thisCount>lastCount) { //keep the same value displayed and reject bounces
      				freq = (float)(thisCount-lastCount)*1000.0f/(thisTime-lastTime);
      				period =(float)(thisTime-lastTime)/(thisCount-lastCount)/1000.0f; 
      				lastTime=thisTime;
      				lastCount=thisCount;}
        break;
    	case ACCELSTEPPER_DATA: { // 0x62 = 98

          switch(storedInputData[1]) {
          case ACCELSTEPPER_REPORT: { //0x06 = 6
        	  for (int i = 2; i < sysexBytesRead; i++) {
        		  accelStepperChannel[i - 2] = storedInputData[i];}
        	  reportDevice = accelStepperChannel[0];
        	  reportSteps = decode32bit(accelStepperChannel[1],accelStepperChannel[2],accelStepperChannel[3],accelStepperChannel[4],accelStepperChannel[5]);
        	  //System.out.println("Stepper device "+ reportDevice + " is at "+ reportSteps);
        	  }
        	  	  break;
          case ACCELSTEPPER_MOVECOMPLETE: { //0x0A  = 10
        	  for (int i = 2; i < sysexBytesRead; i++) {
        		  accelStepperChannel[i - 2] = storedInputData[i];}
        	  moveDeviceNum = accelStepperChannel[0];
        	  reportSteps = decode32bit(accelStepperChannel[1],accelStepperChannel[2],accelStepperChannel[3],accelStepperChannel[4],accelStepperChannel[5]);
        	  //System.out.println("Stepper device "+ moveDeviceNum + " has moved to step "+ reportSteps);
        	  }
        	  break;
          case ACCELSTEPPER_MULTI_MOVECOMPLETE: { //0x24 = 36
        	  for (int i = 2; i < sysexBytesRead; i++) {
        		  accelStepperChannel[i - 2] = storedInputData[i];}
        	  moveDeviceNum = accelStepperChannel[0];
        	  completeMove=1;
        	  //System.out.println("MultiStepper group "+ groupNum + " completed its steps");  
        	  	}
          	  break;
          default: 
        	  
        	  System.out.println("ACCELSTEPPER COMMAND NOT READ");
//        	  for(int i = 0; i<sysexBytesRead; i++) {System.out.print(storedInputData[i]+",");}
//        	  System.out.println();
//        	  for (int i = 2; i < sysexBytesRead; i++) {
//        		  accelStepperChannel[i - 2] = storedInputData[i];}
//        	  int moveDeviceNum = accelStepperChannel[0];
//        	  int moveSteps = decode32bit(accelStepperChannel[1],accelStepperChannel[2],accelStepperChannel[3],accelStepperChannel[4],accelStepperChannel[5]);
//        	  //System.out.println(moveDeviceNum + ", " + storedInputData[1]+ ", "+ moveSteps);
        	  }
          	break;}
          	  		
    }
    }

  /**
   * Process incoming messages from Sysex
   * @param inputData is the message to decode
   */
  public void processInput(int inputData) {
    int command;

    //System.out.print(">" + inputData + " "); //verbose printout!

    if (parsingSysex) {
      if (inputData == END_SYSEX) {
        parsingSysex = false;
        processSysexMessage(); // starts processSysexMessage when END_SYSEX is found
      } else {
        storedInputData[sysexBytesRead] = inputData;
        sysexBytesRead++; //increments sysexBytesRead
      }
    } else if (waitForData > 0 && inputData < 128) { //what if data is longer than 128?
      waitForData--;
      storedInputData[waitForData] = inputData;

      if (executeMultiByteCommand != 0 && waitForData == 0) {
        //we got everything
        switch(executeMultiByteCommand) {
        case DIGITAL_MESSAGE:
          setDigitalInputs(multiByteChannel, (storedInputData[0] << 7) + storedInputData[1]);
          //System.out.print(">" + inputData + " "); //verbose printout!
          break;
        case ANALOG_MESSAGE:
          setAnalogInput(multiByteChannel, (storedInputData[0] << 7) + storedInputData[1]);
          break;
        case REPORT_VERSION:
          setVersion(storedInputData[1], storedInputData[0]);
          break;
        }
      }
    } else {
      if(inputData < 0xF0) { // <240
        command = inputData & 0xF0; //mask with 240
        multiByteChannel = inputData & 0x0F; //mask with 15
      } else {
        command = inputData; // if larger than 240 don't use channel
        // commands in the 0xF* range don't use channel data
      }
      switch (command) {
      case DIGITAL_MESSAGE://does nothing
      case ANALOG_MESSAGE://does nothing
      case REPORT_VERSION:
        waitForData = 2;
        executeMultiByteCommand = command;
        break;
      case START_SYSEX:
        parsingSysex = true;
        sysexBytesRead = 0;
        break;
      }
    }
  }
}
