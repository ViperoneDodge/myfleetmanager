import json
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
ICONS = ROOT / "tool" / "web_icons"
PAGES = ROOT / "docs"
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
    #splash {{ background: linear-gradient(180deg, #0B5CC8 0%, #063F95 100%); }}
    #splash {{ position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; }}
    #splash img {{ width: 112px; height: 112px; border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,.25); }}
    @font-face {{ font-family: 'Lobster'; src: url('assets/assets/fonts/Lobster-Regular.ttf'); font-display: swap; }}
    @font-face {{ font-family: 'LobsterTwo'; src: url('assets/assets/fonts/LobsterTwo-Regular.ttf'); font-display: swap; }}
    #splash .box {{ display: flex; flex-direction: column; align-items: center; box-sizing: border-box; width: 100%; padding: 24px; text-align: center; }}
    #splash .name {{ font-family: 'Lobster', cursive; color: #fff; font-size: clamp(30px, 10vw, 46px); margin-top: 22px;
      text-shadow: 2px 3px 0 rgba(0,0,0,.4); }}
    #splash .slogan {{ font-family: 'LobsterTwo', cursive; color: #FFD54F; font-size: clamp(22px, 7vw, 32px); line-height: 1.05;
      margin-top: 14px; transform: rotate(-6deg); text-shadow: 2px 3px 0 rgba(0,0,0,.6); }}
  </style>
</head>
<body>
  <div id="splash"><div class="box"><img src="icons/Icon-192.png" alt="MyFleetManager">
    <div class="name">MyFleetManager</div><div class="slogan" id="slogan"></div></div></div>
  <script>
    (function () {{
      var it0 = (navigator.language || 'it').toLowerCase().indexOf('it') === 0;
      document.getElementById('slogan').innerHTML = it0
        ? 'La tua flotta nel<br>palmo della mano' : 'Your fleet in the<br>palm of your hand';
      var ok = 'noModule' in document.createElement('script') && !!window.fetch && !!window.Promise
        && !!window.ResizeObserver && typeof Array.prototype.at === 'function'
        && typeof structuredClone === 'function';
      var gl = false;
      try {{
        var cv = document.createElement('canvas');
        gl = !!(cv.getContext('webgl2') || cv.getContext('webgl'));
      }} catch (e) {{}}
      if (!ok || !gl) {{
        var it = (navigator.language || 'it').toLowerCase().indexOf('it') === 0;
        var s = document.getElementById('splash');
        s.innerHTML = '<div style="max-width:420px;margin:24px;padding:24px;background:#fff;border-radius:16px;'
          + 'font-family:Arial,sans-serif;text-align:center;color:#1B2430">'
          + '<img src="icons/Icon-192.png" style="width:72px;height:72px;border-radius:16px" alt="">'
          + '<h2 style="margin:12px 0 8px">MyFleetManager</h2><p style="margin:0;line-height:1.5">'
          + (!ok
              ? (it ? 'Questo browser non è supportato. Apri MyFleetManager con Chrome, Edge, Firefox o Safari aggiornati.'
                    : 'This browser is not supported. Please open MyFleetManager with an up-to-date Chrome, Edge, Firefox or Safari.')
              : (it ? 'Il browser non riesce a usare la grafica WebGL. Attiva l\\'accelerazione hardware nelle impostazioni del browser oppure prova con un altro browser.'
                    : 'Your browser cannot use WebGL graphics. Turn on hardware acceleration in the browser settings or try another browser.'))
          + '</p></div>';
        return;
      }}
      window.addEventListener('flutter-first-frame', function () {{
        var el = document.getElementById('splash');
        if (el) el.parentNode.removeChild(el);
      }});
      var sc = document.createElement('script');
      sc.src = 'flutter_bootstrap.js';
      sc.async = true;
      document.body.appendChild(sc);
    }})();
  </script>
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

for name in ("privacy.html", "join.html", "gian_trip_logo.png"):
    shutil.copy(PAGES / name, WEB / name)
shutil.copy(PAGES / "icon.png", WEB / "app-icon.png")
for name in ("privacy.html", "join.html"):
    t = (WEB / name).read_text(encoding="utf-8").replace('"icon.png"', '"app-icon.png"')
    (WEB / name).write_text(t, encoding="utf-8")
print("Pagine privacy e invito copiate")
