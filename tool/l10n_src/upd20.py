import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['ocr.rawText', 'ocr.rawCopied']
T = {
 'it': ['Testo letto', 'Testo copiato'], 'en': ['Text read', 'Text copied'],
 'fr': ['Texte lu', 'Texte copié'], 'de': ['Gelesener Text', 'Text kopiert'],
 'es': ['Texto leído', 'Texto copiado'], 'pt': ['Texto lido', 'Texto copiado'],
 'nl': ['Gelezen tekst', 'Tekst gekopieerd'], 'hr': ['Pročitani tekst', 'Tekst kopiran'],
 'sl': ['Prebrano besedilo', 'Besedilo kopirano'], 'pl': ['Odczytany tekst', 'Tekst skopiowany'],
 'cs': ['Přečtený text', 'Text zkopírován'], 'sk': ['Prečítaný text', 'Text skopírovaný'],
 'hu': ['Beolvasott szöveg', 'Szöveg másolva'], 'ro': ['Text citit', 'Text copiat'],
 'bg': ['Прочетен текст', 'Текстът е копиран'], 'el': ['Κείμενο που διαβάστηκε', 'Το κείμενο αντιγράφηκε'],
 'sv': ['Läst text', 'Texten kopierad'], 'da': ['Læst tekst', 'Tekst kopieret'],
 'nb': ['Lest tekst', 'Tekst kopiert'], 'fi': ['Luettu teksti', 'Teksti kopioitu'],
 'is': ['Lesinn texti', 'Texti afritaður'], 'et': ['Loetud tekst', 'Tekst kopeeritud'],
 'lv': ['Nolasītais teksts', 'Teksts nokopēts'], 'lt': ['Nuskaitytas tekstas', 'Tekstas nukopijuotas'],
 'mt': ['Test moqri', 'Test ikkopjat'], 'ga': ['Téacs léite', 'Téacs cóipeáilte'],
 'uk': ['Зчитаний текст', 'Текст скопійовано'], 'ru': ['Распознанный текст', 'Текст скопирован'],
 'tr': ['Okunan metin', 'Metin kopyalandı'], 'zh': ['识别的文本', '文本已复制'],
 'ja': ['読み取ったテキスト', 'テキストをコピーしました'], 'ko': ['읽은 텍스트', '텍스트를 복사했습니다'],
 'hi': ['पढ़ा गया पाठ', 'पाठ कॉपी किया गया'], 'id': ['Teks terbaca', 'Teks disalin'],
 'vi': ['Văn bản đã đọc', 'Đã sao chép văn bản'], 'th': ['ข้อความที่อ่านได้', 'คัดลอกข้อความแล้ว'],
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
assert not set(NEW) & set(keys)
order.write_text('\n'.join(keys + NEW) + '\n')
for lang, vals in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d.update(zip(NEW, vals))
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        t.write_text('\n'.join(lines + vals) + '\n', encoding='utf-8')
assert sorted(T) == sorted(x.stem for x in L.glob('*.json'))
print('ok', len(keys) + len(NEW))
