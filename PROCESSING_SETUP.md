# A Construct for Stillness - Processing Direct Control Setup

## Architecture Overview

This simplified system has three components:

1. **Arduino** - Controls stepper motor via TB6606 driver and reads limit switch
2. **Processing** - Runs on RPi5, communicates directly with Arduino via serial, displays the light bar
3. **Projector** - Connected to RPi5 display output, shows the Processing visualization fullscreen

No Python middleman required - Processing handles everything.

## Hardware Setup

### Arduino to TB6606 Driver
```
Arduino Pin 9  -> TB6606 STEP (or PUL)
Arduino Pin 8  -> TB6606 DIR (or DIR)
Arduino Pin 10 -> TB6606 ENABLE (or ENA)
GND            -> TB6606 GND
```

### Arduino to Limit Switch
```
Arduino Pin 2  -> Limit Switch (normally open)
GND            -> Limit Switch
```

### Arduino to Raspberry Pi
```
Arduino USB    -> RPi5 USB port
(Direct USB connection, no wiring needed)
```

## Installation on Raspberry Pi 5

### Step 1: Install Processing
```bash
# Download Processing for ARM (RPi5 runs standard Processing now)
cd ~/Downloads
wget https://github.com/processing/processing/releases/download/processing-1302-4.3.2/processing-4.3.2-linux-armv6hf.tgz

# Extract
tar xzf processing-4.3.2-linux-armv6hf.tgz
sudo mv processing-4.3.2 /opt/processing

# Create symlink
sudo ln -s /opt/processing/processing /usr/local/bin/processing
```

Alternatively, use the official instructions at: https://processing.org/download

### Step 2: Install Serial Library (if needed)
Processing should have serial support built-in. If you get import errors:
- Open Processing IDE
- Sketch → Import Library → Add Library
- Search for "Serial" and ensure it's installed

### Step 3: Upload Arduino Sketch
1. Install Arduino IDE on your computer (not RPi)
2. Connect Arduino via USB
3. Open `stillness_arduino.ino` in Arduino IDE
4. Select board type: Arduino Uno (or your specific board)
5. Select the correct COM port
6. Click Upload

Verify in the Arduino Serial Monitor (9600 baud) that it says "Arduino Ready"

### Step 4: Run Processing on RPi5
```bash
# Copy the Processing sketch to your home directory
cp stillness_display.pde ~/

# Run fullscreen (recommended for projection)
processing --display=:0 --full-screen ~/stillness_display.pde

# Or run windowed for development
processing ~/stillness_display.pde
```

## Calibration

### 1. Find Your Arduino Port
When Processing starts, look at the console output:
```
Available serial ports:
  - /dev/ttyUSB0
  - /dev/ttyACM0
```

If it doesn't find it, check:
```bash
ls /dev/tty*
```

The Arduino sketch will auto-connect to the last port. If that's wrong, modify this line in the Processing sketch:
```java
String port = Serial.list()[Serial.list().length - 1];  // Change index as needed
```

### 2. Calibrate STEPS_PER_MM
The Processing sketch sends commands assuming 80 steps per mm. To verify/adjust:

1. Press 'd' in Processing to show debug info
2. Press 'r' to home the gantry
3. Press spacebar to test a movement to center
4. Measure the actual distance moved vs displayed distance
5. If it moved 100mm and shows 125mm, your actual is 80 * (100/125) = 64 steps/mm

Update this line in `moveToNextPatternPoint()`:
```java
long steps = round(target_position_mm * 64);  // Change 64 to your value
```

### 3. Adjust Gantry Width
Update this line in the `draw()` function or near the top:
```java
float gantry_width_mm = 1000;  // Change to your actual gantry width
```

### 4. Fine-tune Bar Width and Position
```java
float bar_width = 120;  // Width of the light bar in pixels
float smoothing = 0.1;  // 0.0 = jerky, 1.0 = very smooth. Start at 0.1
```

## Controls

When Processing is running, use these keyboard shortcuts:

| Key | Action |
|-----|--------|
| `d` | Toggle debug display |
| `s` | Start/Stop movement cycle |
| `r` | Home gantry to limit switch |
| `space` | Test single movement to center |
| `+` / `-` | Increase/Decrease speed |
| `p` | Toggle position display at bottom |
| `q` | Quit Processing |
| Mouse click | Move to clicked position (when not in cycle) |

## Movement Patterns

Edit the pattern in the `setup()` function:
```java
movement_pattern = new ArrayList<Float>();
movement_pattern.add(0.5);   // Center (50% of gantry width)
movement_pattern.add(0.8);   // Right (80%)
movement_pattern.add(0.2);   // Left (20%)
movement_pattern.add(0.5);   // Back to center
```

Values are 0.0 to 1.0 representing percentage of gantry width.

## Troubleshooting

### Arduino Not Found
```bash
# List available ports
ls /dev/tty*

# Check USB permissions (might need sudo for some boards)
groups $USER

# May need to add user to dialout group
sudo usermod -a -G dialout $USER
```

### "Error connecting to Arduino"
- Check USB cable connection
- Try a different USB port on RPi
- Restart Arduino: briefly disconnect USB and reconnect
- Check baud rate matches (115200)

### Light bar not staying still
- Check `STEPS_PER_MM` calibration
- Verify `gantry_width_mm` is accurate
- Make sure `smoothing` value isn't too high (start with 0.1)
- Check `pixels_per_mm` calculation: `display_width / gantry_width_mm`

### Serial Communication Errors
- Verify Ground wire is connected between Arduino and stepper driver
- Check USB cable quality
- Try: `dmesg | tail -20` to see if kernel recognizes the device

### Gantry Won't Move
- Check stepper motor connections to TB6606
- Verify Pin 8 and Pin 9 are correct in Arduino sketch
- Check power supply for stepper driver
- Test manually with multimeter for continuity

### Movement Too Fast/Slow
- Adjust `current_speed_mm_per_sec` in Processing
- Or use +/- keys while running to adjust on the fly
- Max speed limited to `max_speed_mm_per_sec = 150`

## Projector Output Setup

Processing automatically displays fullscreen on the primary display. To configure projector:

### Option A: HDMI Mirroring
The projector should mirror the RPi5 HDMI output. Enable in Settings.

### Option B: Extended Display
If using extended display, make sure Processing fullscreen runs on the projector monitor.

### Option C: VNC Remote
If running headless, use VNC:
```bash
sudo apt install tigervnc-standalone-server
vncserver :1 -geometry 1920x1080 -depth 24
```

Then connect from a remote machine and start Processing.

## Performance Notes

- Processing runs at 60 FPS by default
- Arduino sends position feedback every 100ms
- Smoothing is applied to avoid jitter between updates
- For smooth projection, ensure:
  - Good USB cable (minimize latency)
  - No other heavy processes running on RPi5
  - Adequate cooling (Processing + display can generate heat)

## Safety Considerations

1. **Homing**: Always home (press 'r') at startup
2. **Limits**: Gantry stops at limit switch and software boundaries
3. **Emergency**: Press 'q' to exit safely (stops movement first)
4. **Manual override**: You can click anywhere to move manually if cycle gets stuck

## Testing Workflow

1. **Arduino test**: Upload sketch, open Serial Monitor (115200), send "STATUS\n"
2. **Limit switch test**: Send "HOME\n" - should see "HOME" response
3. **Movement test**: Send "MOVE 8000 10000\n" for 10 second movement
4. **Processing startup**: Press 'r' to home, then 'd' for debug info
5. **Full cycle**: Press 's' to start automatic movement
6. **Fine-tuning**: Adjust speeds and patterns with keyboard controls

## Performance Optimization

If synchronization seems off:
- Reduce `smoothing` value (0.05 for tighter tracking)
- Increase Arduino `FEEDBACK_INTERVAL` (currently 100ms)
- Check USB latency: `lsusb -v | grep -i bInterval`
- Consider USB3 hub if using external devices

## Next Steps

1. Upload Arduino sketch and verify in Serial Monitor
2. Connect Arduino to RPi5 via USB
3. Run Processing fullscreen: `processing --full-screen stillness_display.pde`
4. Press 'r' to home, then 'd' to see debug info
5. Press 's' to start movement cycle
6. Adjust calibration values as needed
7. Customize movement patterns for your artistic vision
