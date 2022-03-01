/* =========================================================
 * ====                   WARNING                        ===
 * =========================================================
 * The code in this tab has been generated from the GUI form
 * designer and care should be taken when editing this file.
 * Only add/edit code inside the event handlers i.e. only
 * use lines between the matching comment tags. e.g.

 void myBtnEvents(GButton button) { //_CODE_:button1:12356:
     // It is safe to enter your event code here  
 } //_CODE_:button1:12356:
 
 * Do not rename this tab!
 * =========================================================
 */

public void Homing_requested(GOption source, GEvent event) { //_CODE_:Homing:729394:
  //  println("Homing - GOption >> GEvent." + event + " @ " + millis());
  //Homing.setSelected(true);
  homingstep=0;
  pumpRelay.off();
  heaterRelay.off();
  drillRelay.off();
  //extraRelay.off();
  xStepper1.config();
  yStepper.config();
  drillStepper.config(); // configures the drill stepper by sending commands to arduino
  extractorStepper.config();
  drillStepper.setSpeed(drillFeed);
  xStepper1.setSpeed(xSpeed); //xSpeed is in mm/s, setspeed in asSetSpeed() is in steps/s
  extractorStepper.setSpeed(extractorFeed);
  yStepper.setSpeed(ySpeed);
  extractorStepperUpdate.setInitialDelay(50);
  xposLabel.setText("des. drill X=");
  yposLabel.setText("des. drill Y=");
  label2.setText("Drill Position");
  label2.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  slider2d1.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  message.setText("Homing sequence started");
} //_CODE_:Homing:729394:

public void positionDrill_requested(GOption source, GEvent event) { //_CODE_:positionDrill:655791:
  positionDrill.setSelected(true);
  yStepperUpdate.start();
  xStepperUpdate.start();
  positionX();
  positionY();
  message.setText("xStepper to: "+nf(desiredX)+"\n"+
    "yStepper to: "+nf(desiredY_textbox.getValueF())+"\n");
} //_CODE_:positionDrill:655791:

public void touchDrill_requested(GOption source, GEvent event) { //_CODE_:touchDrill:317738:
  touch=false; //set touch to be false to use in main loop
  touchDrill.setSelected(true);
  yStepperUpdate.stop();
  xStepperUpdate.stop();
  // move until we see desireLoad reached. This could be added to draw loop
  message.setText("Starting drill touchdown"); 
  drilltouchmode();
} //_CODE_:touchDrill:317738:

public void engageDrill_requested(GOption source, GEvent event) { //_CODE_:engageDrill:566793:
  //  println("drillEngage - GOption >> GEvent." + event + " @ " + millis());
  yStepperUpdate.stop();
  xStepperUpdate.stop();
  stepperComplete=-1;
  previousHoles.add(new Hole(slider2d1.getValueXI()+940, slider2d1.getValueYI()+135, (int)(2*maxRadius.getValueF()*500/91)));

  drillmode();
  MSEplot = new GPlot(this); //this refers to draw applet
  MSEpoints1 = new GPointsArray();
  MSEplot.addLayer("layer1", MSEpoints1);
  MSEplot.setPos(1200, 0); //set the position of the plot
  MSEplot.setDim(400, 600); //set the size of the plot
  MSEplot.getTitle().setText("MSE vs Depth");
  MSEplot.getXAxis().getAxisLabel().setText("MSE");
  MSEplot.getYAxis().getAxisLabel().setText("Depth");
  MSEplot.activateZooming(1.5);
  tablename =timestamp();
  table = new Table();
  table.addColumn("timestamp");
  table.addColumn("xpos");
  table.addColumn("ypos");
  table.addColumn("depth");
  table.addColumn("load");
  table.addColumn("torque");
  table.addColumn("current");
  table.addColumn("voltage");
  table.addColumn("RPM");
  table.addColumn("MSE");
  message.setText("Drill engaged");
  //  println("Drill started at "+timestamp());
} //_CODE_:engageDrill:566793:

public void removeDrill_requested(GOption source, GEvent event) { //_CODE_:removeDrill:462038:
  yStepperUpdate.stop();
  xStepperUpdate.stop();
  drillRelay.off();
  //drillStepperUpdate.stop(); //stops timer which sends stepper update requests
  drill_checkbox.setSelected(false);
  removeDrill.setSelected(true);
  arduino.freqDisable(2);
  //drillStepper.halt();
  drillStepper.to(0);
  message.setText("Removing drill");
} //_CODE_:removeDrill:462038:

public void positionExtractor_requested(GOption source, GEvent event) { //_CODE_:positionExtractor:462705:
  yStepperUpdate.start();
  xStepperUpdate.start();
  println("extractor is moved into place using xOffset " + xOffset);
  println("extractor is moved into place using yOffset " + yOffset);
  positionExtractor.setSelected(true);
  //allOff();
  label2.setText("Extractor Position");
  label21.setText("extractor X=");
  label22.setText("extractor Y=");
  label2.setLocalColorScheme(GCScheme.RED_SCHEME);
  xposLabel.setText("des. extr. X=");
  yposLabel.setText("des. extr. Y=");
  offsetExtractor();
  slider2d1.setLocalColorScheme(GCScheme.RED_SCHEME);

  positionX();
  positionY();
  message.setText("Positioning x and y");
} //_CODE_:positionExtractor:462705:

public void touchExtractor_requested(GOption source, GEvent event) { //_CODE_:touchExtractor:339898:
  touch=false; //set touch to be false to use in main loop
  println("extractor needs to be lowered until the hall effect sensor is triggered");
  //touchExtractor.setSelected(true);
  yStepperUpdate.stop();
  xStepperUpdate.stop();
  extractortouchmode();
  message.setText("Extractor touchdown");
  //need to look for change on a digital pin. I haven't picked one for this yet, but we need to watch the pin state in draw() and act there after this is called
} //_CODE_:touchExtractor:339898:

public void engageExtractor_requested(GOption source, GEvent event) { //_CODE_:engageExtractor:295662:
  println("extractor heater is turned on and the pump will be looking for the water level signal to begin pumping");
  //allOff();
  extractorStepperUpdate.start();
  timeelapsed=millis(); //plug in initial time

  arduino.freqDisable(2); // don't measure drill rpm anymore
  arduino.freqConfig(3, 3, 1000); // need to settle on arduino interrupts to use for frequency measurement for drill, extractor pump and period of water sensor
  //float freq = Arduino.freqRead(); 
  engageExtractor.setSelected(true);
  extractormode();
  radiusplot = new GPlot(this); //need to sort this out
  radiuspoints1 = new GPointsArray();
  radiuspoints2 = new GPointsArray();
  radiusplot.addLayer("layer1", radiuspoints1);
  radiusplot.addLayer("layer2", radiuspoints2);
  radiusplot.setPos(1200, 0);
  radiusplot.setDim(400, 600);
  radiusplot.getTitle().setText("radius vs Depth");
  radiusplot.getXAxis().getAxisLabel().setText("radius");
  radiusplot.getYAxis().getAxisLabel().setText("Depth");
  radiusplot.activateZooming(1.5);
  tablename=timestamp();
  table = new Table();
  table.addColumn("timestamp");
  table.addColumn("xpos");
  table.addColumn("ypos");
  table.addColumn("depth");
  table.addColumn("temperature");
  table.addColumn("heaterstate");
  table.addColumn("pumpstate");
  table.addColumn("current");
  table.addColumn("radius");
  message.setText("Extractor moving to: " + nf(desiredDepth) +"\n"+
    "Extractor microstepping: " + nf(extractorMicroStepping) +"\n"+
    "Melt radius: " + nf(radiusMeasured.getValueI()) +"\n"
    );
  //  println("Extractor started at "+timestamp());
} //_CODE_:engageExtractor:295662:

public void removeExtractor_requested(GOption source, GEvent event) { //_CODE_:removeExtractor:798498:

  drillStepperUpdate.stop();
  //extractorStepperUpdate.stop(); //don't stop timer unless we don't want to know where extractor is.
  /**/
  arduino.freqDisable(3); 
  removeExtractor.setSelected(true);
  extractorStepper.to(0);
  heaterRelay.off();
  pumpRelay.off();
  heater_checkbox.setSelected(false);
  message.setText("Removing extractor");
} //_CODE_:removeExtractor:798498:

public void startup_change(GOption source, GEvent event) { //_CODE_:startup:973310:
  allOff();
} //_CODE_:startup:973310:

public void configure_requested(GOption source, GEvent event) { //_CODE_:configure:266601:
  xStepper1.config();
  yStepper.config();
  drillStepper.config(); // configures the drill stepper by sending commands to arduino
  extractorStepper.config();
  drillStepper.setSpeed(drillFeed);
  xStepper1.setSpeed(xSpeed); //xSpeed is in mm/s, setspeed in asSetSpeed() is in steps/s
  extractorStepper.setSpeed(extractorFeed);
  yStepper.setSpeed(ySpeed);
} //_CODE_:configure:266601:

public void desiredX_change(GTextField source, GEvent event) { //_CODE_:desiredX_textbox:216378:
  if (event.toString()=="ENTERED"|event.toString()=="LOST_FOCUS") {
    guiPositionEntry();
  }
} //_CODE_:desiredX_textbox:216378:

public void desiredY_change(GTextField source, GEvent event) { //_CODE_:desiredY_textbox:397758:
  if (event.toString()=="ENTERED"|event.toString()=="LOST_FOCUS") {
    guiPositionEntry();
  }
} //_CODE_:desiredY_textbox:397758:

public void checkbox2_clicked1(GCheckbox source, GEvent event) { //_CODE_:heater_checkbox:454278:
  //println("checkbox2 - GCheckbox >> GEvent." + event + " @ " + millis());
  if  (heaterRelay.getState()==0) {
    heaterRelay.on();
  } else {
    heaterRelay.off();
  }
} //_CODE_:heater_checkbox:454278:

public void pumpcheckbox_event(GCheckbox source, GEvent event) { //_CODE_:pump_checkbox:462291:
  if  (pumpRelay.getState()==0) {
    pumpRelay.on();
  } else {
    pumpRelay.off();
  }
} //_CODE_:pump_checkbox:462291:

public void checkbox5_clicked1(GCheckbox source, GEvent event) { //_CODE_:drill_checkbox:494114:
  if  (drillRelay.getState()==0) {
    drillRelay.on();
  } else {
    drillRelay.off();
  }
} //_CODE_:drill_checkbox:494114:

public void textfield1_change5(GTextField source, GEvent event) { //_CODE_:drillRPM_textbox:916718:
  if (event.toString()=="ENTERED"|event.toString()=="LOST_FOCUS") {
    arduino.pinMode(20, Arduino.I2C);
    arduino.pinMode(21, Arduino.I2C);
    arduino.mcp4725(0x60, floor(drillRPM*4095/541)); //test and check address
  }
} //_CODE_:drillRPM_textbox:916718:

public void timeRemain_change(GTextField source, GEvent event) { //_CODE_:timeRemain:956546:
  updateRadiusCalculator();
} //_CODE_:timeRemain:956546:

public void heightIce_changed(GTextField source, GEvent event) { //_CODE_:heightIce_textbox:545207:
  updateRadiusCalculator();
} //_CODE_:heightIce_textbox:545207:

public void hres_change(GTextField source, GEvent event) { //_CODE_:hres:252169:
  updateRadiusCalculator();
} //_CODE_:hres:252169:

public void flowRate_change(GTextField source, GEvent event) { //_CODE_:flowRate_textbox:329304:
  if (event.toString()=="ENTERED"|event.toString()=="LOST_FOCUS") {
    arduino.pinMode(20, Arduino.I2C);
    arduino.pinMode(21, Arduino.I2C);
    arduino.mcp4725(0x61, floor(flowRate*4095/541)); //verify that address 0x61 is used for DAC which controls pump
  }

  updateRadiusCalculator();
} //_CODE_:flowRate_textbox:329304:

public void xSpeed_change(GTextField source, GEvent event) { //_CODE_:xSpeed_textbox:758412:
  xStepper1.setSpeed(xSpeed);
} //_CODE_:xSpeed_textbox:758412:

public void ySpeed_change(GTextField source, GEvent event) { //_CODE_:ySpeed_textbox:590508:
  yStepper.setSpeed(ySpeed);
} //_CODE_:ySpeed_textbox:590508:

public void drillFeed_change(GTextField source, GEvent event) { //_CODE_:drillFeed_textbox:764349:
  drillStepper.setSpeed(drillFeed);
} //_CODE_:drillFeed_textbox:764349:

public void kP_change(GTextField source, GEvent event) { //_CODE_:kP:830113:
} //_CODE_:kP:830113:

public void kI_change(GTextField source, GEvent event) { //_CODE_:kI:397552:
} //_CODE_:kI:397552:

public void kD_change(GTextField source, GEvent event) { //_CODE_:kD:824235:
} //_CODE_:kD:824235:

public void meltRate_change(GTextField source, GEvent event) { //_CODE_:meltRate:663968:
  updateRadiusCalculator();
} //_CODE_:meltRate:663968:

public void desiredLoad_change(GTextField source, GEvent event) { //_CODE_:desiredLoad_textbox:361615:
  println("the drill will now push with "+desiredLoad_textbox.getValueF());
  message.setText("The drill will now push with "+desiredLoad_textbox.getValueF()+"N");
} //_CODE_:desiredLoad_textbox:361615:

public void textfield1_change9(GTextField source, GEvent event) { //_CODE_:extractorFeed_textbox:378077:
  extractorStepper.setSpeed(extractorFeed);
} //_CODE_:extractorFeed_textbox:378077:

public void extractorTouchSpeed_change(GTextField source, GEvent event) { //_CODE_:extractorTouchSpeed_textbox:914267:
  extractorStepper.setSpeed(extractorTouchSpeed);
} //_CODE_:extractorTouchSpeed_textbox:914267:

public void slider2d1_change1(GSlider2D source, GEvent event) { //_CODE_:slider2d1:753888:
  desiredX=map(slider2d1.getValueXF(), -140, 140, 0.0f, 500f);
  desiredY=map(slider2d1.getValueYF(), -20, 20, 0.0f, 75f);
  desiredX_textbox.setText(nf(desiredX, 0, 1));     //sets displays value on the GUI
  desiredY_textbox.setText(nf(desiredY, 0, 1));
  message.setText("xStepper to: "+nf(desiredX_textbox.getValueF())+"\n"+
    "yStepper to: "+nf(desiredY_textbox.getValueF())+"\n");
  if ((positionDrill.isSelected() | positionExtractor.isSelected()) & event.toString()=="VALUE_STEADY") {
    positionX();
    positionY();
  }
} //_CODE_:slider2d1:753888:

public void extra_checkbox_clicked1(GCheckbox source, GEvent event) { //_CODE_:extra_checkbox:227302:
  if  (extraRelay.getState()==0) {
    extraRelay.on();
  } else {
    extraRelay.off();
  }
} //_CODE_:extra_checkbox:227302:

public void desiredDepth_change3(GTextField source, GEvent event) { //_CODE_:desiredDepth_textbox:302565:
  if (event.toString()=="ENTERED" & (touchDrill.isSelected() | engageDrill.isSelected())) {
    drillStepper.to(desiredDepth);
  } else if (event.toString()=="ENTERED" & (touchExtractor.isSelected() | engageExtractor.isSelected())) { //checks to see if the event is entered and not something else
    extractorStepper.setSpeed(extractorFeed);
    extractorStepper.to(desiredDepth);
  }
} //_CODE_:desiredDepth_textbox:302565:

public void reversePump_event(GCheckbox source, GEvent event) { //_CODE_:reversePump:366846:
  arduino.pinMode(35, Arduino.OUTPUT);
  if  (pumpReverse==false) {
    arduino.digitalWrite(35, Arduino.HIGH);
    pumpReverse = true;
    message.setText("Pump is flowing in reverse direction.");
  } else {
    arduino.digitalWrite(35, Arduino.LOW);
    pumpReverse = false;
    message.setText("Pump is flowing in forward direction.");
  }
} //_CODE_:reversePump:366846:

public void resetLimitButton_event(GButton source, GEvent event) { //_CODE_:resetLimitButton:359544:
  if (event.toString()=="CLICKED") {
    resetLimit=true;
    message.setText("Limit stops reset, you can now move steppers.");
  }
} //_CODE_:resetLimitButton:359544:

public void drillStepperUpdate_event(GTimer source) { //_CODE_:drillStepperUpdate:580066:
  drillStepper.reported=false; //sets internal state in drillStepper so the loop will request a report
  plotted=false;
} //_CODE_:drillStepperUpdate:580066:

public void extractorStepperUpdate_event(GTimer source) { //_CODE_:extractorStepperUpdate:350713:
  extractorStepper.reported=false;
  plotted=false;
} //_CODE_:extractorStepperUpdate:350713:



// Create all the GUI controls. 
// autogenerated do not edit
public void createGUI(){
  G4P.messagesEnabled(false);
  G4P.setGlobalColorScheme(GCScheme.GREEN_SCHEME);
  G4P.setMouseOverEnabled(false);
  G4P.setDisplayFont("Arial", G4P.PLAIN, 20);
  G4P.setInputFont("Arial", G4P.PLAIN, 20);
  G4P.setSliderFont("Arial", G4P.PLAIN, 20);
  surface.setTitle("Sketch Window");
  label2 = new GLabel(this, 516, 12, 168, 30);
  label2.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label2.setText("Drill Position");
  label2.setOpaque(true);
  togGroup1 = new GToggleGroup();
  Homing = new GOption(this, 24, 72, 120, 24);
  Homing.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  Homing.setText("Homing");
  Homing.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  Homing.setOpaque(false);
  Homing.addEventHandler(this, "Homing_requested");
  positionDrill = new GOption(this, 24, 96, 192, 25);
  positionDrill.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  positionDrill.setText("Position Drill (x,y)");
  positionDrill.setLocalColorScheme(GCScheme.BLUE_SCHEME);
  positionDrill.setOpaque(false);
  positionDrill.addEventHandler(this, "positionDrill_requested");
  touchDrill = new GOption(this, 24, 120, 156, 25);
  touchDrill.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  touchDrill.setText("Touch Drill (z)");
  touchDrill.setLocalColorScheme(GCScheme.BLUE_SCHEME);
  touchDrill.setOpaque(false);
  touchDrill.addEventHandler(this, "touchDrill_requested");
  engageDrill = new GOption(this, 25, 144, 168, 25);
  engageDrill.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  engageDrill.setText("Engage Drill");
  engageDrill.setLocalColorScheme(GCScheme.BLUE_SCHEME);
  engageDrill.setOpaque(false);
  engageDrill.addEventHandler(this, "engageDrill_requested");
  removeDrill = new GOption(this, 24, 168, 156, 25);
  removeDrill.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  removeDrill.setText("Remove Drill");
  removeDrill.setLocalColorScheme(GCScheme.BLUE_SCHEME);
  removeDrill.setOpaque(false);
  removeDrill.addEventHandler(this, "removeDrill_requested");
  positionExtractor = new GOption(this, 24, 192, 228, 25);
  positionExtractor.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  positionExtractor.setText("Position Extractor (x,y)");
  positionExtractor.setLocalColorScheme(GCScheme.RED_SCHEME);
  positionExtractor.setOpaque(false);
  positionExtractor.addEventHandler(this, "positionExtractor_requested");
  touchExtractor = new GOption(this, 24, 216, 192, 25);
  touchExtractor.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  touchExtractor.setText("Touch Extractor (z)");
  touchExtractor.setLocalColorScheme(GCScheme.RED_SCHEME);
  touchExtractor.setOpaque(false);
  touchExtractor.addEventHandler(this, "touchExtractor_requested");
  engageExtractor = new GOption(this, 24, 240, 180, 25);
  engageExtractor.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  engageExtractor.setText("Engage Extractor");
  engageExtractor.setLocalColorScheme(GCScheme.RED_SCHEME);
  engageExtractor.setOpaque(false);
  engageExtractor.addEventHandler(this, "engageExtractor_requested");
  removeExtractor = new GOption(this, 24, 264, 192, 25);
  removeExtractor.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  removeExtractor.setText("Remove Extractor");
  removeExtractor.setLocalColorScheme(GCScheme.RED_SCHEME);
  removeExtractor.setOpaque(false);
  removeExtractor.addEventHandler(this, "removeExtractor_requested");
  startup = new GOption(this, 24, 48, 192, 24);
  startup.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  startup.setText("Startup (no action)");
  startup.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  startup.setOpaque(false);
  startup.addEventHandler(this, "startup_change");
  configure = new GOption(this, 144, 72, 120, 24);
  configure.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  configure.setText("Configure");
  configure.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  configure.setOpaque(false);
  configure.addEventHandler(this, "configure_requested");
  togGroup1.addControl(Homing);
  togGroup1.addControl(positionDrill);
  togGroup1.addControl(touchDrill);
  togGroup1.addControl(engageDrill);
  togGroup1.addControl(removeDrill);
  togGroup1.addControl(positionExtractor);
  togGroup1.addControl(touchExtractor);
  togGroup1.addControl(engageExtractor);
  togGroup1.addControl(removeExtractor);
  togGroup1.addControl(startup);
  startup.setSelected(true);
  togGroup1.addControl(configure);
  desiredX_textbox = new GTextField(this, 624, 48, 60, 30, G4P.SCROLLBARS_NONE);
  desiredX_textbox.setText("0.0");
  desiredX_textbox.setOpaque(true);
  desiredX_textbox.addEventHandler(this, "desiredX_change");
  desiredY_textbox = new GTextField(this, 624, 84, 60, 30, G4P.SCROLLBARS_NONE);
  desiredY_textbox.setText("0.0");
  desiredY_textbox.setOpaque(true);
  desiredY_textbox.addEventHandler(this, "desiredY_change");
  drillZ = new GTextField(this, 936, 264, 60, 30, G4P.SCROLLBARS_NONE);
  drillZ.setText("0.0");
  drillZ.setOpaque(true);
  heater_checkbox = new GCheckbox(this, 36, 408, 120, 36);
  heater_checkbox.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  heater_checkbox.setText("Heater");
  heater_checkbox.setOpaque(false);
  heater_checkbox.addEventHandler(this, "checkbox2_clicked1");
  pump_checkbox = new GCheckbox(this, 36, 444, 120, 36);
  pump_checkbox.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  pump_checkbox.setText("Pump");
  pump_checkbox.setOpaque(false);
  pump_checkbox.addEventHandler(this, "pumpcheckbox_event");
  label3 = new GLabel(this, 12, 12, 228, 30);
  label3.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label3.setText("Extraction Steps");
  label3.setOpaque(true);
  drill_checkbox = new GCheckbox(this, 36, 373, 120, 36);
  drill_checkbox.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  drill_checkbox.setText("Drill");
  drill_checkbox.setOpaque(false);
  drill_checkbox.addEventHandler(this, "checkbox5_clicked1");
  label7 = new GLabel(this, 828, 324, 348, 36);
  label7.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label7.setText("Measured and Calculated Values");
  label7.setOpaque(true);
  loadcell = new GTextField(this, 720, 420, 70, 30, G4P.SCROLLBARS_NONE);
  loadcell.setText("loadcell");
  loadcell.setOpaque(true);
  drillRPM_textbox = new GTextField(this, 324, 420, 70, 30, G4P.SCROLLBARS_NONE);
  drillRPM_textbox.setText("360");
  drillRPM_textbox.setOpaque(true);
  drillRPM_textbox.addEventHandler(this, "textfield1_change5");
  torque = new GTextField(this, 912, 372, 70, 30, G4P.SCROLLBARS_NONE);
  torque.setText("0.0");
  torque.setOpaque(true);
  current = new GTextField(this, 912, 420, 70, 30, G4P.SCROLLBARS_NONE);
  current.setText("current");
  current.setOpaque(true);
  label8 = new GLabel(this, 612, 420, 108, 24);
  label8.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label8.setText("actual load");
  label8.setOpaque(false);
  label12 = new GLabel(this, 228, 420, 96, 24);
  label12.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label12.setText("set RPM");
  label12.setOpaque(false);
  label9 = new GLabel(this, 840, 372, 72, 24);
  label9.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label9.setText("torque");
  label9.setOpaque(false);
  label10 = new GLabel(this, 819, 408, 90, 48);
  label10.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label10.setText("RMS drill current");
  label10.setOpaque(false);
  label11 = new GLabel(this, 1008, 372, 96, 24);
  label11.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label11.setText("hardness");
  label11.setOpaque(false);
  MSE_textbox = new GTextField(this, 1104, 372, 70, 30, G4P.SCROLLBARS_NONE);
  MSE_textbox.setText("MSE");
  MSE_textbox.setOpaque(true);
  label13 = new GLabel(this, 36, 660, 108, 20);
  label13.setText("minutes left");
  label13.setOpaque(false);
  label14 = new GLabel(this, 36, 720, 120, 20);
  label14.setText("height of ice");
  label14.setOpaque(false);
  label15 = new GLabel(this, 180, 600, 84, 20);
  label15.setText("hdot");
  label15.setOpaque(false);
  timeRemain = new GTextField(this, 48, 684, 84, 30, G4P.SCROLLBARS_NONE);
  timeRemain.setText("360");
  timeRemain.setOpaque(true);
  timeRemain.addEventHandler(this, "timeRemain_change");
  heightIce_textbox = new GTextField(this, 48, 744, 84, 30, G4P.SCROLLBARS_NONE);
  heightIce_textbox.setText("500");
  heightIce_textbox.setOpaque(true);
  heightIce_textbox.addEventHandler(this, "heightIce_changed");
  hdot = new GTextField(this, 180, 624, 84, 30, G4P.SCROLLBARS_NONE);
  hdot.setOpaque(true);
  label16 = new GLabel(this, 312, 660, 108, 20);
  label16.setText("max radius");
  label16.setOpaque(false);
  maxRadius = new GTextField(this, 312, 684, 80, 30, G4P.SCROLLBARS_NONE);
  maxRadius.setText("360");
  maxRadius.setOpaque(true);
  label17 = new GLabel(this, 180, 660, 108, 23);
  label17.setText("height res.");
  label17.setOpaque(false);
  hres = new GTextField(this, 180, 684, 84, 30, G4P.SCROLLBARS_NONE);
  hres.setText("5");
  hres.setOpaque(true);
  hres.addEventHandler(this, "hres_change");
  label18 = new GLabel(this, 312, 600, 80, 20);
  label18.setText("delay");
  label18.setOpaque(false);
  label19 = new GLabel(this, 480, 720, 156, 20);
  label19.setText("period");
  label19.setOpaque(false);
  periodMeasured = new GTextField(this, 480, 744, 80, 30, G4P.SCROLLBARS_NONE);
  periodMeasured.setOpaque(true);
  label4 = new GLabel(this, 12, 324, 180, 48);
  label4.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label4.setText("AC Device Override");
  label4.setLocalColorScheme(GCScheme.RED_SCHEME);
  label4.setOpaque(true);
  xposLabel = new GLabel(this, 504, 48, 120, 24);
  xposLabel.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  xposLabel.setText("des. drill X=");
  xposLabel.setOpaque(false);
  yposLabel = new GLabel(this, 504, 84, 120, 24);
  yposLabel.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  yposLabel.setText("des. drill Y=");
  yposLabel.setOpaque(false);
  zposLabel = new GLabel(this, 864, 264, 72, 30);
  zposLabel.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  zposLabel.setText("drill Z=");
  zposLabel.setOpaque(false);
  label25 = new GLabel(this, 300, 12, 192, 30);
  label25.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label25.setText("Stepper Settings");
  label25.setOpaque(true);
  label26 = new GLabel(this, 636, 600, 108, 20);
  label26.setText("flow rate");
  label26.setOpaque(false);
  flowRate_textbox = new GTextField(this, 637, 624, 84, 30, G4P.SCROLLBARS_NONE);
  flowRate_textbox.setText("140");
  flowRate_textbox.setOpaque(true);
  flowRate_textbox.addEventHandler(this, "flowRate_change");
  label27 = new GLabel(this, 636, 720, 84, 20);
  label27.setText("radius");
  label27.setOpaque(false);
  radiusMeasured = new GTextField(this, 636, 744, 80, 30, G4P.SCROLLBARS_NONE);
  radiusMeasured.setText("19");
  radiusMeasured.setOpaque(true);
  label28 = new GLabel(this, 300, 48, 96, 30);
  label28.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label28.setText("x Speed");
  label28.setOpaque(false);
  label29 = new GLabel(this, 312, 96, 84, 30);
  label29.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label29.setText("y Speed");
  label29.setOpaque(false);
  label30 = new GLabel(this, 228, 372, 96, 24);
  label30.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label30.setText("drill feed");
  label30.setOpaque(false);
  xSpeed_textbox = new GTextField(this, 408, 48, 72, 30, G4P.SCROLLBARS_NONE);
  xSpeed_textbox.setText("20");
  xSpeed_textbox.setOpaque(true);
  xSpeed_textbox.addEventHandler(this, "xSpeed_change");
  ySpeed_textbox = new GTextField(this, 408, 96, 72, 30, G4P.SCROLLBARS_NONE);
  ySpeed_textbox.setText("20");
  ySpeed_textbox.setOpaque(true);
  ySpeed_textbox.addEventHandler(this, "ySpeed_change");
  drillFeed_textbox = new GTextField(this, 324, 372, 70, 30, G4P.SCROLLBARS_NONE);
  drillFeed_textbox.setText("5");
  drillFeed_textbox.setOpaque(true);
  drillFeed_textbox.addEventHandler(this, "drillFeed_change");
  extractorStepperSpeed = new GLabel(this, 480, 600, 132, 19);
  extractorStepperSpeed.setText("extractor feed");
  extractorStepperSpeed.setOpaque(false);
  label24 = new GLabel(this, 240, 324, 151, 36);
  label24.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label24.setText("Drill Settings");
  label24.setOpaque(true);
  label31 = new GLabel(this, 444, 372, 96, 24);
  label31.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label31.setText("KP Gain");
  label31.setOpaque(false);
  kP = new GTextField(this, 540, 372, 70, 30, G4P.SCROLLBARS_NONE);
  kP.setText("1.0");
  kP.setOpaque(true);
  kP.addEventHandler(this, "kP_change");
  label32 = new GLabel(this, 444, 420, 96, 24);
  label32.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label32.setText("KI Gain");
  label32.setOpaque(false);
  kI = new GTextField(this, 540, 420, 70, 30, G4P.SCROLLBARS_NONE);
  kI.setText("1.0");
  kI.setOpaque(true);
  kI.addEventHandler(this, "kI_change");
  label33 = new GLabel(this, 444, 468, 96, 24);
  label33.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label33.setText("KD Gain");
  label33.setOpaque(false);
  kD = new GTextField(this, 540, 468, 70, 30, G4P.SCROLLBARS_NONE);
  kD.setText("1.0");
  kD.setOpaque(true);
  kD.addEventHandler(this, "kD_change");
  label5 = new GLabel(this, 180, 720, 84, 20);
  label5.setText("melt rate");
  label5.setOpaque(false);
  meltRate = new GTextField(this, 180, 744, 84, 30, G4P.SCROLLBARS_NONE);
  meltRate.setText("135");
  meltRate.setOpaque(true);
  meltRate.addEventHandler(this, "meltRate_change");
  label23 = new GLabel(this, 84, 552, 264, 36);
  label23.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label23.setText("Extractor Calculations");
  label23.setOpaque(true);
  label35 = new GLabel(this, 36, 600, 120, 20);
  label35.setText("current time");
  label35.setOpaque(false);
  currentTime = new GTextField(this, 48, 624, 84, 30, G4P.SCROLLBARS_NONE);
  currentTime.setOpaque(true);
  label36 = new GLabel(this, 480, 552, 264, 36);
  label36.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label36.setText("Extractor Settings");
  label36.setOpaque(true);
  label37 = new GLabel(this, 480, 672, 264, 36);
  label37.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label37.setText("Extractor Measurements");
  label37.setOpaque(true);
  label39 = new GLabel(this, 216, 468, 108, 24);
  label39.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label39.setText("actual RPM");
  label39.setOpaque(false);
  measuredDrillRPM = new GTextField(this, 324, 469, 70, 30, G4P.SCROLLBARS_NONE);
  measuredDrillRPM.setOpaque(true);
  pumpDelay_textbox = new GTextField(this, 312, 624, 84, 30, G4P.SCROLLBARS_NONE);
  pumpDelay_textbox.setOpaque(true);
  label41 = new GLabel(this, 444, 324, 348, 36);
  label41.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label41.setText("Load Cell Regulation");
  label41.setOpaque(true);
  label42 = new GLabel(this, 624, 372, 96, 24);
  label42.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label42.setText("set load");
  label42.setOpaque(false);
  desiredLoad_textbox = new GTextField(this, 720, 372, 72, 30, G4P.SCROLLBARS_NONE);
  desiredLoad_textbox.setOpaque(true);
  desiredLoad_textbox.addEventHandler(this, "desiredLoad_change");
  extractorFeed_textbox = new GTextField(this, 480, 624, 84, 30, G4P.SCROLLBARS_NONE);
  extractorFeed_textbox.setText("1.4");
  extractorFeed_textbox.setOpaque(true);
  extractorFeed_textbox.addEventHandler(this, "textfield1_change9");
  label38 = new GLabel(this, 275, 137, 120, 48);
  label38.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label38.setText("extractor touch speed");
  label38.setOpaque(false);
  extractorTouchSpeed_textbox = new GTextField(this, 408, 144, 72, 36, G4P.SCROLLBARS_NONE);
  extractorTouchSpeed_textbox.setText("10");
  extractorTouchSpeed_textbox.setOpaque(true);
  extractorTouchSpeed_textbox.addEventHandler(this, "extractorTouchSpeed_change");
  slider2d1 = new GSlider2D(this, 804, 120, 280, 40);
  slider2d1.setLimitsX(-140.0, -140.0, 140.0);
  slider2d1.setLimitsY(-20.0, -20.0, 20.0);
  slider2d1.setNumberFormat(G4P.DECIMAL, 2);
  slider2d1.setOpaque(true);
  slider2d1.addEventHandler(this, "slider2d1_change1");
  extra_checkbox = new GCheckbox(this, 36, 480, 120, 36);
  extra_checkbox.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  extra_checkbox.setText("Extra");
  extra_checkbox.setOpaque(false);
  extra_checkbox.addEventHandler(this, "extra_checkbox_clicked1");
  desiredDepth_textbox = new GTextField(this, 624, 120, 60, 30, G4P.SCROLLBARS_NONE);
  desiredDepth_textbox.setText("500");
  desiredDepth_textbox.setOpaque(true);
  desiredDepth_textbox.addEventHandler(this, "desiredDepth_change3");
  label20 = new GLabel(this, 492, 120, 132, 24);
  label20.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label20.setText("des. depth=");
  label20.setOpaque(false);
  stepperX = new GTextField(this, 624, 264, 60, 30, G4P.SCROLLBARS_NONE);
  stepperX.setText("0.0");
  stepperX.setOpaque(true);
  stepperY = new GTextField(this, 804, 264, 60, 30, G4P.SCROLLBARS_NONE);
  stepperY.setText("0.0");
  stepperY.setOpaque(true);
  label21 = new GLabel(this, 492, 264, 132, 30);
  label21.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label21.setText("drill X=");
  label21.setOpaque(false);
  label22 = new GLabel(this, 684, 264, 120, 30);
  label22.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label22.setText("drill Y=");
  label22.setOpaque(false);
  label40 = new GLabel(this, 996, 264, 120, 30);
  label40.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label40.setText("extractor Z=");
  label40.setOpaque(false);
  extractorZ = new GTextField(this, 1116, 264, 60, 30, G4P.SCROLLBARS_NONE);
  extractorZ.setText("0.0");
  extractorZ.setOpaque(true);
  label6 = new GLabel(this, 888, 468, 132, 48);
  label6.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label6.setText("extractor temperature");
  label6.setOpaque(false);
  temperature = new GTextField(this, 1044, 468, 72, 30, G4P.SCROLLBARS_NONE);
  temperature.setOpaque(true);
  message = new GTextArea(this, 816, 588, 357, 108, G4P.SCROLLBARS_NONE);
  message.setOpaque(true);
  label34 = new GLabel(this, 312, 720, 108, 20);
  label34.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  label34.setText("pump RPM");
  label34.setOpaque(false);
  pumpRPM = new GTextField(this, 312, 744, 84, 30, G4P.SCROLLBARS_NONE);
  pumpRPM.setOpaque(true);
  label43 = new GLabel(this, 1008, 408, 84, 48);
  label43.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  label43.setText("overall current");
  label43.setOpaque(false);
  systemcurrent = new GTextField(this, 1104, 420, 72, 30, G4P.SCROLLBARS_NONE);
  systemcurrent.setOpaque(true);
  reversePump = new GCheckbox(this, 312, 192, 155, 31);
  reversePump.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  reversePump.setText("reverse pump");
  reversePump.setOpaque(false);
  reversePump.addEventHandler(this, "reversePump_event");
  resetLimitButton = new GButton(this, 816, 708, 140, 60);
  resetLimitButton.setText("Reset Limit Swich");
  resetLimitButton.addEventHandler(this, "resetLimitButton_event");
  drillStepperUpdate = new GTimer(this, this, "drillStepperUpdate_event", 500);
  extractorStepperUpdate = new GTimer(this, this, "extractorStepperUpdate_event", 1000);
}

// Variable declarations 
// autogenerated do not edit
GLabel label2; 
GToggleGroup togGroup1; 
GOption Homing; 
GOption positionDrill; 
GOption touchDrill; 
GOption engageDrill; 
GOption removeDrill; 
GOption positionExtractor; 
GOption touchExtractor; 
GOption engageExtractor; 
GOption removeExtractor; 
GOption startup; 
GOption configure; 
GTextField desiredX_textbox; 
GTextField desiredY_textbox; 
GTextField drillZ; 
GCheckbox heater_checkbox; 
GCheckbox pump_checkbox; 
GLabel label3; 
GCheckbox drill_checkbox; 
GLabel label7; 
GTextField loadcell; 
GTextField drillRPM_textbox; 
GTextField torque; 
GTextField current; 
GLabel label8; 
GLabel label12; 
GLabel label9; 
GLabel label10; 
GLabel label11; 
GTextField MSE_textbox; 
GLabel label13; 
GLabel label14; 
GLabel label15; 
GTextField timeRemain; 
GTextField heightIce_textbox; 
GTextField hdot; 
GLabel label16; 
GTextField maxRadius; 
GLabel label17; 
GTextField hres; 
GLabel label18; 
GLabel label19; 
GTextField periodMeasured; 
GLabel label4; 
GLabel xposLabel; 
GLabel yposLabel; 
GLabel zposLabel; 
GLabel label25; 
GLabel label26; 
GTextField flowRate_textbox; 
GLabel label27; 
GTextField radiusMeasured; 
GLabel label28; 
GLabel label29; 
GLabel label30; 
GTextField xSpeed_textbox; 
GTextField ySpeed_textbox; 
GTextField drillFeed_textbox; 
GLabel extractorStepperSpeed; 
GLabel label24; 
GLabel label31; 
GTextField kP; 
GLabel label32; 
GTextField kI; 
GLabel label33; 
GTextField kD; 
GLabel label5; 
GTextField meltRate; 
GLabel label23; 
GLabel label35; 
GTextField currentTime; 
GLabel label36; 
GLabel label37; 
GLabel label39; 
GTextField measuredDrillRPM; 
GTextField pumpDelay_textbox; 
GLabel label41; 
GLabel label42; 
GTextField desiredLoad_textbox; 
GTextField extractorFeed_textbox; 
GLabel label38; 
GTextField extractorTouchSpeed_textbox; 
GSlider2D slider2d1; 
GCheckbox extra_checkbox; 
GTextField desiredDepth_textbox; 
GLabel label20; 
GTextField stepperX; 
GTextField stepperY; 
GLabel label21; 
GLabel label22; 
GLabel label40; 
GTextField extractorZ; 
GLabel label6; 
GTextField temperature; 
GTextArea message; 
GLabel label34; 
GTextField pumpRPM; 
GLabel label43; 
GTextField systemcurrent; 
GCheckbox reversePump; 
GButton resetLimitButton; 
GTimer drillStepperUpdate; 
GTimer extractorStepperUpdate; 
