/*
 * A Construct for Stillness - Processing Display with Direct Arduino Control
 * Connects directly to Arduino, receives position feedback, displays synchronized light bar
 */

import processing.serial.*;

Serial arduino;

// Display parameters
float bar_x = 0;
float bar_width = 80;  // Width in pixels (50-100 for VS250's 1024px width)
                       // Adjust based on visibility: smaller = more apparent motion, larger = solid bar
int display_width;
int display_height;

// Gantry parameters
float gantry_width_mm = 1000;
float gantry_position_mm = 0;
float target_position_mm = 0;
float pixels_per_mm = 0;
float gantry_center_offset = 0;

// Movement parameters
float current_speed_mm_per_sec = 100;
float max_speed_mm_per_sec = 150;

// Visualization
boolean show_debug = false;
boolean show_position = true;
long last_update = 0;
float smoothed_position = 0;
float smoothing = 0.1;  // Lower = smoother, Higher = more responsive

// Movement pattern
ArrayList<Float> movement_pattern;
int current_pattern_index = 0;
boolean is_moving = false;

// Serial communication
String inBuffer = "";
int baud_rate = 115200;

void settings() {
  // Epson VS250 is 1024x768 native (XGA)
  // Options:
  
  // Option A: Native VS250 resolution (recommended)
  size(1024, 768, P2D);
  
  // Option B: Fullscreen (auto-detects projector resolution)
  // fullScreen(P2D);
  
  // Option C: For development/testing
  // size(800, 600, P2D);
}

void setup() {
  display_width = width;
  display_height = height;
  
  // Calculate pixels per mm based on display dimensions
  // For VS250 at 1024x768, if your gantry is 1000mm wide:
  // pixels_per_mm will be 1024 / 1000 = 1.024
  pixels_per_mm = display_width / gantry_width_mm;
  gantry_center_offset = display_width / 2.0;
  
  // Initialize movement pattern (% of gantry width)
  movement_pattern = new ArrayList<Float>();
  movement_pattern.add(0.5);   // Center
  movement_pattern.add(0.8);   // Right
  movement_pattern.add(0.2);   // Left
  movement_pattern.add(0.5);   // Center
  
  // Connect to Arduino
  connectToArduino();
  
  // Set background
  background(0);
  
  println("=== A Construct for Stillness ===");
  println("Display: " + display_width + "x" + display_height);
  println("Gantry width: " + gantry_width_mm + "mm");
  println("Pixels/mm: " + nf(pixels_per_mm, 0, 3));
  println("Projector: Epson VS250 (1024x768 native)");
  println("");
  println("Controls:");
  println("  'd' = debug info");
  println("  's' = start/stop movement");
  println("  'r' = reset (home to limit)");
  println("  '+/-' = adjust speed");
  println("  'p' = position display");
  println("  'q' = quit");
}

void draw() {
  // Black background
  background(0);
  
  // Apply smoothing to position for fluid motion
  smoothed_position = lerp(smoothed_position, gantry_position_mm, smoothing);
  
  // Calculate bar position (inverse relationship with gantry position)
  // When gantry moves right (+), image shifts left (-)
  bar_x = gantry_center_offset - (smoothed_position * pixels_per_mm);
  
  // Draw white vertical bar
  fill(255);
  noStroke();
  rect(bar_x, 0, bar_width, display_height);
  
  // Optional: draw subtle center reference line
  stroke(50);
  strokeWeight(1);
  line(gantry_center_offset, 0, gantry_center_offset, display_height);
  
  // Position indicator at bottom
  if (show_position) {
    drawPositionIndicator();
  }
  
  // Debug visualization
  if (show_debug) {
    drawDebugInfo();
  }
  
  // Read serial feedback from Arduino
  readArduinoFeedback();
}

void drawPositionIndicator() {
  fill(255);
  textAlign(CENTER);
  textSize(14);
  
  String position_text = nf(gantry_position_mm, 0, 1) + " mm";
  text(position_text, display_width / 2, display_height - 20);
}

void drawDebugInfo() {
  fill(0, 150);
  rect(10, 10, 500, 250);
  
  fill(255);
  textAlign(LEFT);
  textSize(14);
  
  int y = 30;
  int line_height = 25;
  
  text("=== Debug Info ===", 20, y);
  y += line_height;
  
  text("Gantry Position: " + nf(gantry_position_mm, 0, 2) + " mm", 20, y);
  y += line_height;
  
  text("Target Position: " + nf(target_position_mm, 0, 2) + " mm", 20, y);
  y += line_height;
  
  text("Bar X: " + nf(bar_x, 0, 1) + " px", 20, y);
  y += line_height;
  
  text("Pixels/mm: " + nf(pixels_per_mm, 0, 3), 20, y);
  y += line_height;
  
  text("Speed: " + nf(current_speed_mm_per_sec, 0, 1) + " mm/s", 20, y);
  y += line_height;
  
  text("FPS: " + nf(frameRate, 0, 1), 20, y);
  y += line_height;
  
  long elapsed = millis() - last_update;
  text("Last serial update: " + elapsed + " ms", 20, y);
  y += line_height;
  
  text("Arduino connected: " + (arduino != null && arduino.available() > 0 ? "YES" : "NO"), 20, y);
  y += line_height;
  
  text("Moving: " + (is_moving ? "YES" : "NO"), 20, y);
  y += line_height;
  
  text("Pattern index: " + current_pattern_index + " / " + movement_pattern.size(), 20, y);
  y += line_height;
  
  // Show available keys
  y += line_height;
  text("Keys: d=debug, s=start/stop, r=reset, +/-=speed, space=test", 20, y);
}

void connectToArduino() {
  try {
    // List all available ports
    println("\nAvailable serial ports:");
    for (String port : Serial.list()) {
      println("  - " + port);
    }
    
    // Try to connect to the first USB port (usually Arduino)
    String port = Serial.list()[Serial.list().length - 1];
    println("\nConnecting to: " + port);
    
    arduino = new Serial(this, port, baud_rate);
    arduino.bufferUntil('\n');
    
    println("Arduino connected!");
    delay(2000);  // Wait for Arduino to reset
    
    // Send initial configuration
    sendCommand("STATUS");
    
  } catch (Exception e) {
    println("Error connecting to Arduino: " + e);
    println("Make sure Arduino is connected and check the port");
  }
}

void readArduinoFeedback() {
  if (arduino == null || !arduino.available()) {
    return;
  }
  
  try {
    while (arduino.available() > 0) {
      int inByte = arduino.read();
      
      if (inByte == '\n') {
        // Process complete line
        processArduinoMessage(inBuffer.trim());
        inBuffer = "";
      } else if (inByte != '\r') {
        inBuffer += char(inByte);
      }
    }
  } catch (Exception e) {
    println("Serial read error: " + e);
  }
}

void processArduinoMessage(String message) {
  if (message.length() == 0) return;
  
  last_update = millis();
  
  if (message.startsWith("POS:")) {
    // Position feedback: "POS: 250.5"
    try {
      String value = message.substring(4).trim();
      gantry_position_mm = Float.parseFloat(value);
    } catch (NumberFormatException e) {
      println("Error parsing position: " + message);
    }
  } 
  else if (message.startsWith("HOME")) {
    println("Gantry homed to limit switch");
    gantry_position_mm = 0;
    smoothed_position = 0;
  }
  else if (message.startsWith("DONE")) {
    println("Movement complete");
    is_moving = false;
  }
  else if (message.startsWith("STATUS:")) {
    println("Arduino status: " + message);
  }
  else if (message.startsWith("ERR:")) {
    println("Arduino error: " + message);
  }
  else {
    // Generic message from Arduino
    println("Arduino: " + message);
  }
}

void sendCommand(String command) {
  if (arduino == null) {
    println("Arduino not connected");
    return;
  }
  
  arduino.write(command + "\n");
  println("> Sent: " + command);
}

void startMovementCycle() {
  if (is_moving) {
    println("Already moving");
    return;
  }
  
  println("Starting movement cycle...");
  is_moving = true;
  current_pattern_index = 0;
  moveToNextPatternPoint();
}

void stopMovement() {
  println("Stopping movement");
  is_moving = false;
  sendCommand("STOP");
}

void moveToNextPatternPoint() {
  if (!is_moving || movement_pattern.size() == 0) {
    return;
  }
  
  // Get next target position as percentage of gantry width
  float percentage = movement_pattern.get(current_pattern_index);
  target_position_mm = percentage * gantry_width_mm;
  
  // Calculate movement duration
  float distance = abs(target_position_mm - gantry_position_mm);
  float duration_sec = distance / current_speed_mm_per_sec;
  
  // Send move command to Arduino
  long steps = round(target_position_mm * 80);  // 80 steps per mm (adjust to your calibration)
  long duration_ms = round(duration_sec * 1000);
  
  sendCommand("MOVE " + steps + " " + duration_ms);
  
  println("Moving to " + nf(target_position_mm, 0, 1) + "mm over " + nf(duration_sec, 0, 2) + "s");
  
  // Schedule next movement after duration
  thread("waitForMovementComplete");
}

void waitForMovementComplete() {
  float distance = abs(target_position_mm - gantry_position_mm);
  float duration_sec = distance / current_speed_mm_per_sec;
  
  delay(round(duration_sec * 1000) + 500);  // Add 500ms buffer
  
  if (is_moving) {
    current_pattern_index++;
    
    // Loop pattern
    if (current_pattern_index >= movement_pattern.size()) {
      current_pattern_index = 0;
    }
    
    moveToNextPatternPoint();
  }
}

void homeGantry() {
  println("Homing gantry to limit switch...");
  sendCommand("HOME");
}

void keyPressed() {
  if (key == 'd' || key == 'D') {
    show_debug = !show_debug;
    println("Debug mode: " + (show_debug ? "ON" : "OFF"));
  }
  else if (key == 's' || key == 'S') {
    if (is_moving) {
      stopMovement();
    } else {
      startMovementCycle();
    }
  }
  else if (key == 'r' || key == 'R') {
    homeGantry();
  }
  else if (key == ' ') {
    // Test: Move to center and back
    if (!is_moving) {
      println("Test: Move to center");
      is_moving = true;
      movement_pattern.clear();
      movement_pattern.add(0.5);
      current_pattern_index = 0;
      moveToNextPatternPoint();
    }
  }
  else if (key == '+' || key == '=') {
    current_speed_mm_per_sec = min(current_speed_mm_per_sec + 10, max_speed_mm_per_sec);
    println("Speed: " + current_speed_mm_per_sec + " mm/s");
  }
  else if (key == '-' || key == '_') {
    current_speed_mm_per_sec = max(current_speed_mm_per_sec - 10, 10);
    println("Speed: " + current_speed_mm_per_sec + " mm/s");
  }
  else if (key == 'p' || key == 'P') {
    show_position = !show_position;
    println("Position display: " + (show_position ? "ON" : "OFF"));
  }
  else if (key == 'q' || key == 'Q') {
    stopMovement();
    exit();
  }
}

void mousePressed() {
  // Optional: click to move to mouse position
  float click_position = map(mouseX, 0, display_width, 0, gantry_width_mm);
  target_position_mm = click_position;
  
  // Only allow manual movement if not in cycle
  if (!is_moving) {
    float distance = abs(target_position_mm - gantry_position_mm);
    float duration_sec = distance / current_speed_mm_per_sec;
    long steps = round(target_position_mm * 80);
    long duration_ms = round(duration_sec * 1000);
    
    sendCommand("MOVE " + steps + " " + duration_ms);
    println("Manual move to " + nf(click_position, 0, 1) + "mm");
  }
}
