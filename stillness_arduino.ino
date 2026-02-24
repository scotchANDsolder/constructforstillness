/*
 * A Construct for Stillness - Arduino Stepper Control
 * Controls TB6606 stepper driver and reads limit switch for position feedback
 */

// Pin definitions
const int STEP_PIN = 9;      // PWM pin for stepper pulses
const int DIR_PIN = 8;       // Direction control
const int LIMIT_SWITCH_PIN = 2;  // Interrupt pin for limit switch
const int ENABLE_PIN = 10;   // Driver enable (optional)

// Motion parameters
const int STEPS_PER_MM = 80;  // Calibrate based on your stepper/gearing
const int ACCELERATION_STEPS = 500;  // Ramp up over this many steps
const int MAX_SPEED = 5000;   // Maximum frequency in Hz

// State variables
volatile boolean limit_triggered = false;
volatile long current_step_position = 0;
long target_step_position = 0;
boolean is_homing = false;
unsigned long last_feedback_time = 0;
const unsigned long FEEDBACK_INTERVAL = 100;  // Send position every 100ms

// Movement state
boolean moving = false;
long steps_remaining = 0;
int current_speed = 0;
int target_speed = 0;

void setup() {
  Serial.begin(115200);
  
  // Configure pins
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(ENABLE_PIN, OUTPUT);
  pinMode(LIMIT_SWITCH_PIN, INPUT_PULLUP);
  
  // Enable the stepper driver
  digitalWrite(ENABLE_PIN, LOW);
  
  // Attach interrupt for limit switch
  attachInterrupt(digitalPinToInterrupt(LIMIT_SWITCH_PIN), 
                  limit_switch_interrupt, FALLING);
  
  Serial.println("Arduino Ready - A Construct for Stillness");
  delay(500);
}

void loop() {
  // Handle serial commands
  if (Serial.available()) {
    parse_command();
  }
  
  // Perform step if moving
  if (moving && steps_remaining > 0) {
    perform_step();
  } else if (moving && steps_remaining <= 0) {
    moving = false;
    Serial.println("DONE");
  }
  
  // Send position feedback periodically
  if (millis() - last_feedback_time > FEEDBACK_INTERVAL) {
    send_position_feedback();
    last_feedback_time = millis();
  }
}

void parse_command() {
  String command = Serial.readStringUntil('\n');
  command.trim();
  
  if (command.startsWith("MOVE")) {
    // Format: MOVE <target_steps> <duration_ms>
    int space1 = command.indexOf(' ');
    int space2 = command.indexOf(' ', space1 + 1);
    
    if (space1 > 0 && space2 > space1) {
      long target_steps = command.substring(space1 + 1, space2).toInt();
      long duration_ms = command.substring(space2 + 1).toInt();
      
      move_to_position(target_steps, duration_ms);
    }
  } 
  else if (command == "HOME") {
    // Return to limit switch
    home_gantry();
  }
  else if (command == "STOP") {
    stop_movement();
  }
  else if (command == "STATUS") {
    send_status();
  }
}

void move_to_position(long target_steps, long duration_ms) {
  long distance = target_steps - current_step_position;
  
  // Determine direction
  if (distance > 0) {
    digitalWrite(DIR_PIN, HIGH);  // Forward
  } else {
    digitalWrite(DIR_PIN, LOW);   // Backward
    distance = -distance;
  }
  
  steps_remaining = distance;
  target_step_position = target_steps;
  
  // Calculate speed profile for smooth acceleration
  // This is a simple linear ramp - you can improve with S-curve profiling
  if (duration_ms > 0) {
    target_speed = (distance * 1000) / duration_ms;  // steps per second
    target_speed = constrain(target_speed, 100, MAX_SPEED);
  }
  
  moving = true;
  current_speed = 0;
}

void perform_step() {
  // Simple acceleration/deceleration
  if (current_speed < target_speed) {
    current_speed = min(current_speed + 50, target_speed);
  } else if (current_speed > target_speed) {
    current_speed = max(current_speed - 50, target_speed);
  }
  
  // Generate step pulse
  digitalWrite(STEP_PIN, HIGH);
  delayMicroseconds(5);
  digitalWrite(STEP_PIN, LOW);
  
  current_step_position++;
  steps_remaining--;
  
  // Wait for next step based on current speed
  unsigned long step_delay = 1000000 / max(current_speed, 100);  // microseconds
  delayMicroseconds(step_delay);
}

void home_gantry() {
  // Move backward until limit switch triggers
  digitalWrite(DIR_PIN, LOW);  // Backward direction
  is_homing = true;
  limit_triggered = false;
  moving = true;
  target_speed = 2000;  // Slow speed for homing
  
  while (!limit_triggered && is_homing) {
    perform_step();
    
    // Safety timeout
    delay(0);
  }
  
  is_homing = false;
  moving = false;
  current_step_position = 0;
  Serial.println("HOME");
}

void stop_movement() {
  moving = false;
  steps_remaining = 0;
  current_speed = 0;
}

void limit_switch_interrupt() {
  if (is_homing) {
    limit_triggered = true;
  }
  // Optional: add debounce or immediate stop behavior
}

void send_position_feedback() {
  // Calculate position in mm
  float position_mm = (float)current_step_position / STEPS_PER_MM;
  Serial.print("POS:");
  Serial.println(position_mm, 2);
}

void send_status() {
  Serial.print("STATUS:");
  Serial.print(current_step_position);
  Serial.print(",");
  Serial.print(moving ? "MOVING" : "IDLE");
  Serial.print(",");
  Serial.println(current_speed);
}
