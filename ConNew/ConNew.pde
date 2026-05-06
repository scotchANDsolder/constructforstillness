/*
 * A Construct for Stillness - Processing Display
 * TIGHT TRACKING, NO JITTER, AUTO-SAVE SETTINGS
 * Added: Manual Bar Offset for alignment
 */

import processing.serial.*;

// --- CONFIGURATION ---
int BAR_WIDTH = 80;
int BAR_OFFSET = 0; // NEW: Manual alignment nudge
color BAR_COLOR = color(255, 220, 0);
float compensation = 1.0;
final float COMP_ADJUST = 0.005; 
final float SMOOTH_FACTOR = 0.15; 
final int TOTAL_STEPS = 360000;
final int MOVE_DURATION_MS = 30000; 

// --- STATE MACHINE ---
final int STATE_STARTUP = 0;
final int STATE_HOMING_INIT = 1;  
final int STATE_CENTERING = 2;    
final int STATE_SWEEP_LEFT = 3;   
final int STATE_SWEEP_RIGHT = 4;        

// --- SYSTEM VARIABLES ---
Serial port;
boolean connected = false;
boolean debug = true; 
long current_position = 0;
float smooth_position = 0;
int state = STATE_STARTUP;
long state_start_time = 0;
boolean tuning_mode = false; 

void settings() {
  fullScreen(P3D);
}

void setup() {
  frameRate(60);
  loadSettings();
  
  println("AVAILABLE SERIAL PORTS:");
  printArray(Serial.list()); 
  
  try {
    String portName = "/dev/arduinowifi"; 
    port = new Serial(this, portName, 115200);
    port.bufferUntil('\n');
    connected = true;
  } catch (Exception e) {
    connected = false;
    println("FAILED: Running in DEMO mode.");
  }
}

void draw() {
  background(0);
  noCursor();
  run_state();

  if (state < STATE_SWEEP_LEFT && !tuning_mode) { 
    fill(200); 
    textSize(48); 
    textAlign(CENTER, CENTER);
    text(get_state_name(state) + "...", width/2, height/2);
    if (debug) draw_debug(0, 0);
    return;
  }

  // Smooth out the incoming gantry steps
  smooth_position = lerp(smooth_position, (float)current_position, SMOOTH_FACTOR);
  float normalized = smooth_position / (float)TOTAL_STEPS;
  
  // Calculate movement based on motor progress
  float comp_offset = (normalized - 0.5) * width / 2.0 * compensation;
  
  // FINAL POSITION: Center + Movement + Manual Offset
  float bar_x = (width / 2.0) - (BAR_WIDTH / 2.0) + comp_offset + BAR_OFFSET;
  
  fill(BAR_COLOR); 
  noStroke();
  rect(bar_x, 0, BAR_WIDTH, height);

  if (debug) draw_debug(bar_x, comp_offset);
}

void run_state() {
  if (state == STATE_STARTUP) {
    if (state_start_time == 0) state_start_time = millis();
    if (millis() - state_start_time > 5000) {
      send("HOME"); 
      state = STATE_HOMING_INIT;
    }
  }
}

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);

  if (line.startsWith("POS:")) {
    current_position = Long.parseLong(line.substring(4));
  } 
  else if (line.equals("HOME")) {
    if (state == STATE_HOMING_INIT) {
      send("MOVE " + (TOTAL_STEPS / 2) + " " + (MOVE_DURATION_MS / 2)); 
      state = STATE_CENTERING;
    } 
  } 
  else if (line.equals("DONE")) {
    if (state == STATE_CENTERING) {
      send("MOVE " + TOTAL_STEPS + " " + (MOVE_DURATION_MS / 2));
      state = STATE_SWEEP_LEFT;
    } 
    else if (state == STATE_SWEEP_LEFT) {
      send("MOVE 0 " + MOVE_DURATION_MS);
      state = STATE_SWEEP_RIGHT;
    }
    else if (state == STATE_SWEEP_RIGHT) {
      current_position = 0; 
      send("MOVE " + TOTAL_STEPS + " " + MOVE_DURATION_MS);
      state = STATE_SWEEP_LEFT;
    }
  }
}

void send(String cmd) {
  if (port != null && connected) port.write(cmd + "\n");
}

String get_state_name(int s) {
  String[] names = {"STARTUP", "HOMING", "CENTERING", "SWEEP LEFT", "SWEEP RIGHT"};
  return (s >= 0 && s < names.length) ? names[s] : "UNKNOWN";
}

void draw_debug(float bar_x, float comp_offset) {
  fill(0, 230); 
  rect(10, 10, 520, 310); 
  
  fill(255); 
  textSize(12); 
  textAlign(LEFT, TOP);
  
  int y = 25;
  text("STATE: " + get_state_name(state), 20, y); y += 22;
  
  float pct = (float)current_position / TOTAL_STEPS;
  text("Gantry Progress: " + nf(pct * 100, 0, 1) + "% (" + current_position + " steps)", 20, y); y += 22;
  text("Compensation: " + nf(compensation, 0, 4), 20, y); y += 22;
  text("Screen Offset (Dynamic): " + nf(comp_offset, 0, 1) + " px", 20, y); y += 22;
  text("Manual Alignment (Static): " + BAR_OFFSET + " px", 20, y); y += 22;
  text("Bar Width: " + BAR_WIDTH + " px", 20, y); y += 40; 

  stroke(255, 100); 
  line(30, y, 490, y);
  
  fill(255); 
  float gantry_screen_x = 30 + ((1.0 - pct) * 460); 
  ellipse(gantry_screen_x, y, 12, 12); 
  text("Gantry", gantry_screen_x - 15, y - 20);
  
  fill(BAR_COLOR); 
  // Visual representation of the offset influence in debug mode
  float bar_screen_x = 30 + (pct * 460) + (BAR_OFFSET * 0.05); 
  ellipse(bar_screen_x, y, 8, 8); 
  text("Bar Target", bar_screen_x - 25, y + 15);
  
  y += 50;
  fill(150, 200, 255);
  text("KEYS: +/-=Comp | [/]=Width | Arrows=Offset | R=Home | D=Debug", 20, y);
}

void loadSettings() {
  File f = new File(dataPath("settings.json"));
  if (f.exists()) {
    JSONObject json = loadJSONObject("data/settings.json");
    BAR_WIDTH = json.getInt("barWidth", 80);
    BAR_OFFSET = json.getInt("barOffset", 0);
    compensation = json.getFloat("compensation", 1.0);
    println("Settings Loaded.");
  } else {
    println("No settings file. Using defaults.");
  }
}

void saveSettings() {
  JSONObject json = new JSONObject();
  json.setInt("barWidth", BAR_WIDTH);
  json.setInt("barOffset", BAR_OFFSET);
  json.setFloat("compensation", compensation);
  saveJSONObject(json, "data/settings.json");
  println("Settings auto-saved.");
}

void keyPressed() {
  boolean settingsChanged = false;
  
  // Simple key characters
  if (key == '+' || key == '=') { compensation += COMP_ADJUST; settingsChanged = true; }
  else if (key == '-' || key == '_') { compensation = max(0, compensation - COMP_ADJUST); settingsChanged = true; }
  else if (key == '[') { BAR_WIDTH = max(5, BAR_WIDTH - 5); settingsChanged = true; }
  else if (key == ']') { BAR_WIDTH += 5; settingsChanged = true; }
  else if (key == 'r' || key == 'R') { send("HOME"); state = STATE_HOMING_INIT; }
  else if (key == 'q' || key == 'Q') { send("STOP"); exit(); }
  else if (key == 'd' || key == 'D') debug = !debug;
  else if (key == 't' || key == 'T') tuning_mode = !tuning_mode;
  
  // Special coded keys (Arrows)
  if (key == CODED) {
    if (keyCode == LEFT) { BAR_OFFSET -= 2; settingsChanged = true; }
    else if (keyCode == RIGHT) { BAR_OFFSET += 2; settingsChanged = true; }
  }
  
  if (settingsChanged) {
    saveSettings();
  }
}
