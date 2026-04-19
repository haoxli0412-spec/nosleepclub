# nosleepclub

Keep your Mac awake with the lid closed — no dongle needed.

`nosleepclub` creates a virtual display so macOS thinks an external monitor is connected, then prevents sleep. Close the lid and your Mac stays awake in clamshell mode.

## Install

**From source (recommended):**

```bash
git clone https://github.com/haoxli0412-spec/nosleepclub.git
cd nosleepclub
make install
```

This builds the release binary and copies it to `/usr/local/bin`.

**Build only (without installing):**

```bash
git clone https://github.com/haoxli0412-spec/nosleepclub.git
cd nosleepclub
swift build -c release
# Binary is at .build/release/nosleepclub
```

## Usage

```bash
# Start — creates virtual display + prevents sleep
nosleepclub

# Custom resolution
nosleepclub -w 2560 -h 1440

# HiDPI (Retina) mode
nosleepclub --hidpi

# Stop — press Ctrl+C
```

Then close your MacBook lid. Your Mac will stay awake.

### Run in background

```bash
# Start in background
nosleepclub &

# Check if running
pgrep -f nosleepclub && echo "running" || echo "not running"

# Stop
pkill -f nosleepclub
```

### Verify it's working

```bash
# Check sleep assertions
pmset -g assertions | grep -E "PreventUserIdle|PreventSystem"

# Check virtual display
system_profiler SPDisplaysDataType | grep -A3 "nosleepclub"
```

You should see:
- `PreventUserIdleDisplaySleep = 1`
- `PreventUserIdleSystemSleep = 1`
- `PreventSystemSleep = 1`
- `nosleepclub Virtual Display: 1920 x 1080`

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- Swift 5.9+ (for building from source)
- **Power adapter must be connected** (macOS requires this for clamshell mode)

## How it works

```
┌─────────────────────────────────────────────────┐
│  nosleepclub                                    │
│                                                 │
│  1. CGVirtualDisplay API                        │
│     └─ Creates a virtual "external" display     │
│                                                 │
│  2. caffeinate -d -i -s                         │
│     ├─ -d: prevent display sleep                │
│     ├─ -i: prevent idle sleep                   │
│     └─ -s: prevent system sleep                 │
│                                                 │
│  Result: macOS sees an "external monitor"       │
│  → closing lid triggers clamshell mode          │
│  → system stays awake, network stays connected  │
└─────────────────────────────────────────────────┘
```

1. Uses the macOS CoreGraphics `CGVirtualDisplay` API to create a virtual display
2. macOS sees it as an external monitor connected to your Mac
3. Launches `caffeinate -d -i -s` to prevent display, idle, and system sleep
4. When you close the lid, macOS enters **clamshell mode** instead of sleeping
5. Your network stays connected, downloads continue, processes keep running
6. Press `Ctrl+C` to stop — the virtual display is removed and sleep behavior returns to normal

## Uninstall

```bash
cd nosleepclub
make uninstall
```

Or manually: `rm /usr/local/bin/nosleepclub`

## FAQ

**Q: Do I need an external monitor or HDMI dongle?**
No. That's the whole point — `nosleepclub` replaces the physical dongle with a software virtual display.

**Q: Will it work without the power adapter?**
No. macOS requires a power source for clamshell mode. This is a hardware-level restriction that no software can bypass.

**Q: Does the virtual display show up in System Settings?**
Yes, it appears as "nosleepclub Virtual Display" in Settings → Displays.

**Q: Is this safe?**
Yes. The virtual display is created in memory and removed when `nosleepclub` exits. No system files are modified, no kernel extensions are installed.

**Q: What macOS versions are supported?**
macOS 14 (Sonoma) and later. The `CGVirtualDisplay` API was introduced in macOS 14.

**Q: Does it work on Intel Macs?**
It should work on any Mac running macOS 14+, but has only been tested on Apple Silicon (M4 Pro).

## License

MIT
