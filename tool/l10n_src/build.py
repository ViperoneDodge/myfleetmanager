"""Converte tool/l10n_src/<lingua>.txt (un testo per riga, nello stesso ordine di
order.txt / en.json) in assets/l10n/<lingua>.json, controllando numero di righe
e segnaposto {..}."""
import json, pathlib, re, sys
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
keys = (S / 'order.txt').read_text().split('\n')[:-1]
en = json.loads((L / 'en.json').read_text())
ok = True
for lang in sys.argv[1:]:
    lines = (S / f'{lang}.txt').read_text(encoding='utf-8').split('\n')
    while lines and lines[-1] == '':
        lines.pop()
    if len(lines) != len(keys):
        print(f'{lang}: {len(lines)} righe invece di {len(keys)}')
        for i, (k, v) in enumerate(zip(keys, lines)):
            if set(re.findall(r'\{\w+\}', en[k])) != set(re.findall(r'\{\w+\}', v)):
                print('  primo sospetto:', i + 1, k, '|', v); break
        ok = False
        continue
    bad = []
    for i, (k, v) in enumerate(zip(keys, lines)):
        need = set(re.findall(r'\{\w+\}', en[k]))
        have = set(re.findall(r'\{\w+\}', v))
        if k.endswith('_one'):
            need.discard('{n}'); have.discard('{n}')
        if need != have or not v.strip():
            bad.append((i + 1, k, v))
    if bad:
        ok = False
        for b in bad: print(lang, 'segnaposto:', *b)
        continue
    d = {k: v.strip() + (' ' if en[k].endswith(' ') else '') for k, v in zip(keys, lines)}
    (L / f'{lang}.json').write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(lang, 'ok', len(d))
sys.exit(0 if ok else 1)
