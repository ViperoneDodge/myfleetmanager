import asyncio
import pathlib
import sys

from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else 'http://localhost:8765/'
OUT = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else 'web-test')
ENGINES = sys.argv[3].split(',') if len(sys.argv) > 3 else ['chromium', 'firefox', 'webkit']
EXE = sys.argv[4] if len(sys.argv) > 4 else None


async def text_visible(pg, text, timeout=20000):
    await pg.get_by_text(text, exact=False).first.wait_for(state='attached', timeout=timeout)


async def tap(pg, text):
    el = pg.get_by_text(text, exact=False).first
    await el.wait_for(state='attached', timeout=20000)
    box = await el.bounding_box()
    await pg.mouse.click(box['x'] + box['width'] / 2, box['y'] + box['height'] / 2)


async def field(pg, label, value):
    el = pg.get_by_label(label, exact=False).first
    await el.wait_for(state='attached', timeout=20000)
    box = await el.bounding_box()
    await pg.mouse.click(box['x'] + box['width'] / 2, box['y'] + box['height'] / 2)
    await pg.wait_for_timeout(400)
    await pg.keyboard.type(value, delay=30)


async def run(p, engine):
    errors = []
    kind = getattr(p, engine)
    browser = await (kind.launch(executable_path=EXE) if EXE else kind.launch())
    ctx = await browser.new_context(viewport={'width': 1280, 'height': 800}, locale='it-IT')
    pg = await ctx.new_page()
    pg.on('pageerror', lambda e: errors.append(str(e)))
    step = 'apertura'
    try:
        await pg.goto(URL, wait_until='load')
        await pg.wait_for_timeout(4000)
        await pg.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
        step = 'schermata di accesso'
        await text_visible(pg, 'Accedi', 60000)
        await pg.screenshot(path=str(OUT / f'{engine}-1-login.png'))
        step = 'registrazione'
        await tap(pg, 'Registrati')
        await pg.wait_for_timeout(800)
        await field(pg, 'Nome utente', 'Prova')
        await field(pg, 'Password', 'prova123')
        await field(pg, 'Ripeti password', 'prova123')
        await tap(pg, 'Crea account')
        step = 'pagina principale'
        await text_visible(pg, 'Nessun veicolo', 30000)
        await pg.screenshot(path=str(OUT / f'{engine}-2-home.png'))
        step = 'ricarica'
        await pg.reload(wait_until='load')
        await pg.wait_for_timeout(4000)
        await pg.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
        await text_visible(pg, 'Nessun veicolo', 60000)
        await pg.screenshot(path=str(OUT / f'{engine}-3-reload.png'))
        ok = True
    except Exception as e:
        errors.append(f'{step}: {e}'.splitlines()[0])
        try:
            await pg.screenshot(path=str(OUT / f'{engine}-errore.png'))
        except Exception:
            pass
        ok = False
    await browser.close()
    return ok, step, errors


async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    async with async_playwright() as p:
        for engine in ENGINES:
            ok, step, errors = await run(p, engine)
            results.append((engine, ok, step, errors))
    lines = []
    for engine, ok, step, errors in results:
        lines.append(f"{engine}: {'OK' if ok else 'ERRORE in ' + step}")
        for e in errors[:5]:
            lines.append(f'  - {e}')
    report = '\n'.join(lines)
    print(report)
    (OUT / 'risultato.txt').write_text(report + '\n')
    if not all(r[1] for r in results):
        sys.exit(1)


asyncio.run(main())
