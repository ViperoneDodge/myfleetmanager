import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['pdf.chooseGroups', 'pdf.allGroups']
T = {
 'it': ('Cosa vuoi esportare?', 'Tutti i gruppi'),
 'en': ('What do you want to export?', 'All groups'),
 'fr': ('Que voulez-vous exporter ?', 'Tous les groupes'),
 'de': ('Was möchtest du exportieren?', 'Alle Gruppen'),
 'es': ('¿Qué quieres exportar?', 'Todos los grupos'),
 'pt': ('O que pretende exportar?', 'Todos os grupos'),
 'nl': ('Wat wil je exporteren?', 'Alle groepen'),
 'hr': ('Što želiš izvesti?', 'Sve grupe'),
 'sl': ('Kaj želiš izvoziti?', 'Vse skupine'),
 'pl': ('Co chcesz wyeksportować?', 'Wszystkie grupy'),
 'cs': ('Co chcete exportovat?', 'Všechny skupiny'),
 'sk': ('Čo chcete exportovať?', 'Všetky skupiny'),
 'hu': ('Mit szeretnél exportálni?', 'Összes csoport'),
 'ro': ('Ce vrei să exporți?', 'Toate grupurile'),
 'bg': ('Какво искате да експортирате?', 'Всички групи'),
 'el': ('Τι θέλεις να εξαγάγεις;', 'Όλες οι ομάδες'),
 'sv': ('Vad vill du exportera?', 'Alla grupper'),
 'da': ('Hvad vil du eksportere?', 'Alle grupper'),
 'nb': ('Hva vil du eksportere?', 'Alle grupper'),
 'fi': ('Mitä haluat viedä?', 'Kaikki ryhmät'),
 'is': ('Hvað viltu flytja út?', 'Allir hópar'),
 'et': ('Mida soovid eksportida?', 'Kõik grupid'),
 'lv': ('Ko vēlies eksportēt?', 'Visas grupas'),
 'lt': ('Ką norite eksportuoti?', 'Visos grupės'),
 'mt': ('X\'trid tesporta?', 'Il-gruppi kollha'),
 'ga': ('Cad ba mhaith leat a easpórtáil?', 'Gach grúpa'),
 'uk': ('Що ви хочете експортувати?', 'Усі групи'),
 'ru': ('Что вы хотите экспортировать?', 'Все группы'),
 'tr': ('Neyi dışa aktarmak istiyorsun?', 'Tüm gruplar'),
 'zh': ('要导出什么？', '所有群组'),
 'ja': ('何をエクスポートしますか？', 'すべてのグループ'),
 'ko': ('무엇을 내보낼까요?', '모든 그룹'),
 'hi': ('आप क्या निर्यात करना चाहते हैं?', 'सभी समूह'),
 'id': ('Apa yang ingin diekspor?', 'Semua grup'),
 'vi': ('Bạn muốn xuất gì?', 'Tất cả nhóm'),
 'th': ('ต้องการส่งออกอะไร', 'ทุกกลุ่ม'),
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
