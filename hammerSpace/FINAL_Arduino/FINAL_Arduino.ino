/*
 * A Construct for Stillness - Arduino Stepper Control
 * SMOOTH CONTINUOUS SWEEPING
 */

const int STEP_PIN = 5;
const int DIR_PIN = 9;
const int LIMIT_PIN = 3;
const int ENABLE_PIN = 11;

// --- HARDWARE DIRECTION CONFIGURATION ---
const int MOVE_RIGHT = HIGH; 
const int MOVE_LEFT = LOW;   

const long MAX_STEPS = 360000;
const int MAX_SPEED = 6000;
const int HOME_SPEED = 6000; 
const int ACCEL_STEP = 20;

volatile boolean limit_hit = false;
long position = 0;
long steps_left = 0;
int direction = 1;

boolean moving = false;
boolean is_homing = false;

int speed_now = 0;
int speed_target = 0;
unsigned long last_feedback = 0;

void setup() {
  Serial.begin(115200);
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(ENABLE_PIN, OUTPUT);
  pinMode(LIMIT_PIN, INPUT_PULLUP);

  digitalWrite(ENABLE_PIN, LOW);
  digitalWrite(STEP_PIN, LOW);
  digitalWrite(DIR_PIN, LOW);
  
  attachInterrupt(digitalPinToInterrupt(LIMIT_PIN), limit_isr, FALLING);
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    
    if (cmd == "HOME") {
      start_homing();
    } 
    else if (cmd.startsWith("MOVE ")) {
      int space_idx = cmd.indexOf(' ', 5);
      if (space_idx > 0) {
        long target = cmd.substring(5, space_idx).toInt();
        long duration = cmd.substring(space_idx + 1).toInt();
        move_to(target, duration);
      }
    }
    else if (cmd == "STOP") {
      stop_all();
    }
  }

  if (is_homing) {
    if (limit_hit || digitalRead(LIMIT_PIN) == LOW) {
      position = 0;
      is_homing = false;
      moving = false;
      speed_now = 0;
      Serial.println("HOME");
    } else {
      if (speed_now < HOME_SPEED) speed_now = min(speed_now + ACCEL_STEP, HOME_SPEED);
      do_step(speed_now);
    }
  }
  else if (moving) {
    if (direction == -1 && digitalRead(LIMIT_PIN) == LOW) {
      moving = false;
      position = 0; 
      speed_now = 0;
      steps_left = 0;
      Serial.println("DONE"); 
    }
    else if (steps_left > 0) {
      if (speed_now < speed_target) speed_now = min(speed_now + ACCEL_STEP, speed_target);
      do_step(speed_now);
      position += direction;
      steps_left--;
    } else {
      moving = false;
      speed_now = 0;
      Serial.println("DONE");
    }
  }

  // UPDATED: Now sends position data every 30ms for buttery smooth visual tracking
  if (millis() - last_feedback > 30) {
    Serial.print("POS:");
    Serial.println(position);
    last_feedback = millis();
  }
}

void start_homing() {
  stop_all();
  digitalWrite(DIR_PIN, MOVE_RIGHT); 
  direction = -1;
  limit_hit = (digitalRead(LIMIT_PIN) == LOW); 
  speed_now = 100;
  is_homing = true;
  delayMicroseconds(50);
}

void move_to(long target, long duration_ms) {
  is_homing = false;
  limit_hit = false;
  
  long distance = target - position;
  if (distance == 0) {
    Serial.println("DONE");
    return;
  }

  if (distance > 0) {
    digitalWrite(DIR_PIN, MOVE_LEFT);  
    direction = 1;
  } else {
    digitalWrite(DIR_PIN, MOVE_RIGHT);   
    direction = -1;
    distance = -distance;
  }
  
  delayMicroseconds(50); 
  steps_left = distance;
  
  if (duration_ms > 0) {
    speed_target = (distance * 1000L) / duration_ms;
    speed_target = constrain(speed_target, 100, MAX_SPEED);
  } else {
    speed_target = MAX_SPEED;
  }

  speed_now = 100; 
  moving = true;
}

void do_step(int current_speed) {
  digitalWrite(STEP_PIN, HIGH);
  delayMicroseconds(5);
  digitalWrite(STEP_PIN, LOW);
  unsigned long delay_us = 1000000UL / max(current_speed, 100);
  delayMicroseconds(delay_us);
}

void stop_all() {
  moving = false;
  is_homing = false;
  steps_left = 0;
  speed_now = 0;
}

void limit_isr() {
  if (digitalRead(LIMIT_PIN) == LOW) {
    limit_hit = true;
  }
}
