/**
 * Arduino.java - Arduino/firmata library for Processing
 * Copyright (C) 2006-08 David A. Mellis
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
 * Processing code to communicate with the Arduino Firmata 2 firmware.
 * http://firmata.org/
 *
 * $Id$
 */

package cc.arduino;

import processing.core.PApplet;
import processing.serial.Serial;

import org.firmata.Firmata;

/**
 * Together with the Firmata 2 firmware (an Arduino sketch uploaded to the
 * Arduino board), this class allows you to control the Arduino board from
 * Processing: reading from and writing to the digital pins and reading the
 * analog inputs.
 */
public class Arduino {
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
  public static final int ONEWIRE = 0x07;
  /**
   * Constant to set a pin to input mode and enable the pull-up resistor (in a call to pinMode()).
   */
  public static final int STEPPER = 0x08;
  /**
   * Constant to set a pin to input mode and enable the pull-up resistor (in a call to pinMode()).
   */
  public static final int ENCODER = 0x09;
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

  PApplet parent;
  Serial serial;
  SerialProxy serialProxy;
  Firmata firmata;
/**
  * We need a class descended from PApplet so that we can override the
  * serialEvent() method to capture serial data.  We can't use the Arduino
  * class itself, because PApplet defines a list() method that couldn't be
  * overridden by the static list() method we use to return the available
  * serial ports.  This class needs to be public so that the Serial class
  * can access its serialEvent() method.
   * 
   * @author EW
   *
   */
  public class SerialProxy extends PApplet {
	  /**
	   * Serial proxy extends the processing applet so that the list() command can be used without error
	   * */
    public SerialProxy() {
    }
/**
 * Serial event instance
 * @param which particular instance
 * */
  public void serialEvent(Serial which) {
      try {
        // Notify the Arduino class that there's serial data for it to process.
        while (which.available() > 0)
          firmata.processInput(which.read());
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.serialEvent()");
      }
    }
  }
  /**
   * Firmata Writer is used for communicating with the Configurable Firmata installed on the microcontroller
   * */
  public class FirmataWriter implements Firmata.Writer {
    public void write(int val) {
      serial.write(val);
//      System.out.print("<" + val + " ");
    }
  }
  /**
   * dispose of current serial communication instance
   * */
  public void dispose() {
    this.serial.dispose();
  }

  /**
   * Get a list of the available Arduino boards; currently all serial devices
   * (i.e. the same as Serial.list()).  In theory, this should figure out
   * what's an Arduino board and what's not.
   * 
   * @return list of ports that are potentially arduinos
   */
  public static String[] list() {
    return Serial.list();
  }

  /**
   * Create a proxy to an Arduino board running the Firmata 2 firmware at the
   * default baud rate of 57600.
   *
   * @param parent the Processing sketch creating this Arduino board
   * (i.e. "this").
   * @param iname the name of the serial device associated with the Arduino
   * board (e.g. one the elements of the array returned by Arduino.list())
   */
  public Arduino(PApplet parent, String iname) {
    this(parent, iname, 57600);
  }

  /**
   * Create a proxy to an Arduino board running the Firmata 2 firmware.
   *
   * @param parent the Processing sketch creating this Arduino board
   * (i.e. "this").
   * @param iname the name of the serial device associated with the Arduino
   * board (e.g. one the elements of the array returned by Arduino.list())
   * @param irate the baud rate to use to communicate with the Arduino board
   * (the firmata library defaults to 57600, and the examples use this rate,
   * but other firmwares may override it)
   */
  public Arduino(PApplet parent, String iname, int irate) {
    this.parent = parent;
    this.firmata = new Firmata(new FirmataWriter());
    this.serialProxy = new SerialProxy();
    this.serial = new Serial(serialProxy, iname, irate);

    parent.registerMethod("dispose", this);

    try {
      Thread.sleep(6000); // let bootloader timeout 5 seconds
    } catch (InterruptedException e) {

    }

    firmata.init();
  }
  /**
   * Reset the arduino to stop all motion /sensing
   * */
  public void restartArduino() {
	 firmata.restartArduino();
  }
  /**
   * Returns the last known value read from the digital pin: HIGH or LOW.
   *
   * @param pin the digital pin whose value should be returned (from 2 to 13,
   * since pins 0 and 1 are used for serial communication)
   * @return state of pin
   */
  public int digitalRead(int pin) {
    return firmata.digitalRead(pin);
  }
  /**
   * 
   * Returns portwide data of digital pins
   * @param port to be read
   * @return port integer (only 7 LSB bits)
   * */
  public int portRead(int port) {
	  return firmata.portRead(port);
  }

  /**
   * Returns the last known value read from the analog pin: 0 (0 volts) to
   * 1023 (5 volts).
   *
   * @param pin the analog pin whose value should be returned (from 0 to 5)
   * @return analog reading (0-1023)
   */
  public int analogRead(int pin) {
    return firmata.analogRead(pin);
  }
  /**
   * Returns the last known value of frequency measured on pin 2
   * @return frequency float
   * */
  public float freqRead() {
	  return firmata.freqRead();
  } 
  /**
   * read a period from the frequency counter
   * @return period as float
   * */
  public float periodRead() {
	  return firmata.periodRead();
  }
  /**
   * read the current steps from the sysex message after a report request
   * @return current steps
   * */
  public int stepsRead() {
	  return firmata.stepsRead();
  }
  /**
   * read the stepper motor number from the sysex message after a report request
   * @return reportDevice
   * */
  public int deviceRead() {
	  return firmata.deviceRead();
  }
  /**
   * gets the devicenumber for a stepper who has completed its steps
   * @return moveDeviceNum
   * */
  public int moveComplete() {
	  return firmata.moveComplete();
  }
  /**
   * gets the devicenumber for a stepper who has completed its steps
   * @return moveDeviceNum
   * */
  public int checkMoveFlag() {
	  return firmata.checkMoveFlag();
  }
  /**
   * Set a digital pin to input or output mode.
   *
   * @param pin the pin whose mode to set (from 2 to 13)
   * @param mode either Arduino.INPUT or Arduino.OUTPUT
   */
  public void pinMode(int pin, int mode) {
    try {
      firmata.pinMode(pin, mode);
    } catch (Exception e) {
      e.printStackTrace();
      throw new RuntimeException("Error inside Arduino.pinMode()");
    }
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
    try {
      firmata.digitalWrite(pin, value);
    } catch (Exception e) {
      e.printStackTrace();
      throw new RuntimeException("Error inside Arduino.digitalWrite()");
    }
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
    try {
      firmata.analogWrite(pin, value);
    } catch (Exception e) {
      e.printStackTrace();
      throw new RuntimeException("Error inside Arduino.analogWrite()");
    }
  }

  /**
   * Write a value to a servo pin.
   *
   * @param pin the pin the servo is attached to
   * @param value the value: 0 being the lowest angle, and 180 the highest angle
   */
  public void servoWrite(int pin, int value) {
    try {
      firmata.servoWrite(pin, value);
    } catch (Exception e) {
      e.printStackTrace();
      throw new RuntimeException("Error inside Arduino.servoWrite()");
    }
  }
  /**
   * I2C config
   * 
   * */
  public void mcp4725config() {
	  try {
		  firmata.mcp4725config();
  } catch (Exception e) {
	  e.printStackTrace();
	  throw new RuntimeException("Error inside Arduino.mcp4725config()");
	  }
  }
  
  /**
   * I2C write value to an mcp4725 DAC
   * 
   * @param address i2c address of device
   * @param value 12 bit voltage value as integer (0-4096)
   * */
  public void mcp4725(int address, int value) {
	  try {
		  firmata.mcp4725(address, value);
	  } catch (Exception e) {
	  e.printStackTrace();
	  throw new RuntimeException("Error inside mcp4725");
	  }
	  
  }
  /**
   * Measure frequency events on a pin
   *
   * @param pin the pin used for frequency measurement
   * @param mode the type of interrupt used to measure frequency (3->RISING, 4->FALLING, 5->CHANGE)
   * @param period the interval used for measuremnt (period of reporting data)
   */
  	public void freqConfig(int pin, int mode, int period) {
  		try {
    	      firmata.freqConfig(pin, mode, period);
    	    } catch (Exception e) {
    	      e.printStackTrace();
    	      throw new RuntimeException("Error inside Arduino.freqConfig()");
    	    }
  	}
    /**
     * Configure frequency measurement on an arduino pin with interrupt
     *
     * @param pin pin used for interrupt based frequency measurements
     */
  	public void freqDisable(int pin) {
  		try {
  			firmata.freqDisable(pin);
//  			System.out.println("sent clear command in processing");
  		} catch (Exception e) {
  			e.printStackTrace();
  			throw new RuntimeException("Error inside Arduino.freqDisable");
  		}
  	} 
    /**
     * Configure a stepper motor using
     *
     * @param deviceNum the number identifying the specific stepper motor 0-9
     * @param stepPin pin connected to stepper motor step pin
     * @param dirPin pin connected to stepper motor direction pin
     */
    public void asConfig(int deviceNum, int stepPin, int dirPin) {
  	    try {
  	      firmata.asConfig(deviceNum,stepPin,dirPin);
  	    } catch (Exception e) {
  	      e.printStackTrace();
  	      throw new RuntimeException("Error inside Arduino.ASConfig()");
  	    }
  	  }
    /**
     * Set the zero position on a stepper motor
     * 
     *  @param deviceNum the number identifying the specific stepper motor 0-9
     * */
    public void asZero(int deviceNum) {try {
        firmata.asZero(deviceNum);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asZero(), check for config");
      }}
    /**
     * Drive a stepper motor with a given number of steps
     * 
     *  @param deviceNum the number identifying the specific stepper motor 0-9
     *  @param steps the number of steps to drive stepper motor (signed 32bit integer)
     * */
    public void asStep(int deviceNum, int steps) {try {
        firmata.asStep(deviceNum, steps);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asStep(), check for config");
      }}
    /**
     * Drive a stepper motor to a step location (must have been zeroed during homing to be accurate)
     * 
     *  @param deviceNum the number identifying the specific stepper motor 0-9
     *  @param moveto the desired step location (signed 32bit integer)
     * */
    public void asTo(int deviceNum, int moveto) {try {
        firmata.asTo(deviceNum,moveto);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asTo(), check for config");
      }}
    /**
     * Stop a stepper motor 
     * 
     *  @param deviceNum the specific stepper motor to stop
     *  
     * */
    public void asStop(int deviceNum) {try {
        firmata.asStop(deviceNum);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asStop(), check for config");
      }}
    /**
     * Report the position of a stepper motor 
     * 
     *  @param deviceNum the stepper motor which we want a report
     *  
     * */
    public void asReport(int deviceNum) {try {
        firmata.asReport(deviceNum);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asReport(), check for config");
      }}
    /**
     * Set the maximum speed of a stepper motor in steps/second 
     * 
     *  @param deviceNum the stepper motor which we want to set speed
     *  @param speed the maximum speed in steps/second
     * */
    public void asSetSpeed(int deviceNum, float speed) {try {
        firmata.asSetSpeed(deviceNum,speed);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asSetSpeed(), check for config");
      }}  
    /**
     * Set the acceleration/deceleration of a stepper motor in steps/second^2 
     * 
     *  @param deviceNum the stepper motor which we want a report
     *  @param accel the acceleration in steps/second^2
     * */
    public void asSetAccel(int deviceNum, float accel) {try {
        firmata.asSetAccel(deviceNum,accel);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asSetAccel(), check for config");
      }}  
    /**
     * Setup a group of steppers using Multistepper
     * 
     * @param groupNum the group number you would like to setup
     * @param deviceNum1 the first stepper number which we want to add to group
     * @param deviceNum2 the second stepper number which we want to add to group
     * 
     * */
    public void asMultiConfig(int groupNum, int deviceNum1, int deviceNum2) {try {
        firmata.asMultiConfig(groupNum, deviceNum1, deviceNum2);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asMultiConfig(), check config");
      }}
    /**
     * Drive a Multistepper group to a step location (must have been zeroed during homing to be accurate)
     * 
     *  @param groupNum the number identifying the specific Multistepper group we want to move
     *  @param moveto the desired step location (signed 32bit integer)
     * */
    public void asMultiTo(int groupNum, int moveto) {try {
        firmata.asMultiTo(groupNum, moveto);
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Error inside Arduino.asMultiTo(), check config");
      }}
    /**
     * Stop a Multistepper group
     * 
     *  @param groupNum the number identifying the specific Multistepper group we want to move
     * 
     * */
	public void asMultiStop(int groupNum) {try {
		firmata.asMultiStop(groupNum);
		} catch (Exception e) {
			e.printStackTrace();
			throw new RuntimeException("Error inside Arduino.asMultiStop(), check config");
		}}
		    
//	}

}
