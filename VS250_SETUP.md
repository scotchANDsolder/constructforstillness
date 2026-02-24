# A Construct for Stillness - Epson VS250 Configuration

## Epson VS250 Specifications

**Native Resolution**: 1024 x 768 (XGA)
**Brightness**: 3000 ANSI lumens
**Contrast Ratio**: 15,000:1
**Keystone Correction**: ±30 degrees (vertical)
**Lens**: Fixed, 0.48:1 throw ratio
**Connections**: VGA, HDMI, Composite Video
**Recommended Distance**: 1.5m - 7.6m for 40"-300" screen

## Display Output Setup on RPi5

The VS250 accepts HDMI input and will auto-detect the resolution. Processing needs to output at a resolution the projector can handle.

### Recommended Processing Resolution for VS250

The Epson VS250 natively supports:
- 1024 x 768 (native XGA)
- 1280 x 1024
- 1600 x 1200
- And various other resolutions via scaling

For best results with this installation, use **1024 x 768** (native) or **1280 x 720** (wider aspect ratio).

### Option 1: Native Resolution (1024 x 768)

Modify the Processing sketch settings:

```java
void settings() {
  // Native VS250 resolution
  size(1024, 768, P2D);
  // Or for fullscreen:
  // fullScreen(P2D);
}
```

### Option 2: Wider Aspect Ratio (1280 x 720)

```java
void settings() {
  size(1280, 720, P2D);
  // fullScreen(P2D);
}
```

### Option 3: Full Screen Auto-Detect

Keep the sketch as-is with `fullScreen(P2D)` and configure the RPi5 display:

```bash
# Check current display settings
tvservice -s

# List supported resolutions
tvservice -m CEA
tvservice -m DMT

# Set specific resolution (example 1024x768)
tvservice -e "CEA 1"
# or
tvservice -e "DMT 1"
```

## Connecting VS250 to RPi5

### HDMI Connection
1. Connect RPi5 HDMI output to VS250 HDMI input
2. Power on projector
3. The projector should auto-detect the signal

### If Not Detected
1. On RPi5, open Settings → Display
2. Check "HDMI 0" is detected
3. Select resolution (1024x768 recommended)
4. Apply and confirm

### Via VGA (if HDMI unavailable)
Use a USB-C to VGA adapter on RPi5, or HDMI to VGA converter.

## Projector Configuration on VS250

### On the Projector

1. **Power On**: Let it warm up for 30 seconds
2. **Input Source**: 
   - Press INPUT button on remote or projector
   - Select "HDMI 1" or "HDMI 2" (whichever is connected)
3. **Keystone Correction** (if needed):
   - Press MENU → Keystone
   - Adjust vertical angle to square up image
4. **Focus**: 
   - Use Focus ring on lens to sharpen the image
   - Or use remote: MENU → Focus (if available)
5. **Zoom**: 
   - Move projector closer/farther to adjust image size
   - VS250 has fixed lens, no digital zoom

### Optimal Throw Distance for Light Bar Installation

For a vertical light bar to be visible:
- **Typical distance**: 2-3 meters
- **Image width at 2.5m**: ~90cm
- **At 3m**: ~110cm
- **At 4m**: ~150cm

### Brightness Settings

For a visible white light bar in a dark environment:
- **Normal mode**: Suitable (3000 lumens)
- **Bright mode**: Maximum brightness
- **Eco mode**: Reduced brightness (quieter fan, saves power)

For this installation, Normal mode is recommended.

## Processing Configuration for VS250

Update these values in the Processing sketch based on your VS250 setup:

```java
void settings() {
  // Adjust based on actual projector resolution
  // For VS250 native:
  size(1024, 768, P2D);
  
  // Or for fullscreen (auto-detects):
  // fullScreen(P2D);
}

void setup() {
  display_width = width;    // Will be 1024
  display_height = height;  // Will be 768
  
  // Gantry parameters - ADJUST TO YOUR SETUP
  gantry_width_mm = 1000;   // Your actual gantry width
  
  // Light bar width - adjust for visibility
  bar_width = 100;          // Pixels (adjust 50-150 based on preference)
  
  // Smoothing for fluid motion
  smoothing = 0.1;          // 0.05 = tighter, 0.15 = smoother
}
```

## Performance Optimization for VS250

The VS250 refreshes at 60Hz, matching Processing's default frame rate.

### For Smooth Operation:
```java
// Add to setup() if needed:
frameRate(60);  // Match projector refresh rate
```

### If you experience flickering:
1. Check HDMI cable quality (use shielded, certified HDMI 2.0 cable)
2. Reduce Processing complexity (currently just drawing a bar, so this shouldn't be needed)
3. Enable adaptive sync on RPi5 if available

## Calibration Notes for VS250

### Pixel-to-Millimeter Mapping
The mapping depends on your projector distance and throw ratio.

**VS250 Specifications**:
- Throw ratio: 0.48:1
- This means: Screen width = Throw distance × 2.08

**Example Calculation**:
- Throw distance: 2.5 meters
- Screen width: 2.5m × 2.08 = 5.2m (520cm)
- Pixels per mm: 1024px / 5200mm = 0.197 px/mm

If your gantry is 1000mm wide and positioned to cover the full projection width, then:
- `pixels_per_mm = 1024 / 1000 = 1.024`

**This should be automatically calculated** in the Processing sketch:
```java
pixels_per_mm = display_width / gantry_width_mm;
```

### Centering the Light Bar

The bar is centered at:
```java
gantry_center_offset = display_width / 2.0;  // 512 pixels for 1024 width
```

Make sure your gantry 0mm position aligns with the center of the projected image.

## Connecting via Network (Optional)

If you want to control the VS250 settings remotely or use Crestron integration:

```bash
# VS250 supports basic network control
# IP address appears in: MENU → Setup → Network
# Standard protocols: PJLink (port 4352)

# Example: Check projector status
echo "STATUS" | nc <projector_ip> 4352
```

This is optional for your installation but useful for remote monitoring.

## Troubleshooting VS250 Issues

### No signal from RPi5
- Check HDMI cable (try another cable)
- Restart projector
- On RPi5: `tvservice -p` (power on display)
- Check RPi5 video output: `grep -i hdmi /var/log/Xorg.0.log`

### Image is blurry
- Adjust focus ring on VS250 lens
- Check throw distance is correct
- Ensure projector is perpendicular to wall (check keystone)

### Image is dim
- Check if Eco mode is enabled (use Normal/Bright)
- Clean lens with soft cloth
- Increase ambient light check (though dark is better for visible light bar)

### Colors look wrong
- Check HDMI input color settings (usually auto)
- In Processing, ensure background(0) is pure black
- Color bar is white: fill(255)

### Resolution doesn't match
- VS250 may scale the input automatically
- Force resolution on RPi5:
  ```bash
  tvservice -e "DMT 4"  # For 1024x768
  ```
- Restart Processing after changing resolution

## Ideal Viewing Environment

For optimal visibility of the light bar:

- **Ambient lighting**: Dark room is ideal (light bar is white on black)
- **Viewing angle**: Straight-on is best (minimal keystone correction needed)
- **Projection surface**: White wall or screen
- **Distance**: 2-4 meters for comfortable viewing

## Final Setup Checklist

- [ ] VS250 powered on and warmed up
- [ ] HDMI cable connected from RPi5 to VS250
- [ ] Projector set to HDMI input
- [ ] Focus adjusted on projector lens
- [ ] Keystone correction applied if needed
- [ ] Processing resolution matches VS250 native or compatible mode
- [ ] Arduino sketch uploaded and connected to RPi5 via USB
- [ ] Gantry limit switch tested
- [ ] Movement pattern configured
- [ ] Light bar position and width adjusted for visibility

## Testing Workflow

1. **Display test**: Start Processing without movement - should show white vertical bar centered on screen
2. **Position test**: Press 'r' in Processing to home gantry - bar should remain stationary
3. **Movement test**: Press spacebar - gantry moves, bar stays in place visually
4. **Full cycle**: Press 's' - automatic movement cycle begins
5. **Debug**: Press 'd' - shows live position and frame rate

## VS250 Power Specifications

- **Power consumption**: 300W (Normal mode), 205W (Eco mode)
- **Warm-up time**: ~30 seconds
- **Cool-down time**: ~30 seconds (fan runs after power off)
- **Recommended for**: Always turn off properly (don't unplug while cooling)

## Notes on VS250 Limitations

- **Fixed lens**: No digital zoom (move projector to adjust size)
- **Lower brightness than newer models**: 3000 lumens is moderate (fine for dark spaces)
- **Resolution capped at 1024x768 native**: Processing will scale larger sizes down
- **Older connectivity**: HDMI via RPi5 is the modern approach

The VS250 is a solid projector for this installation. The key to visual quality is proper focus, distance, and a dark viewing environment.
