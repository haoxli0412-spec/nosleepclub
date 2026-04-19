# nosleepclub

Keep your Mac awake with the lid closed — no dongle needed.

`nosleepclub` creates a virtual display so macOS thinks an external monitor is connected, then prevents sleep. Close the lid and your Mac stays awake in clamshell mode.

## Install

**From source:**

```bash
git clone https://github.com/user/nosleepclub.git
cd nosleepclub
make install
```

**Homebrew (coming soon):**

```bash
brew install nosleepclub
```

## Usage

```bash
# Start (creates virtual display + prevents sleep)
nosleepclub

# Custom resolution
nosleepclub -w 2560 -h 1440

# HiDPI mode
nosleepclub --hidpi

# Stop — press Ctrl+C
```

Then close your MacBook lid. It will stay awake.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- **Power adapter must be connected** (macOS requires this for clamshell mode)

## How it works

1. Creates a virtual display using macOS CoreGraphics APIs
2. macOS sees the virtual display as an "external monitor"
3. Runs `caffeinate -d -i -s` to prevent display, idle, and system sleep
4. When you close the lid, macOS enters clamshell mode instead of sleeping
5. Your network stays connected, processes keep running

## FAQ

**Q: Do I need an external monitor or HDMI dongle?**
No. That's the whole point — `nosleepclub` replaces the dongle with a software virtual display.

**Q: Will it work without the power adapter?**
No. macOS requires a power source for clamshell mode. This is a hardware-level restriction that no software can bypass.

**Q: Does the virtual display show up in System Settings?**
Yes, it appears as "nosleepclub Virtual Display" in Displays settings.

**Q: Is this safe?**
Yes. The virtual display is removed when `nosleepclub` exits. No system files are modified.

## License

MIT
