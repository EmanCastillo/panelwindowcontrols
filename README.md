# Panel Window Controls
![Normal Form](screenshots/main.png)  
![Inactive Form](screenshots/inactive.png)  
[Watch demo](screenshots/demo.webm)  
Window control buttons for Plasma panels (6.0+), implemented in pure QML.

This widget provides minimize, maximize/restore, and close buttons for the active window, with smooth animations and configurable behavior. It is inspired by earlier implementations, but rebuilt from scratch for long-term stability and maintainability.

---

## Features

- Minimize, maximize/restore, and close buttons
- Follows KWin button order (`kwinrc`)
- Optional manual button order override
- Smooth slide-in/out animation
- Optional “only show when maximized” mode
- Inactive window dimming
- Live updates when KWin button layout changes
- Theme-agnostic (uses standard Plasma icon names)
- Fully configurable through Plasma widget settings

---

## Configuration Options

- **Show minimize / maximize / close buttons**
- **Show when no window is active**
- **Only show for maximized windows**
- **Follow KWin button order**
- **Manual button order (e.g. `IAX`)**
- **Enable animations**
- **Animation duration**
- **Dim inactive windows**
- **Enable hover effect**
- **Live-update KWin button order**

---

## Button Order Codes

Some configuration options use a short code to define button order.

Each letter represents a window action:
- `I` → Minimize
- `A` → Maximize / Restore
- `X` → Close

So `IAX` translates to `[ Minimize ] [ Maximize ] [ Close ]`. Feel free to alter this as you see fit.

This code, however, is ignored if "Follow KWin button order" is enabled.

---

## Requirements

- KDE Plasma 6.0+
- `kpackagetool6`

---

## Installation

### Option 1: Install from GitHub

```bash
git clone https://github.com/EmanCastillo/panelwindowcontrols.git
cd panelwindowcontrols
kpackagetool6 --type Plasma/Applet --install package
kquitapp6 plasmashell
plasmashell --replace &
```

### Option 2: Install from a package
Download your choice of package from releases. Then execute the following commands in your terminal:
```bash
kpackagetool6 --type Plasma/Applet --install path/to/package
kquitapp6 plasmashell
plasmashell --replace &
```

### Adding the widget

After installation:

```text
Right-click panel → Add Widgets → search "Panel Window Controls"
```

---

## Inspiration

This project is inspired by moodyhunter’s Window Buttons applet:

https://github.com/moodyhunter/applet-window-buttons6

That project provided the original idea of bringing window control buttons into Plasma panels and was my go-to until the changes in Plasma 6.6 caused it to break. As such, this is an independent reimplementation built using public Plasma APIs for compatibility with Plasma 6.
