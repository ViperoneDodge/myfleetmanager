import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['sync.problemTitle', 'sync.problemInfo', 'sync.problemGroups', 'sync.problemVehicles', 'sync.problemDocs', 'sync.problemSave', 'sync.retry']
T = {
 'it': ('Problema di sincronizzazione', 'Alcuni dati non si sincronizzano con il cloud. Le modifiche restano salvate sul telefono e verranno inviate appena il problema si risolve.', 'Elenco dei gruppi', 'Veicoli: {name}', 'Documenti: {name}', 'Salvataggio: {name}', 'Riprova'),
 'en': ('Sync problem', 'Some data is not syncing with the cloud. Your changes stay saved on the phone and will be sent as soon as the problem is solved.', 'List of groups', 'Vehicles: {name}', 'Documents: {name}', 'Saving: {name}', 'Retry'),
 'fr': ('Problème de synchronisation', 'Certaines données ne se synchronisent pas avec le cloud. Vos modifications restent enregistrées sur le téléphone et seront envoyées dès que le problème sera résolu.', 'Liste des groupes', 'Véhicules : {name}', 'Documents : {name}', 'Enregistrement : {name}', 'Réessayer'),
 'de': ('Synchronisierungsproblem', 'Einige Daten werden nicht mit der Cloud synchronisiert. Deine Änderungen bleiben auf dem Telefon gespeichert und werden gesendet, sobald das Problem behoben ist.', 'Liste der Gruppen', 'Fahrzeuge: {name}', 'Dokumente: {name}', 'Speichern: {name}', 'Erneut versuchen'),
 'es': ('Problema de sincronización', 'Algunos datos no se sincronizan con la nube. Tus cambios siguen guardados en el teléfono y se enviarán en cuanto se resuelva el problema.', 'Lista de grupos', 'Vehículos: {name}', 'Documentos: {name}', 'Guardado: {name}', 'Reintentar'),
 'pt': ('Problema de sincronização', 'Alguns dados não estão a sincronizar com a nuvem. As alterações ficam guardadas no telemóvel e serão enviadas assim que o problema for resolvido.', 'Lista de grupos', 'Veículos: {name}', 'Documentos: {name}', 'Gravação: {name}', 'Tentar novamente'),
 'nl': ('Synchronisatieprobleem', 'Sommige gegevens worden niet met de cloud gesynchroniseerd. Je wijzigingen blijven op de telefoon bewaard en worden verzonden zodra het probleem is opgelost.', 'Lijst met groepen', 'Voertuigen: {name}', 'Documenten: {name}', 'Opslaan: {name}', 'Opnieuw proberen'),
 'hr': ('Problem sa sinkronizacijom', 'Neki se podaci ne sinkroniziraju s oblakom. Promjene ostaju spremljene na telefonu i bit će poslane čim se problem riješi.', 'Popis grupa', 'Vozila: {name}', 'Dokumenti: {name}', 'Spremanje: {name}', 'Pokušaj ponovno'),
 'sl': ('Težava s sinhronizacijo', 'Nekateri podatki se ne sinhronizirajo z oblakom. Spremembe ostanejo shranjene v telefonu in bodo poslane, ko bo težava odpravljena.', 'Seznam skupin', 'Vozila: {name}', 'Dokumenti: {name}', 'Shranjevanje: {name}', 'Poskusi znova'),
 'pl': ('Problem z synchronizacją', 'Niektóre dane nie synchronizują się z chmurą. Zmiany pozostają zapisane w telefonie i zostaną wysłane, gdy problem zostanie rozwiązany.', 'Lista grup', 'Pojazdy: {name}', 'Dokumenty: {name}', 'Zapis: {name}', 'Spróbuj ponownie'),
 'cs': ('Problém se synchronizací', 'Některá data se nesynchronizují s cloudem. Změny zůstávají uložené v telefonu a odešlou se, jakmile bude problém vyřešen.', 'Seznam skupin', 'Vozidla: {name}', 'Dokumenty: {name}', 'Ukládání: {name}', 'Zkusit znovu'),
 'sk': ('Problém so synchronizáciou', 'Niektoré údaje sa nesynchronizujú s cloudom. Zmeny zostávajú uložené v telefóne a odošlú sa, keď sa problém vyrieši.', 'Zoznam skupín', 'Vozidlá: {name}', 'Dokumenty: {name}', 'Ukladanie: {name}', 'Skúsiť znova'),
 'hu': ('Szinkronizálási hiba', 'Néhány adat nem szinkronizálódik a felhővel. A módosítások a telefonon maradnak, és elküldjük őket, amint a hiba megoldódik.', 'Csoportok listája', 'Járművek: {name}', 'Dokumentumok: {name}', 'Mentés: {name}', 'Újra'),
 'ro': ('Problemă de sincronizare', 'Unele date nu se sincronizează cu cloudul. Modificările rămân salvate pe telefon și vor fi trimise imediat ce problema se rezolvă.', 'Lista grupurilor', 'Vehicule: {name}', 'Documente: {name}', 'Salvare: {name}', 'Reîncearcă'),
 'bg': ('Проблем със синхронизацията', 'Някои данни не се синхронизират с облака. Промените остават запазени в телефона и ще бъдат изпратени веднага щом проблемът бъде решен.', 'Списък с групи', 'Превозни средства: {name}', 'Документи: {name}', 'Запазване: {name}', 'Опитай отново'),
 'el': ('Πρόβλημα συγχρονισμού', 'Ορισμένα δεδομένα δεν συγχρονίζονται με το cloud. Οι αλλαγές παραμένουν αποθηκευμένες στο τηλέφωνο και θα σταλούν μόλις λυθεί το πρόβλημα.', 'Λίστα ομάδων', 'Οχήματα: {name}', 'Έγγραφα: {name}', 'Αποθήκευση: {name}', 'Δοκιμή ξανά'),
 'sv': ('Synkroniseringsproblem', 'Vissa data synkroniseras inte med molnet. Dina ändringar finns kvar i telefonen och skickas så snart problemet är löst.', 'Lista över grupper', 'Fordon: {name}', 'Dokument: {name}', 'Sparande: {name}', 'Försök igen'),
 'da': ('Synkroniseringsproblem', 'Nogle data synkroniseres ikke med skyen. Dine ændringer forbliver gemt på telefonen og sendes, så snart problemet er løst.', 'Liste over grupper', 'Køretøjer: {name}', 'Dokumenter: {name}', 'Gemning: {name}', 'Prøv igen'),
 'nb': ('Synkroniseringsproblem', 'Noen data synkroniseres ikke med skyen. Endringene dine blir lagret på telefonen og sendes så snart problemet er løst.', 'Liste over grupper', 'Kjøretøy: {name}', 'Dokumenter: {name}', 'Lagring: {name}', 'Prøv igjen'),
 'fi': ('Synkronointiongelma', 'Osa tiedoista ei synkronoidu pilveen. Muutokset pysyvät tallessa puhelimessa ja lähetetään heti, kun ongelma ratkeaa.', 'Ryhmien luettelo', 'Ajoneuvot: {name}', 'Asiakirjat: {name}', 'Tallennus: {name}', 'Yritä uudelleen'),
 'is': ('Samstillingarvandi', 'Sum gögn samstillast ekki við skýið. Breytingarnar þínar eru vistaðar í símanum og verða sendar um leið og vandinn leysist.', 'Listi yfir hópa', 'Ökutæki: {name}', 'Skjöl: {name}', 'Vistun: {name}', 'Reyna aftur'),
 'et': ('Sünkroonimise probleem', 'Osa andmeid ei sünkroonita pilvega. Muudatused jäävad telefoni salvestatuks ja saadetakse kohe, kui probleem laheneb.', 'Gruppide loend', 'Sõidukid: {name}', 'Dokumendid: {name}', 'Salvestamine: {name}', 'Proovi uuesti'),
 'lv': ('Sinhronizācijas problēma', 'Daļa datu netiek sinhronizēta ar mākoni. Izmaiņas paliek saglabātas tālrunī un tiks nosūtītas, tiklīdz problēma tiks novērsta.', 'Grupu saraksts', 'Transportlīdzekļi: {name}', 'Dokumenti: {name}', 'Saglabāšana: {name}', 'Mēģināt vēlreiz'),
 'lt': ('Sinchronizavimo problema', 'Kai kurie duomenys nesinchronizuojami su debesimi. Pakeitimai lieka išsaugoti telefone ir bus išsiųsti, kai tik problema išsispręs.', 'Grupių sąrašas', 'Transporto priemonės: {name}', 'Dokumentai: {name}', 'Įrašymas: {name}', 'Bandyti dar kartą'),
 'mt': ('Problema fis-sinkronizzazzjoni', 'Xi data mhix qed tissinkronizza mal-cloud. It-tibdiliet jibqgħu ssejvjati fuq it-telefon u jintbagħtu hekk kif tissolva l-problema.', 'Lista tal-gruppi', 'Vetturi: {name}', 'Dokumenti: {name}', 'Issejvjar: {name}', 'Erġa\' pprova'),
 'ga': ('Fadhb sioncrónaithe', 'Níl roinnt sonraí á sioncrónú leis an scamall. Fanann d\'athruithe sábháilte ar an bhfón agus seolfar iad a luaithe a réitítear an fhadhb.', 'Liosta grúpaí', 'Feithiclí: {name}', 'Doiciméid: {name}', 'Sábháil: {name}', 'Bain triail eile as'),
 'uk': ('Проблема синхронізації', 'Деякі дані не синхронізуються з хмарою. Зміни залишаються збереженими на телефоні й будуть надіслані, щойно проблему буде вирішено.', 'Список груп', 'Транспорт: {name}', 'Документи: {name}', 'Збереження: {name}', 'Повторити'),
 'ru': ('Проблема синхронизации', 'Некоторые данные не синхронизируются с облаком. Изменения остаются сохранёнными на телефоне и будут отправлены, как только проблема будет решена.', 'Список групп', 'Транспорт: {name}', 'Документы: {name}', 'Сохранение: {name}', 'Повторить'),
 'tr': ('Senkronizasyon sorunu', 'Bazı veriler bulutla senkronize olmuyor. Değişiklikleriniz telefonda kayıtlı kalır ve sorun çözülür çözülmez gönderilir.', 'Grup listesi', 'Araçlar: {name}', 'Belgeler: {name}', 'Kaydetme: {name}', 'Tekrar dene'),
 'zh': ('同步出现问题', '部分数据未能与云端同步。您的更改仍保存在手机上，问题解决后会立即上传。', '群组列表', '车辆：{name}', '文件：{name}', '保存：{name}', '重试'),
 'ja': ('同期の問題', '一部のデータがクラウドと同期されていません。変更はスマートフォンに保存されており、問題が解決するとすぐに送信されます。', 'グループ一覧', '車両：{name}', '書類：{name}', '保存：{name}', '再試行'),
 'ko': ('동기화 문제', '일부 데이터가 클라우드와 동기화되지 않습니다. 변경 내용은 휴대폰에 저장되어 있으며 문제가 해결되면 바로 전송됩니다.', '그룹 목록', '차량: {name}', '문서: {name}', '저장: {name}', '다시 시도'),
 'hi': ('सिंक में समस्या', 'कुछ डेटा क्लाउड के साथ सिंक नहीं हो रहा है। आपके बदलाव फ़ोन में सुरक्षित हैं और समस्या ठीक होते ही भेज दिए जाएँगे।', 'समूहों की सूची', 'वाहन: {name}', 'दस्तावेज़: {name}', 'सहेजना: {name}', 'फिर से कोशिश करें'),
 'id': ('Masalah sinkronisasi', 'Sebagian data tidak tersinkron dengan cloud. Perubahan tetap tersimpan di ponsel dan akan dikirim begitu masalahnya teratasi.', 'Daftar grup', 'Kendaraan: {name}', 'Dokumen: {name}', 'Penyimpanan: {name}', 'Coba lagi'),
 'vi': ('Lỗi đồng bộ', 'Một số dữ liệu không đồng bộ được với đám mây. Thay đổi vẫn được lưu trên điện thoại và sẽ được gửi ngay khi sự cố được khắc phục.', 'Danh sách nhóm', 'Xe: {name}', 'Tài liệu: {name}', 'Lưu: {name}', 'Thử lại'),
 'th': ('ปัญหาการซิงค์', 'ข้อมูลบางส่วนซิงค์กับคลาวด์ไม่ได้ การเปลี่ยนแปลงยังบันทึกอยู่ในโทรศัพท์และจะส่งทันทีเมื่อแก้ปัญหาได้', 'รายการกลุ่ม', 'ยานพาหนะ: {name}', 'เอกสาร: {name}', 'การบันทึก: {name}', 'ลองอีกครั้ง'),
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
