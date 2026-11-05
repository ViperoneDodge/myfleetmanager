import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
KEY = 'app.slogan'
KEY = 'doc.notFound'
T = {
 'it': 'Il file non c\'è più: documento tolto dall\'elenco, aggiungilo di nuovo.',
 'en': 'The file is no longer there: document removed from the list, please add it again.',
 'fr': 'Le fichier n\'existe plus : document retiré de la liste, ajoutez-le à nouveau.',
 'de': 'Die Datei ist nicht mehr vorhanden: Dokument aus der Liste entfernt, bitte erneut hinzufügen.',
 'es': 'El archivo ya no existe: documento quitado de la lista, vuelve a añadirlo.',
 'pt': 'O ficheiro já não existe: documento removido da lista, adicione-o novamente.',
 'nl': 'Het bestand bestaat niet meer: document uit de lijst gehaald, voeg het opnieuw toe.',
 'hr': 'Datoteka više ne postoji: dokument je uklonjen s popisa, dodaj ga ponovno.',
 'sl': 'Datoteke ni več: dokument je odstranjen s seznama, dodaj ga znova.',
 'pl': 'Pliku już nie ma: dokument usunięto z listy, dodaj go ponownie.',
 'cs': 'Soubor už neexistuje: dokument byl odebrán ze seznamu, přidejte ho znovu.',
 'sk': 'Súbor už neexistuje: dokument bol odstránený zo zoznamu, pridajte ho znova.',
 'hu': 'A fájl már nincs meg: a dokumentum lekerült a listáról, add hozzá újra.',
 'ro': 'Fișierul nu mai există: documentul a fost scos din listă, adaugă-l din nou.',
 'bg': 'Файлът вече го няма: документът е премахнат от списъка, добави го отново.',
 'el': 'Το αρχείο δεν υπάρχει πια: το έγγραφο αφαιρέθηκε από τη λίστα, πρόσθεσέ το ξανά.',
 'sv': 'Filen finns inte längre: dokumentet togs bort från listan, lägg till det igen.',
 'da': 'Filen findes ikke længere: dokumentet er fjernet fra listen, tilføj det igen.',
 'nb': 'Filen finnes ikke lenger: dokumentet er fjernet fra listen, legg det til på nytt.',
 'fi': 'Tiedostoa ei enää ole: asiakirja poistettiin luettelosta, lisää se uudelleen.',
 'is': 'Skráin er ekki lengur til: skjalið var fjarlægt af listanum, bættu því við aftur.',
 'et': 'Faili enam pole: dokument eemaldati loendist, lisa see uuesti.',
 'lv': 'Faila vairs nav: dokuments noņemts no saraksta, pievieno to vēlreiz.',
 'lt': 'Failo nebėra: dokumentas pašalintas iš sąrašo, pridėk jį iš naujo.',
 'mt': 'Il-fajl m\'għadux hemm: id-dokument tneħħa mil-lista, erġa\' żidu.',
 'ga': 'Níl an comhad ann a thuilleadh: baineadh an doiciméad den liosta, cuir leis arís é.',
 'uk': 'Файлу більше немає: документ прибрано зі списку, додай його знову.',
 'ru': 'Файла больше нет: документ убран из списка, добавь его снова.',
 'tr': 'Dosya artık yok: belge listeden kaldırıldı, lütfen yeniden ekle.',
 'zh': '文件已不存在：该文档已从列表中移除，请重新添加。',
 'ja': 'ファイルが見つかりません。書類をリストから削除しました。もう一度追加してください。',
 'ko': '파일이 더 이상 없습니다. 문서를 목록에서 제거했으니 다시 추가하세요.',
 'hi': 'फ़ाइल अब मौजूद नहीं है: दस्तावेज़ सूची से हटा दिया गया, कृपया फिर से जोड़ें।',
 'id': 'File sudah tidak ada: dokumen dihapus dari daftar, tambahkan lagi.',
 'vi': 'Tệp không còn nữa: tài liệu đã bị xóa khỏi danh sách, hãy thêm lại.',
 'th': 'ไม่มีไฟล์นี้แล้ว: นำเอกสารออกจากรายการแล้ว โปรดเพิ่มใหม่',
}
keys = (S / 'order.txt').read_text().split('\n')[:-1]
i = keys.index(KEY)
langs = sorted(p.stem for p in L.glob('*.json'))
assert set(langs) == set(T), set(langs) ^ set(T)
for lang, v in T.items():
    p = L / f'{lang}.json'
    d = json.loads(p.read_text(encoding='utf-8'))
    d[KEY] = v
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    t = S / f'{lang}.txt'
    if t.exists():
        lines = t.read_text(encoding='utf-8').rstrip('\n').split('\n')
        lines[i] = v
        t.write_text('\n'.join(lines) + '\n', encoding='utf-8')
