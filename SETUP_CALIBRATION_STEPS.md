# A Construct for Stillness - Setup & Calibration Steps

## Overview

This guide walks you through every step to get your installation running, from Arduino upload to first movement test.

---

## PHASE 1: Arduino Setup (Do this on a computer first)

### Step 1.1: Install Arduino IDE
1. Download from https://www.arduino.cc/en/software
2. Install on your computer (Windows/Mac/Linux)
3. Launch Arduino IDE

### Step 1.2: Connect Arduino to Computer
1. Use USB cable to connect Arduino to your computer
2. Wait for drivers to install (usually automatic)

### Step 1.3: Select Board Type
1. In Arduino IDE: **Tools → Board → Arduino Uno** (or your specific board)
2. **Tools → Port** - Select the COM port with "Arduino" in the name
   - Windows: Usually COM3, COM4, etc.
   - Mac/Linux: Usually /dev/ttyUSB0 or /dev/ttyACM0

### Step 1.4: Open & Upload Sketch
1. Open the file: `stillness_arduino.ino`
2. Click **Upload** button (right arrow icon)
3. Wait for "Done uploading" message

### Step 1.5: Verify Serial Connection
1. Open **Tools → Serial Monitor**
2. Set baud rate to **115200** (bottom right of monitor)
3. You should see: `Arduino Ready - A Construct for Stillness`
4. If nothing appears, try different COM ports or check USB cable

**✓ SUCCESS**: Arduino is ready and confirmed working

---

## PHASE 2: Stepper Motor Calibration

This determines how many steps your motor takes per millimeter of gantry movement.

### Step 2.1: Prepare the Gantry
1. Manually move the gantry to the **left limit** (where limit switch triggers)
2. Position a **measuring tape** or ruler along the gantry
3. Mark the current position (e.g., with tape) - call this 0mm

### Step 2.2: Send Test Movement Command
In Arduino Serial Monitor (from Phase 1.5):

1. Click in the input box at top of Serial Monitor
2. Type: `MOVE 8000 10000`
3. Press Enter

This sends the gantry 8000 steps over 10 seconds.

### Step 2.3: Measure Actual Distance
1. Wait for movement to complete (10 seconds)
2. Measure where the gantry stopped
3. Record the distance (e.g., 100mm)

### Step 2.4: Calculate STEPS_PER_MM

**Formula:**
```
STEPS_PER_MM = Steps Sent / Actual Distance
STEPS_PER_MM = 8000 / 100 = 80
```

**Examples:**
- Sent 8000 steps, moved 100mm → 80 steps/mm
- Sent 8000 steps, moved 125mm → 64 steps/mm
- Sent 8000 steps, moved 80mm → 100 steps/mm

### Step 2.5: Update Arduino Sketch
1. Open `stillness_arduino.ino` again
2. Find this line (near the top):
   ```cpp
   const int STEPS_PER_MM = 80;  // Calibrate based on your stepper/gearing
   ```
3. Change 80 to your calculated value
4. **Upload** the sketch again

### Step 2.6: Verify Calibration
1. Send another test: `MOVE 4000 5000` (should move ~50mm)
2. Measure and verify accuracy
3. If still off, repeat steps 2.2-2.5

**✓ SUCCESS**: Gantry moves correct distances

---

## PHASE 3: Limit Switch Testing

### Step 3.1: Position Gantry
1. Manually move gantry left until you hear/feel a **click** from the limit switch
2. The switch should be positioned so it triggers at your desired **home position**

### Step 3.2: Test Home Command
In Arduino Serial Monitor:

1. Type: `HOME`
2. Press Enter
3. Gantry should move left until it hits the limit switch
4. Serial Monitor should display: `HOME`

If it doesn't work:
- Check limit switch wiring (Pin 2 on Arduino)
- Verify limit switch has continuity with multimeter
- Check it's wired to GND and Pin 2

**✓ SUCCESS**: Limit switch detects and homes gantry

---

## PHASE 4: Raspberry Pi 5 Setup

### Step 4.1: Connect Arduino to RPi5
1. Disconnect Arduino from your computer
2. **Connect Arduino to RPi5 via USB cable**
3. RPi5 should auto-detect it

### Step 4.2: Identify Serial Port
On RPi5, open a terminal and run:

```bash
ls /dev/tty*
```

Look for:
- `/dev/ttyUSB0` (most common)
- `/dev/ttyACM0`

Write down which one you see.

### Step 4.3: Install Processing
```bash
# Update package list
sudo apt update

# Install Processing
sudo apt install -y processing

# Verify installation
processing --version
```

If that doesn't work, see full instructions at: https://processing.org/download

### Step 4.4: Fix Serial Permissions (Important!)
```bash
# Add yourself to the dialout group (for serial access)
sudo usermod -a -G dialout $USER

# Apply the change (either restart terminal or run):
newgrp dialout
```

### Step 4.5: Test Arduino Connection on RPi5
```bash
# List USB devices
lsusb

# You should see "Arduino" or "USB2.0-Serial" in the list

# Check serial port again
ls /dev/tty*
```

**✓ SUCCESS**: Arduino appears in device list and serial port exists

---

## PHASE 5: Processing Setup

### Step 5.1: Copy Processing Sketch to RPi5
```bash
# Copy the file to your home directory
cp stillness_display.pde ~/

# Or if you downloaded it differently:
# Just make sure stillness_display.pde is accessible
```

### Step 5.2: Test Processing Startup
```bash
# Run Processing (windowed for testing)
processing ~/stillness_display.pde &
```

You should see:
- Processing window opens
- Console output shows "=== A Construct for Stillness ==="
- "Connecting to: /dev/ttyUSB0" (or your port)
- "Arduino connected!"
- A white vertical bar appears on screen

If Arduino doesn't connect:
- Check the port in Step 4.2 matches what Processing found
- Verify Arduino Serial Monitor still works (Step 1.5)
- Check permissions (Step 4.4)

### Step 5.3: Test Display Connection to VS250
1. Connect VS250 projector to RPi5 HDMI
2. Power on VS250 and let it warm up 30 seconds
3. Set VS250 input to HDMI
4. Adjust focus and keystone on projector
5. You should see the white bar projected on the wall

**✓ SUCCESS**: Light bar visible on projection

---

## PHASE 6: Gantry Calibration in Processing

### Step 6.1: Measure Your Gantry Width
1. Measure the full left-to-right distance your gantry can travel
2. Record this in **millimeters** (e.g., 1000mm, 1200mm, etc.)

### Step 6.2: Update Processing Sketch
1. Open `stillness_display.pde` in a text editor
2. Find this line (near the top of setup()):
   ```java
   float gantry_width_mm = 1000;   // Your actual gantry width
   ```
3. Change 1000 to your measured value
4. Save the file

### Step 6.3: Test Home Position
In Processing, press **'r'** (for reset/home)

You should see:
- Gantry moves to left limit
- White bar stays centered on screen

### Step 6.4: Verify Bar Position Tracking
In Processing, press **'spacebar'** for test movement

You should see:
- Gantry moves to center
- **White bar remains in same spot on projection** (doesn't move with gantry)

This is the key feedback effect! The bar stays still while the projector moves.

**✓ SUCCESS**: Bar position tracking works correctly

---

## PHASE 7: Movement Pattern Setup

### Step 7.1: Edit Pattern for Back-and-Forth
Open `stillness_display.pde` and find this section in `setup()`:

```java
// Initialize movement pattern (% of gantry width)
movement_pattern = new ArrayList<Float>();
movement_pattern.add(0.5);   // Center
movement_pattern.add(0.8);   // Right
movement_pattern.add(0.2);   // Left
movement_pattern.add(0.5);   // Center
```

**Replace with:**

```java
// Initialize movement pattern (% of gantry width)
movement_pattern = new ArrayList<Float>();
movement_pattern.add(0.0);   // Far left
movement_pattern.add(1.0);   // Far right
```

This creates continuous back-and-forth motion.

### Step 7.2: Set Default Speed
Find this line (near the top of the file):

```java
float current_speed_mm_per_sec = 100;
```

Adjust based on your preference:
- **50** = Slow, contemplative
- **100** = Moderate (default)
- **150** = Fast, energetic

Save the file.

**✓ SUCCESS**: Movement pattern configured

---

## PHASE 8: Final Testing

### Step 8.1: Full Startup Sequence
1. Power on Arduino (if separate)
2. Power on VS250 projector, wait 30 seconds
3. Start Processing:
   ```bash
   processing ~/stillness_display.pde
   ```

### Step 8.2: Test Each Function
In Processing, press these keys in order:

1. **'d'** - Toggle debug mode
   - Should show: Gantry Position, FPS, Arduino connected: YES
   
2. **'r'** - Reset/home gantry
   - Gantry moves left, bar stays centered
   
3. **'spacebar'** - Test single movement
   - Gantry moves to center, bar remains stationary
   
4. **'s'** - Start continuous cycle
   - Gantry oscillates back and forth
   - White bar never moves on the projection
   - This repeats indefinitely
   
5. **'+'** - Increase speed (while moving)
   - Motion becomes faster
   
6. **'-'** - Decrease speed
   - Motion becomes slower

### Step 8.3: Verify Feedback Effect
**The key test:**

1. Watch the projected wall/screen
2. The white bar should appear **completely stationary**
3. Even though the projector (gantry) is moving
4. This demonstrates "stillness in motion" - the homeostatic effect

If the bar moves with the gantry:
- Check `STEPS_PER_MM` calibration (Phase 2)
- Verify `gantry_width_mm` is accurate (Phase 6)
- Check `pixels_per_mm` calculation in debug info

**✓ SUCCESS**: Installation is working!

---

## PHASE 9: Troubleshooting

### Arduino Issues

**"Arduino not found"**
```bash
# Check port
ls /dev/tty*

# Fix permissions
sudo usermod -a -G dialout $USER

# Restart
exit  # close terminal
# open new terminal
```

**"Connection refused"**
- Check baud rate in Arduino Serial Monitor (should be 115200)
- Try different USB port
- Restart Arduino: unplug 5 seconds, plug back in

### Processing Issues

**"Cannot open COM port"**
- Run with sudo: `sudo processing ~/stillness_display.pde`
- Or fix permissions (Phase 4.4)

**"Display shows nothing"**
- Check VS250 is powered on
- Check HDMI cable connection
- Check VS250 input is set to HDMI
- Verify RPi5 recognizes display: `tvservice -s`

**"Bar doesn't stay still"**
- Check "Pixels/mm" value in debug info (press 'd')
- Verify `gantry_width_mm` matches reality
- Test movement distances (spacebar test)

### Motor Issues

**"Gantry won't move"**
- Check TB6606 power supply
- Verify stepper motor connections
- Test with Arduino Serial Monitor: `MOVE 8000 5000`
- Check Arduino pins 8, 9, 10 connections

**"Movement is jerky"**
- Reduce `current_speed_mm_per_sec` value
- Check mechanical friction/binding
- Verify stepper power supply has enough current

---

## Typical Timing

| Phase | Time |
|-------|------|
| Arduino setup | 10-15 min |
| Motor calibration | 10 min |
| Limit switch test | 5 min |
| RPi5 setup | 15-20 min |
| Processing setup | 10 min |
| Gantry calibration | 10 min |
| Movement pattern | 5 min |
| Final testing | 10 min |
| **Total** | **~90 minutes** |

---

## Final Checklist

Before declaring success:

- [ ] Arduino uploads without errors
- [ ] Serial Monitor shows "Arduino Ready"
- [ ] `MOVE` command works with accurate distances
- [ ] `HOME` command triggers limit switch
- [ ] Arduino connects to RPi5 via USB
- [ ] Processing starts and finds Arduino
- [ ] Processing displays white bar on VS250
- [ ] Press 'r' - gantry homes successfully
- [ ] Press 'spacebar' - bar stays still while gantry moves
- [ ] Press 's' - continuous back-and-forth motion starts
- [ ] Press 'd' - debug info shows FPS ~60 and Arduino connected YES
- [ ] Speed adjustment works with +/- keys
- [ ] 'q' safely exits Processing

**✓ If all checked: Installation is complete and working!**

---

## Daily Operation

Once everything is set up:

```bash
# 1. Power on Arduino (if separate)
# 2. Power on VS250, wait 30 seconds
# 3. Run Processing:
processing ~/stillness_display.pde &

# 4. In Processing window, press 's' to start
# 5. Installation runs indefinitely
# 6. Press 'q' to quit safely
```

---

## Next Steps

Once the installation is working, you can:

- **Customize patterns** (different movement sequences)
- **Adjust bar width** for different visual effects
- **Optimize smoothing** for your specific hardware
- **Fine-tune speed** for artistic effect
- **Add artistic variations** (color, patterns, etc.)

Enjoy your construction of stillness!
