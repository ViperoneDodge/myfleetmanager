import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['diag.title', 'diag.subtitle', 'diag.copied']
T = {
 'it': ('Diagnostica sincronizzazione', 'Informazioni tecniche da inviare allo sviluppatore', 'Diagnostica copiata'),
 'en': ('Sync diagnostics', 'Technical information to send to the developer', 'Diagnostics copied'),
 'fr': ('Diagnostic de synchronisation', 'Informations techniques à envoyer au développeur', 'Diagnostic copié'),
 'de': ('Synchronisierungsdiagnose', 'Technische Informationen für den Entwickler', 'Diagnose kopiert'),
 'es': ('Diagnóstico de sincronización', 'Información técnica para enviar al desarrollador', 'Diagnóstico copiado'),
 'pt': ('Diagnóstico de sincronização', 'Informações técnicas para enviar ao programador', 'Diagnóstico copiado'),
 'nl': ('Synchronisatiediagnose', 'Technische informatie voor de ontwikkelaar', 'Diagnose gekopieerd'),
 'hr': ('Dijagnostika sinkronizacije', 'Tehnički podaci za razvojnog programera', 'Dijagnostika kopirana'),
 'sl': ('Diagnostika sinhronizacije', 'Tehnični podatki za razvijalca', 'Diagnostika kopirana'),
 'pl': ('Diagnostyka synchronizacji', 'Informacje techniczne dla twórcy aplikacji', 'Diagnostyka skopiowana'),
 'cs': ('Diagnostika synchronizace', 'Technické informace pro vývojáře', 'Diagnostika zkopírována'),
 'sk': ('Diagnostika synchronizácie', 'Technické informácie pre vývojára', 'Diagnostika skopírovaná'),
 'hu': ('Szinkronizálási diagnosztika', 'Műszaki adatok a fejlesztőnek', 'Diagnosztika másolva'),
 'ro': ('Diagnosticare sincronizare', 'Informații tehnice pentru dezvoltator', 'Diagnosticare copiată'),
 'bg': ('Диагностика на синхронизацията', 'Техническа информация за разработчика', 'Диагностиката е копирана'),
 'el': ('Διαγνωστικά συγχρονισμού', 'Τεχνικές πληροφορίες για τον προγραμματιστή', 'Τα διαγνωστικά αντιγράφηκαν'),
 'sv': ('Synkroniseringsdiagnostik', 'Teknisk information till utvecklaren', 'Diagnostik kopierad'),
 'da': ('Synkroniseringsdiagnostik', 'Teknisk information til udvikleren', 'Diagnostik kopieret'),
 'nb': ('Synkroniseringsdiagnostikk', 'Teknisk informasjon til utvikleren', 'Diagnostikk kopiert'),
 'fi': ('Synkronoinnin diagnostiikka', 'Tekniset tiedot kehittäjälle', 'Diagnostiikka kopioitu'),
 'is': ('Greining samstillingar', 'Tæknilegar upplýsingar fyrir forritarann', 'Greining afrituð'),
 'et': ('Sünkroonimise diagnostika', 'Tehniline teave arendajale', 'Diagnostika kopeeritud'),
 'lv': ('Sinhronizācijas diagnostika', 'Tehniskā informācija izstrādātājam', 'Diagnostika nokopēta'),
 'lt': ('Sinchronizavimo diagnostika', 'Techninė informacija kūrėjui', 'Diagnostika nukopijuota'),
 'mt': ('Dijanjostika tas-sinkronizzazzjoni', 'Informazzjoni teknika għall-iżviluppatur', 'Dijanjostika kkupjata'),
 'ga': ('Diagnóisic sioncrónaithe', 'Faisnéis theicniúil don fhorbróir', 'Diagnóisic cóipeáilte'),
 'uk': ('Діагностика синхронізації', 'Технічна інформація для розробника', 'Діагностику скопійовано'),
 'ru': ('Диагностика синхронизации', 'Техническая информация для разработчика', 'Диагностика скопирована'),
 'tr': ('Senkronizasyon tanılama', 'Geliştiriciye gönderilecek teknik bilgiler', 'Tanılama kopyalandı'),
 'zh': ('同步诊断', '发送给开发者的技术信息', '诊断信息已复制'),
 'ja': ('同期の診断', '開発者に送る技術情報', '診断情報をコピーしました'),
 'ko': ('동기화 진단', '개발자에게 보낼 기술 정보', '진단 정보가 복사됨'),
 'hi': ('सिंक निदान', 'डेवलपर को भेजने के लिए तकनीकी जानकारी', 'निदान कॉपी हो गया'),
 'id': ('Diagnostik sinkronisasi', 'Informasi teknis untuk dikirim ke pengembang', 'Diagnostik disalin'),
 'vi': ('Chẩn đoán đồng bộ', 'Thông tin kỹ thuật gửi cho nhà phát triển', 'Đã sao chép chẩn đoán'),
 'th': ('การวินิจฉัยการซิงค์', 'ข้อมูลทางเทคนิคสำหรับส่งให้ผู้พัฒนา', 'คัดลอกการวินิจฉัยแล้ว'),
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
