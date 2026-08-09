# Platform proof screenshots

Evidence that one codebase runs correctly on each target. Every image is the
same build of the same code, captured at **v0.1.0+1** in release mode.

Each platform is captured twice — once wide, once narrow — because the
interesting claim is not just "it runs" but "it adapts". The size class in the
Display metrics card and the navigation affordance should disagree between the
two shots while everything else stays identical.

## Captured

| File | Platform | Window | Proves |
| --- | --- | --- | --- |
| [`linux-expanded.png`](linux-expanded.png) | Linux desktop (GTK) | 1280 × 720 | Native AOT binary; reports Ubuntu 24.04.4 noble; extended rail, two columns |
| [`linux-compact.png`](linux-compact.png) | Linux desktop (GTK) | 520 × 880 | **Same desktop binary** re-flowed below 600 dp to a bottom bar and one column |
| [`web-expanded.png`](web-expanded.png) | Web (Chrome 151) | 1400 × 950 | Compiled to JavaScript; browser and vendor identified; extended rail |
| [`web-compact.png`](web-compact.png) | Web (Chrome 151) | 430 × 900 | Phone-width browser tab gets the bottom bar, no code change |

The Linux pair is the more persuasive of the two: it is a *desktop* application
switching to a mobile navigation pattern purely because the window got narrower,
which is what makes the claim about one layout serving every form factor
concrete rather than theoretical.

Screens render dark here because the app follows the system colour scheme and
these hosts were set to dark; a light host produces the same layout in the light
palette.

## Still needed

Windows, macOS, iOS and Android. All four build green in CI, but no screenshots
exist because each must be captured on its own hardware. Android additionally
needs a physical device attached — the APK is built but has not yet run on real
hardware.

## Reproducing these

Linux, using the release bundle. The app is run under XWayland so the window can
be captured directly — GNOME 46 denies `org.gnome.Shell.Screenshot` to
unsandboxed callers, and grabbing a single window avoids capturing the rest of
the desktop:

```bash
flutter build linux --release
GDK_BACKEND=x11 ./build/linux/x64/release/bundle/property_management_app &
WID=$(wmctrl -l | grep property_management_app | awk '{print $1}')
wmctrl -i -r "$WID" -e 0,120,80,520,880   # optional: force the compact class
import -window "$WID" docs/proof/linux-compact.png
```

Web, via headless Chrome against a locally served release build:

```bash
flutter build web --release
(cd build/web && python3 -m http.server 8899 --bind 127.0.0.1 &)
google-chrome --headless --disable-gpu --enable-unsafe-swiftshader \
  --hide-scrollbars --virtual-time-budget=25000 --window-size=1400,950 \
  --screenshot=docs/proof/web-expanded.png http://127.0.0.1:8899/index.html
```

`--enable-unsafe-swiftshader` is what lets CanvasKit render without a GPU;
without it headless Chrome captures a blank canvas.
