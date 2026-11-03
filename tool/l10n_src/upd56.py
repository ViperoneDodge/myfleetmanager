import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['docs.withdrawConfirm']
T = {
 'it': ("Le copie online dei tuoi documenti verranno cancellate. I documenti restano su questo telefono.",),
 'en': ("The online copies of your documents will be deleted. The documents stay on this phone.",),
 'fr': ("Les copies en ligne de tes documents seront supprimées. Les documents restent sur ce téléphone.",),
 'de': ("Die Online-Kopien deiner Dokumente werden gelöscht. Die Dokumente bleiben auf diesem Telefon.",),
 'es': ("Se eliminarán las copias en línea de tus documentos. Los documentos se quedan en este teléfono.",),
 'pt': ("As cópias online dos teus documentos serão eliminadas. Os documentos ficam neste telemóvel.",),
 'nl': ("De online kopieën van je documenten worden verwijderd. De documenten blijven op deze telefoon.",),
 'hr': ("Mrežne kopije tvojih dokumenata bit će izbrisane. Dokumenti ostaju na ovom telefonu.",),
 'sl': ("Spletne kopije tvojih dokumentov bodo izbrisane. Dokumenti ostanejo na tem telefonu.",),
 'pl': ("Kopie online twoich dokumentów zostaną usunięte. Dokumenty pozostaną na tym telefonie.",),
 'cs': ("Online kopie tvých dokumentů budou smazány. Dokumenty zůstanou v tomto telefonu.",),
 'sk': ("Online kópie tvojich dokumentov budú vymazané. Dokumenty zostanú v tomto telefóne.",),
 'hu': ("A dokumentumaid online másolatai törlődnek. A dokumentumok ezen a telefonon maradnak.",),
 'ro': ("Copiile online ale documentelor tale vor fi șterse. Documentele rămân pe acest telefon.",),
 'bg': ("Онлайн копията на документите ти ще бъдат изтрити. Документите остават на този телефон.",),
 'el': ("Τα online αντίγραφα των εγγράφων σου θα διαγραφούν. Τα έγγραφα μένουν σε αυτό το τηλέφωνο.",),
 'sv': ("Onlinekopiorna av dina dokument raderas. Dokumenten finns kvar på den här telefonen.",),
 'da': ("Onlinekopierne af dine dokumenter slettes. Dokumenterne bliver på denne telefon.",),
 'nb': ("Nettkopiene av dokumentene dine slettes. Dokumentene blir værende på denne telefonen.",),
 'fi': ("Asiakirjojesi verkkokopiot poistetaan. Asiakirjat jäävät tähän puhelimeen.",),
 'is': ("Netafritum skjalanna þinna verður eytt. Skjölin verða áfram á þessum síma.",),
 'et': ("Sinu dokumentide veebikoopiad kustutatakse. Dokumendid jäävad sellesse telefoni.",),
 'lv': ("Tavu dokumentu tiešsaistes kopijas tiks dzēstas. Dokumenti paliek šajā tālrunī.",),
 'lt': ("Internetinės tavo dokumentų kopijos bus ištrintos. Dokumentai liks šiame telefone.",),
 'mt': ("Il-kopji online tad-dokumenti tiegħek se jitħassru. Id-dokumenti jibqgħu fuq dan it-telefon.",),
 'ga': ("Scriosfar na cóipeanna ar líne de do dhoiciméid. Fanfaidh na doiciméid ar an bhfón seo.",),
 'ru': ("Онлайн-копии твоих документов будут удалены. Документы останутся на этом телефоне.",),
 'uk': ("Онлайн-копії твоїх документів буде видалено. Документи залишаться на цьому телефоні.",),
 'tr': ("Belgelerinin çevrimiçi kopyaları silinecek. Belgeler bu telefonda kalır.",),
 'hi': ("आपके दस्तावेज़ों की ऑनलाइन प्रतियाँ हटा दी जाएँगी। दस्तावेज़ इस फ़ोन पर बने रहेंगे।",),
 'id': ("Salinan online dokumenmu akan dihapus. Dokumen tetap ada di ponsel ini.",),
 'vi': ("Các bản sao trực tuyến của tài liệu sẽ bị xóa. Tài liệu vẫn còn trên điện thoại này.",),
 'th': ("สำเนาออนไลน์ของเอกสารของคุณจะถูกลบ เอกสารยังอยู่ในโทรศัพท์เครื่องนี้",),
 'ja': ("書類のオンラインコピーは削除されます。書類はこのスマートフォンに残ります。",),
 'ko': ("문서의 온라인 사본이 삭제됩니다. 문서는 이 휴대폰에 그대로 남습니다.",),
 'zh': ("你的文件的在线副本将被删除。文件会保留在这部手机上。",),
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
