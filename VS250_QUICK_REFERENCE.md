# A Construct for Stillness - VS250 Quick Reference

## One-Line Setup

```bash
# On RPi5:
# 1. Upload Arduino sketch (on computer first)
# 2. Connect Arduino to RPi5 USB
# 3. Connect VS250 HDMI to RPi5 HDMI
# 4. Power on VS250, let it warm up 30 seconds
# 5. Run: processing --display=:0 stillness_display.pde
```

## VS250 Specs at a Glance

| Spec | Value |
|------|-------|
| Resolution | 1024 x 768 (XGA) |
| Brightness | 3000 ANSI lumens |
| Contrast | 15,000:1 |
| Throw ratio | 0.48:1 |
| Connections | HDMI, VGA, Composite |
| Warm-up time | 30 seconds |

## Processing Keyboard Controls

```
d     Toggle debug display
s     Start/Stop movement cycle
r     Home gantry (reset to limit switch)
space Test single movement
+/-   Speed up / Slow down
p     Toggle position display
q     Quit (safe shutdown)
```

## Serial/USB Troubleshooting

**Arduino not found?**
```bash
# List USB devices
ls /dev/tty*

# Check permissions
sudo chmod 666 /dev/ttyUSB0  # or /dev/ttyACM0
```

**HDMI not detected?**
```bash
# Check display
tvservice -s

# Force resolution
tvservice -e "DMT 4"  # 1024x768

# Power cycle
tvservice -p 0
tvservice -p 1
```

## Calibration Checklist

- [ ] **STEPS_PER_MM**: Verify with test movement
  ```
  Press spacebar → measure distance → adjust multiplier in sketch
  ```

- [ ] **Gantry Width**: Ensure actual width matches code
  ```
  float gantry_width_mm = 1000;  // Change to your value
  ```

- [ ] **Bar Width**: Adjust for visibility
  ```
  float bar_width = 80;  // Pixels (50-100 typical for 1024px width)
  ```

- [ ] **Smoothing**: For fluid motion
  ```
  float smoothing = 0.1;  // Lower = jerky, Higher = lag
  ```

## Common Issues & Fixes

### Light bar jumps around
- **Cause**: Smoothing too high
- **Fix**: Reduce `smoothing` value (try 0.05)

### Light bar doesn't stay still
- **Cause**: STEPS_PER_MM is wrong
- **Fix**: Test movement, measure actual distance, recalibrate

### Projector shows no image
- **Cause**: Resolution mismatch
- **Fix**: Check VS250 input source, verify HDMI cable
- **Fix**: Force resolution: `tvservice -e "DMT 4"`

### Arduino won't connect
- **Cause**: Serial port permissions
- **Fix**: `sudo usermod -a -G dialout $USER`
- **Fix**: Restart terminal or system

### Movement is too slow/fast
- **Cause**: Speed setting
- **Fix**: Press +/- keys in Processing to adjust
- **Fix**: Default 100 mm/s, max 150 mm/s

### Gantry won't move
- **Cause**: Stepper not connected or Arduino command failed
- **Fix**: Check TB6606 wiring, verify Arduino pin connections
- **Fix**: Test in Arduino Serial Monitor: send "MOVE 8000 5000"

## Performance Tips

- **For smoother motion**: Reduce smoothing value, increase Arduino feedback interval
- **For snappier response**: Increase smoothing value, decrease feedback interval
- **For power efficiency**: Use Eco mode on VS250 (still 2000 lumens)
- **For brightest image**: Use Bright mode on VS250 (3000 lumens)

## Movement Pattern Examples

Edit in Processing `setup()` function:

```java
// Slow oscillation
movement_pattern.add(0.5);   // center
movement_pattern.add(0.7);   // right
movement_pattern.add(0.3);   // left
movement_pattern.add(0.5);   // center

// Wide sweeps
movement_pattern.add(0.1);   // far left
movement_pattern.add(0.9);   // far right
movement_pattern.add(0.1);   // back to left

// Smooth breathing
movement_pattern.add(0.5);   // center
movement_pattern.add(0.6);   // slight right
movement_pattern.add(0.4);   // slight left
movement_pattern.add(0.5);   // center
```

## Resolution Reference

If using different VS250 configurations:

| Mode | Pixels | Recommended |
|------|--------|-------------|
| Native XGA | 1024×768 | ✓ Best |
| SXGA | 1280×1024 | Scaled |
| WXGA | 1280×720 | Wider |
| VGA | 640×480 | Smaller |

Change in Processing:
```java
size(1024, 768, P2D);  // Change first two numbers
```

## Field of View Calculations

For gantry positioning over projected image:

```
Screen width = Throw distance × 2.08
Pixels per mm = 1024 / (Screen width in mm)

Example: 3m distance
Screen width = 3000mm × 2.08 = 6240mm
Pixels/mm = 1024 / 6240 = 0.164

If gantry is 1000mm wide covering 20% of screen:
Apparent pixels = 1000mm × 0.164 = 164px
```

The Processing sketch calculates this automatically based on:
```java
pixels_per_mm = display_width / gantry_width_mm;
```

## Remote Control (Optional)

VS250 supports PJLink protocol for network control:

```bash
# Check projector IP (on projector: MENU → Network)
# Example: 192.168.1.100

# Send command
echo "STATUS" | nc 192.168.1.100 4352
```

This is optional but useful for monitoring brightness, fan status, etc.

## Power Management

- **Normal startup**: Turn on → wait 30s → start Processing
- **Shutdown**: Exit Processing → projector auto-cools (30s)
- **Do not**: Unplug during cool-down (damages lamp)
- **Eco mode**: Lower power, quieter, suitable for dark environments

## Debug Output Interpretation

Press 'd' in Processing to see:

```
Gantry Position:     250.5 mm
Target Position:     500.0 mm
Bar X:               256 px
Pixels/mm:           1.024
Speed:               100.0 mm/s
FPS:                 60.0
Last serial update:  45 ms
Arduino connected:   YES
Moving:              YES
```

**If Last serial update > 200ms**: USB latency issue, check cable

## Emergency Procedures

**If gantry runs away**: Press 'q' → exit Processing → gantry stops

**If projector overheats**: Reduce brightness in Eco mode, ensure ventilation

**If light bar appears frozen**: Check "Last serial update" in debug (should be <200ms)

## Maintenance

- **Clean lens**: Use soft, dry cloth monthly
- **Check filters**: Epson VS250 has replaceable air filters (check manual)
- **Lamp life**: ~2000-4000 hours depending on mode
- **Projector placement**: Ensure good ventilation (min 10cm clearance)

## Success Indicators

✓ Arduino auto-connects on startup
✓ White vertical bar visible and centered
✓ Press 'r' - gantry homes smoothly
✓ Press 'spacebar' - bar stays in place while gantry moves
✓ Press 's' - continuous cycle starts and loops
✓ FPS steady at 60 in debug info
✓ Last serial update < 100ms

If all green, you're ready for the full installation!
