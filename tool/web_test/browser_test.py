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
        await text_visible(pg, 'Le scadenze dei tuoi veicoli', 60000)
        await pg.wait_for_timeout(1500)
        await pg.screenshot(path=str(OUT / f'{engine}-1-login.png'))
        step = 'ricarica'
        await pg.reload(wait_until='load')
        await pg.wait_for_timeout(4000)
        await pg.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
        await text_visible(pg, 'Le scadenze dei tuoi veicoli', 60000)
        await pg.screenshot(path=str(OUT / f'{engine}-2-reload.png'))
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
