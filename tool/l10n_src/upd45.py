import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['notif.seen', 'notif.changed', 'notif.new']
T = {
 'it': ('Visto', 'Modificato', 'Nuovo'),
 'en': ('Seen', 'Changed', 'New'),
 'fr': ('Vu', 'Modifié', 'Nouveau'),
 'de': ('Gesehen', 'Geändert', 'Neu'),
 'es': ('Visto', 'Modificado', 'Nuevo'),
 'pt': ('Visto', 'Alterado', 'Novo'),
 'nl': ('Gezien', 'Gewijzigd', 'Nieuw'),
 'hr': ('Viđeno', 'Izmijenjeno', 'Novo'),
 'sl': ('Videno', 'Spremenjeno', 'Novo'),
 'pl': ('Widziane', 'Zmienione', 'Nowe'),
 'cs': ('Viděno', 'Změněno', 'Nové'),
 'sk': ('Videné', 'Zmenené', 'Nové'),
 'hu': ('Láttam', 'Módosítva', 'Új'),
 'ro': ('Văzut', 'Modificat', 'Nou'),
 'bg': ('Видяно', 'Променено', 'Ново'),
 'el': ('Το είδα', 'Αλλαγή', 'Νέο'),
 'sv': ('Sett', 'Ändrad', 'Ny'),
 'da': ('Set', 'Ændret', 'Ny'),
 'nb': ('Sett', 'Endret', 'Ny'),
 'fi': ('Nähty', 'Muutettu', 'Uusi'),
 'is': ('Séð', 'Breytt', 'Nýtt'),
 'et': ('Nähtud', 'Muudetud', 'Uus'),
 'lv': ('Redzēts', 'Mainīts', 'Jauns'),
 'lt': ('Matyta', 'Pakeista', 'Nauja'),
 'mt': ('Rajt', 'Mibdul', 'Ġdid'),
 'ga': ('Feicthe', 'Athraithe', 'Nua'),
 'ru': ('Просмотрено', 'Изменено', 'Новое'),
 'uk': ('Переглянуто', 'Змінено', 'Нове'),
 'tr': ('Görüldü', 'Değişti', 'Yeni'),
 'hi': ('देख लिया', 'बदला गया', 'नया'),
 'id': ('Dilihat', 'Diubah', 'Baru'),
 'vi': ('Đã xem', 'Đã sửa', 'Mới'),
 'th': ('ดูแล้ว', 'แก้ไขแล้ว', 'ใหม่'),
 'ja': ('確認済み', '変更', '新規'),
 'ko': ('확인', '변경됨', '새 항목'),
 'zh': ('已查看', '已修改', '新增'),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, vals in T.items():
    assert len(vals) == len(NEW), lang
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    for k, v in zip(NEW, vals):
        d[k] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + list(vals)) + '\n', encoding='utf-8')
