import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['pro.benefitNoAds', 'ads.privacy', 'ads.privacySub']
T = {
 'it': ('Nessuna pubblicità', 'Privacy della pubblicità', 'Rivedi le tue scelte sugli annunci personalizzati'),
 'en': ('No ads', 'Ad privacy', 'Review your choices about personalised ads'),
 'fr': ('Aucune publicité', 'Confidentialité des annonces', 'Revois tes choix sur les annonces personnalisées'),
 'de': ('Keine Werbung', 'Werbe-Datenschutz', 'Deine Auswahl zu personalisierter Werbung prüfen'),
 'es': ('Sin publicidad', 'Privacidad de los anuncios', 'Revisa tus opciones sobre anuncios personalizados'),
 'pt': ('Sem publicidade', 'Privacidade dos anúncios', 'Revê as tuas escolhas sobre anúncios personalizados'),
 'nl': ('Geen advertenties', 'Advertentieprivacy', 'Bekijk je keuzes voor gepersonaliseerde advertenties'),
 'hr': ('Bez oglasa', 'Privatnost oglasa', 'Pregledaj svoje izbore za personalizirane oglase'),
 'sl': ('Brez oglasov', 'Zasebnost oglasov', 'Preglej svoje izbire za prilagojene oglase'),
 'pl': ('Bez reklam', 'Prywatność reklam', 'Sprawdź swoje wybory dotyczące spersonalizowanych reklam'),
 'cs': ('Bez reklam', 'Soukromí reklam', 'Zkontroluj své volby pro personalizované reklamy'),
 'sk': ('Bez reklám', 'Súkromie reklám', 'Skontroluj svoje voľby pre prispôsobené reklamy'),
 'hu': ('Reklámmentes', 'Hirdetési adatvédelem', 'Személyre szabott hirdetésekkel kapcsolatos döntéseid áttekintése'),
 'ro': ('Fără reclame', 'Confidențialitatea reclamelor', 'Revizuiește alegerile despre reclamele personalizate'),
 'bg': ('Без реклами', 'Поверителност на рекламите', 'Прегледай избора си за персонализирани реклами'),
 'el': ('Χωρίς διαφημίσεις', 'Απόρρητο διαφημίσεων', 'Έλεγξε τις επιλογές σου για εξατομικευμένες διαφημίσεις'),
 'sv': ('Ingen reklam', 'Annonsintegritet', 'Se över dina val för anpassade annonser'),
 'da': ('Ingen reklamer', 'Annoncepersondata', 'Gennemgå dine valg om tilpassede annoncer'),
 'nb': ('Ingen reklame', 'Annonsepersonvern', 'Se over valgene dine for tilpassede annonser'),
 'fi': ('Ei mainoksia', 'Mainosten tietosuoja', 'Tarkista valintasi kohdennetuista mainoksista'),
 'is': ('Engar auglýsingar', 'Persónuvernd auglýsinga', 'Farðu yfir val þitt um sérsniðnar auglýsingar'),
 'et': ('Reklaamivaba', 'Reklaamide privaatsus', 'Vaata üle oma valikud isikupärastatud reklaamide kohta'),
 'lv': ('Bez reklāmām', 'Reklāmu privātums', 'Pārskati savas izvēles par personalizētām reklāmām'),
 'lt': ('Be reklamų', 'Reklamų privatumas', 'Peržiūrėk savo pasirinkimus dėl suasmenintų reklamų'),
 'mt': ('Ebda reklami', 'Privatezza tar-reklami', 'Irrevedi l-għażliet tiegħek dwar reklami personalizzati'),
 'ga': ('Gan fógraí', 'Príobháideachas fógraí', 'Athbhreithnigh do roghanna faoi fhógraí pearsantaithe'),
 'ru': ('Без рекламы', 'Конфиденциальность рекламы', 'Проверьте настройки персонализированной рекламы'),
 'uk': ('Без реклами', 'Конфіденційність реклами', 'Перегляньте вибір щодо персоналізованої реклами'),
 'tr': ('Reklamsız', 'Reklam gizliliği', 'Kişiselleştirilmiş reklam tercihlerini gözden geçir'),
 'hi': ('कोई विज्ञापन नहीं', 'विज्ञापन निजता', 'व्यक्तिगत विज्ञापनों के बारे में अपनी पसंद देखें'),
 'id': ('Tanpa iklan', 'Privasi iklan', 'Tinjau pilihan Anda tentang iklan yang dipersonalisasi'),
 'vi': ('Không quảng cáo', 'Quyền riêng tư quảng cáo', 'Xem lại lựa chọn về quảng cáo được cá nhân hóa'),
 'th': ('ไม่มีโฆษณา', 'ความเป็นส่วนตัวของโฆษณา', 'ตรวจสอบตัวเลือกเกี่ยวกับโฆษณาที่ปรับให้เหมาะกับคุณ'),
 'ja': ('広告なし', '広告のプライバシー', 'パーソナライズ広告の設定を確認'),
 'ko': ('광고 없음', '광고 개인정보', '맞춤 광고에 대한 선택 검토'),
 'zh': ('无广告', '广告隐私', '查看你对个性化广告的选择'),
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
