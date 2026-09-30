# 1.5 (seconda parte): camion, bollo, testo Pro aggiornato.
import json, pathlib
S = pathlib.Path(__file__).resolve().parent
L = S.parents[1] / 'assets' / 'l10n'
NEW = ['type.truck', 'type.trucks', 'deadline.tax']
T = {
 'it': ('Camion', 'Camion', 'Bollo auto', 'Furgoni, camion e rimorchi'),
 'en': ('Truck', 'Trucks', 'Road tax', 'Vans, trucks and trailers'),
 'fr': ('Camion', 'Camions', 'Taxe sur le véhicule', 'Fourgons, camions et remorques'),
 'de': ('Lkw', 'Lkw', 'Kfz-Steuer', 'Transporter, Lkw und Anhänger'),
 'es': ('Camión', 'Camiones', 'Impuesto de circulación', 'Furgonetas, camiones y remolques'),
 'hr': ('Kamion', 'Kamioni', 'Porez na vozilo', 'Kombiji, kamioni i prikolice'),
 'pt': ('Camião', 'Camiões', 'Imposto de circulação (IUC)', 'Carrinhas, camiões e reboques'),
 'nl': ('Vrachtwagen', 'Vrachtwagens', 'Motorrijtuigenbelasting', 'Bestelwagens, vrachtwagens en aanhangers'),
 'sv': ('Lastbil', 'Lastbilar', 'Fordonsskatt', 'Skåpbilar, lastbilar och släpvagnar'),
 'da': ('Lastbil', 'Lastbiler', 'Ejerafgift', 'Varevogne, lastbiler og trailere'),
 'nb': ('Lastebil', 'Lastebiler', 'Trafikkforsikringsavgift', 'Varebiler, lastebiler og tilhengere'),
 'fi': ('Kuorma-auto', 'Kuorma-autot', 'Ajoneuvovero', 'Pakettiautot, kuorma-autot ja perävaunut'),
 'is': ('Vörubíll', 'Vörubílar', 'Bifreiðagjald', 'Sendibílar, vörubílar og kerrur'),
 'pl': ('Ciężarówka', 'Ciężarówki', 'Podatek od pojazdu', 'Furgony, ciężarówki i przyczepy'),
 'cs': ('Nákladní auto', 'Nákladní auta', 'Silniční daň', 'Dodávky, nákladní auta a přívěsy'),
 'sk': ('Nákladné auto', 'Nákladné autá', 'Daň z motorových vozidiel', 'Dodávky, nákladné autá a prívesy'),
 'sl': ('Tovornjak', 'Tovornjaki', 'Letna dajatev za vozila', 'Kombiji, tovornjaki in prikolice'),
 'hu': ('Teherautó', 'Teherautók', 'Gépjárműadó', 'Kisteherautók, teherautók és utánfutók'),
 'ro': ('Camion', 'Camioane', 'Impozit auto', 'Dube, camioane și remorci'),
 'bg': ('Камион', 'Камиони', 'Данък МПС', 'Бусове, камиони и ремаркета'),
}
order = S / 'order.txt'
keys = order.read_text().split('\n')[:-1]
bi = keys.index('pro.benefitTypes')
if NEW[0] not in keys:
    keys += NEW
    order.write_text('\n'.join(keys) + '\n')
for lang, (tr1, tr2, tax, ben) in T.items():
    txt = S / f'{lang}.txt'
    if txt.exists():
        lines = txt.read_text(encoding='utf-8').split('\n')
        while lines and lines[-1] == '':
            lines.pop()
        lines[bi] = ben
        if len(lines) == len(keys) - 3:
            lines += [tr1, tr2, tax]
        txt.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    else:
        p = L / f'{lang}.json'
        d = json.loads(p.read_text())
        d.update({'type.truck': tr1, 'type.trucks': tr2, 'deadline.tax': tax, 'pro.benefitTypes': ben})
        p.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
print('ok', len(keys))
