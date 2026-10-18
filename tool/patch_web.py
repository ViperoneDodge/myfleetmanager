import json
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
ICONS = ROOT / "tool" / "web_icons"
BLUE = "#0257C3"

if WEB.exists():
    (WEB / "icons").mkdir(exist_ok=True)
    for f in ICONS.iterdir():
        shutil.copy(f, (WEB / f.name) if f.name == "favicon.png" else (WEB / "icons" / f.name))
    (WEB / "index.html").write_text(f"""<!DOCTYPE html>
<html lang="it">
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="MyFleetManager: scadenze, manutenzioni e documenti dei tuoi veicoli, anche in gruppo.">
  <meta name="theme-color" content="{BLUE}">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="MyFleetManager">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">
  <title>MyFleetManager</title>
  <style>
    html, body {{ margin: 0; height: 100%; background: {BLUE}; }}
    #splash {{ position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; }}
    #splash img {{ width: 112px; height: 112px; border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,.25); }}
  </style>
</head>
<body>
  <div id="splash"><img src="icons/Icon-192.png" alt="MyFleetManager"></div>
  <script>
    window.addEventListener('flutter-first-frame', function () {{
      var s = document.getElementById('splash');
      if (s) s.remove();
    }});
  </script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
""")
    (WEB / "manifest.json").write_text(json.dumps({
        "name": "MyFleetManager",
        "short_name": "MyFleet",
        "start_url": ".",
        "display": "standalone",
        "background_color": BLUE,
        "theme_color": BLUE,
        "description": "Scadenze, manutenzioni e documenti dei tuoi veicoli, anche in gruppo.",
        "prefer_related_applications": False,
        "icons": [
            {"src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png"},
            {"src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
            {"src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
    }, indent=2) + "\n")
    print("Patched", WEB)
