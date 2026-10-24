import re
import sys
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Frame, KeepTogether, NextPageTemplate, PageBreak,
                                PageTemplate, Paragraph, Spacer, Table, TableStyle)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon

import datetime
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / 'tool' / 'architettura' / 'MyFleetManager_Architettura.pdf')
_ver = re.search(r'^version:\s*([0-9.]+)\+(\d+)', (ROOT / 'pubspec.yaml').read_text(), re.M)
VERSION, BUILD = _ver.group(1), _ver.group(2)
MESI = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre',
        'novembre', 'dicembre']
_today = datetime.date.today()
DATA = '%s %d' % (MESI[_today.month - 1].capitalize(), _today.year)
DART = sorted((ROOT / 'lib').rglob('*.dart'))


def righe(*nomi):
    n = sum(len((ROOT / 'lib' / x).read_text(encoding='utf-8').splitlines()) for x in nomi)
    return '{:,}'.format(n).replace(',', '.')


TOT_RIGHE = sum(len(f.read_text(encoding='utf-8').splitlines()) for f in DART)
N_CHIAVI = len(json.loads((ROOT / 'assets' / 'l10n' / 'it.json').read_text(encoding='utf-8')))
N_LINGUE = len(list((ROOT / 'assets' / 'l10n').glob('*.json')))
F = '/usr/share/fonts/truetype/dejavu/'
pdfmetrics.registerFont(TTFont('DV', F + 'DejaVuSans.ttf'))
pdfmetrics.registerFont(TTFont('DVB', F + 'DejaVuSans-Bold.ttf'))
pdfmetrics.registerFont(TTFont('DVM', F + 'DejaVuSansMono.ttf'))
from reportlab.pdfbase.pdfmetrics import registerFontFamily
registerFontFamily('DV', normal='DV', bold='DVB', italic='DV', boldItalic='DVB')

BLUE = colors.HexColor('#0257C3')
DARK = colors.HexColor('#1B2430')
GREY = colors.HexColor('#5F6B7A')
LIGHT = colors.HexColor('#EEF3FB')
LINE = colors.HexColor('#C9D3E0')

ss = getSampleStyleSheet()
body = ParagraphStyle('body', parent=ss['Normal'], fontName='DV', fontSize=9.6, leading=13.6, textColor=DARK,
                      spaceAfter=5)
small = ParagraphStyle('small', parent=body, fontSize=8.4, leading=11.2, spaceAfter=0)
cell = ParagraphStyle('cell', parent=body, fontSize=8.4, leading=11, spaceAfter=0)
cellb = ParagraphStyle('cellb', parent=cell, fontName='DVB')
h1 = ParagraphStyle('h1', parent=body, fontName='DVB', fontSize=17, leading=21, textColor=BLUE, spaceBefore=4,
                    spaceAfter=10)
h2 = ParagraphStyle('h2', parent=body, fontName='DVB', fontSize=12.2, leading=16, textColor=DARK, spaceBefore=10,
                    spaceAfter=5)
h3 = ParagraphStyle('h3', parent=body, fontName='DVB', fontSize=10.2, leading=14, textColor=BLUE, spaceBefore=7,
                    spaceAfter=3)
bullet = ParagraphStyle('bullet', parent=body, leftIndent=12, bulletIndent=2, spaceAfter=2.5)
mono = ParagraphStyle('mono', parent=cell, fontName='DVM', fontSize=7.8)
cap = ParagraphStyle('cap', parent=small, textColor=GREY, alignment=TA_CENTER, spaceBefore=3, spaceAfter=8)


class Doc(BaseDocTemplate):
    def afterFlowable(self, f):
        if isinstance(f, Paragraph) and f.style.name in ('h1', 'h2') and f.getPlainText() != 'Sommario':
            lvl = 0 if f.style.name == 'h1' else 1
            key = 'k%d' % id(f)
            self.canv.bookmarkPage(key)
            self.notify('TOCEntry', (lvl, f.getPlainText(), self.page, key))
            self.canv.addOutlineEntry(f.getPlainText(), key, lvl, closed=lvl > 0)


def deco(c, d):
    c.saveState()
    c.setStrokeColor(LINE)
    c.setLineWidth(0.6)
    c.line(18 * mm, 284 * mm, 192 * mm, 284 * mm)
    c.setFont('DV', 7.6)
    c.setFillColor(GREY)
    c.drawString(18 * mm, 286 * mm, 'MyFleetManager %s · Architettura software e funzioni' % VERSION)
    c.drawRightString(192 * mm, 12 * mm, 'Pagina %d' % d.page)
    c.restoreState()


def cover(c, d):
    c.saveState()
    c.setFillColor(BLUE)
    c.rect(0, 0, 210 * mm, 297 * mm, fill=1, stroke=0)
    c.setFillColor(colors.HexColor('#0B4AA0'))
    for i in range(0, 30):
        c.circle(20 * mm, (20 + i * 9) * mm, 2.2 * mm, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont('DVB', 34)
    c.drawString(40 * mm, 200 * mm, 'MyFleetManager')
    c.setFont('DV', 17)
    c.drawString(40 * mm, 188 * mm, 'Architettura software, moduli e funzioni')
    c.setFont('DV', 11)
    c.setFillColor(colors.HexColor('#D6E4FA'))
    c.drawString(40 * mm, 174 * mm, 'Documento tecnico e funzionale · versione app %s (build %s)' % (VERSION, BUILD))
    c.drawString(40 * mm, 167 * mm, DATA)
    c.setFont('DV', 9)
    lines = [
        'Contenuto: architettura a livelli, moduli e loro interfacce, modello dei dati,',
        'flussi principali, schermate, impostazioni e opzioni per l\'utente,',
        'differenze tra versione gratuita e Pro, cloud, sicurezza, build e rilascio.',
    ]
    for i, t in enumerate(lines):
        c.drawString(40 * mm, (60 - i * 5.5) * mm, t)
    c.restoreState()


def P(t, s=body):
    return Paragraph(t, s)


def B(items):
    return [Paragraph(t, bullet, bulletText='•') for t in items]


def table(rows, widths, head=True, zebra=True, style=cell):
    data = []
    for r_i, r in enumerate(rows):
        data.append([c if not isinstance(c, str) else Paragraph(c, cellb if (head and r_i == 0) else style)
                     for c in r])
    t = Table(data, colWidths=widths, repeatRows=1 if head else 0)
    st = [
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.4, LINE),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]
    if head:
        st.append(('BACKGROUND', (0, 0), (-1, 0), LIGHT))
    if zebra:
        for i in range(2 if head else 1, len(rows), 2):
            st.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor('#FAFBFD')))
    t.setStyle(TableStyle(st))
    return t


def box(d, x, y, w, h, title, sub='', fill=LIGHT, stroke=BLUE, tc=DARK):
    d.add(Rect(x, y, w, h, rx=4, ry=4, fillColor=fill, strokeColor=stroke, strokeWidth=0.8))
    d.add(String(x + w / 2, y + h - 12, title, fontName='DVB', fontSize=8.2, fillColor=tc, textAnchor='middle'))
    if sub:
        for i, s in enumerate(sub.split('\n')):
            d.add(String(x + w / 2, y + h - 23 - i * 9, s, fontName='DV', fontSize=6.6, fillColor=GREY,
                         textAnchor='middle'))


def arrow(d, x1, y1, x2, y2, col=GREY):
    d.add(Line(x1, y1, x2, y2, strokeColor=col, strokeWidth=0.8))
    import math
    a = math.atan2(y2 - y1, x2 - x1)
    l = 5
    p1 = (x2 - l * math.cos(a - 0.4), y2 - l * math.sin(a - 0.4))
    p2 = (x2 - l * math.cos(a + 0.4), y2 - l * math.sin(a + 0.4))
    d.add(Polygon([x2, y2, p1[0], p1[1], p2[0], p2[1]], fillColor=col, strokeColor=col))


def layers():
    W, H = 480, 330
    d = Drawing(W, H)
    bands = [
        (262, 'INTERFACCIA (lib/screens, lib/widgets)', colors.HexColor('#E7F0FD')),
        (182, 'STATO DELL\'APP (lib/services/app_state.dart)', colors.HexColor('#FFF4DA')),
        (88, 'SERVIZI (lib/services)', colors.HexColor('#E8F5EA')),
        (6, 'PIATTAFORMA E CLOUD', colors.HexColor('#F2ECF9')),
    ]
    hs = [62, 72, 86, 74]
    for (y, t, c), hh in zip(bands, hs):
        d.add(Rect(0, y, W, hh, fillColor=c, strokeColor=LINE, strokeWidth=0.5))
        d.add(String(6, y + hh - 10, t, fontName='DVB', fontSize=7.2, fillColor=GREY))
    ui = ['Home', 'Scheda veicolo', 'Modifica', 'Gruppi', 'Impostazioni', 'Login / Pro']
    for i, t in enumerate(ui):
        box(d, 8 + i * 78.5, 268, 72, 34, t, '', colors.white)
    box(d, 120, 192, 240, 46, 'AppState (ChangeNotifier)', 'sessione · dati utente · tema · Pro\nregole di permesso · orchestrazione',
        colors.white, colors.HexColor('#C99400'))
    sv = [('LocalStore', 'file JSON'), ('AuthService', 'accesso'), ('SyncService', 'Firestore'),
          ('Notification', 'promemoria'), ('PushService', 'FCM'), ('ProService', 'acquisti'),
          ('GroupWatch', 'background'), ('Registration', 'lettura libretto'), ('DocCloud', 'compressione'),
          ('PdfExport', 'riepilogo'), ('Update', 'aggiornamenti'), ('Support', 'email')]
    for i, (t, s) in enumerate(sv):
        col, row = i % 6, i // 6
        box(d, 8 + col * 78.5, 136 - row * 42, 72, 36, t, s, colors.white, colors.HexColor('#3C8D4A'))
    pf = [('Telefono', 'file e documenti'), ('Firebase Auth', 'email/Google/Apple'), ('Firestore', 'dati condivisi'),
          ('FCM', 'notifiche push'), ('Play / App Store', 'acquisto Pro'), ('Android / iOS', 'sveglie, ML Kit,\nWorkManager')]
    for i, (t, s) in enumerate(pf):
        tt = t.split('\n')
        box(d, 8 + i * 78.5, 14, 72, 48, tt[0], (tt[1] + '\n' if len(tt) > 1 else '') + s, colors.white,
            colors.HexColor('#7B4FB8'))
    arrow(d, 240, 266, 240, 239)
    arrow(d, 240, 191, 240, 175)
    arrow(d, 240, 92, 240, 64)
    return d


def nav():
    W, H = 480, 250
    d = Drawing(W, H)
    box(d, 190, 214, 100, 30, 'Intro animata', '', colors.white)
    box(d, 170, 168, 140, 30, 'Login', 'locale · email · Google · Apple', colors.white)
    box(d, 180, 112, 120, 38, 'Home (3 schede)', 'Veicoli · Gruppi · Scadenze', LIGHT)
    box(d, 8, 112, 120, 38, 'Impostazioni', 'notifiche · aspetto · gruppi\naccount · supporto', colors.white)
    box(d, 352, 112, 120, 38, 'Pro', 'acquisto · ripristino', colors.white)
    box(d, 8, 40, 110, 46, 'Scheda veicolo', 'Scadenze · Dati tecnici\nManutenzioni', colors.white)
    box(d, 128, 40, 100, 46, 'VehicleBook', 'sfoglia i veicoli\ncome pagine', colors.white)
    box(d, 238, 40, 100, 46, 'Modifica veicolo', 'dati, foto, pneumatici\nscadenze, note', colors.white)
    box(d, 348, 40, 124, 46, 'Gruppo', 'membri, ruoli, QR\ncondivisione documenti', colors.white)
    box(d, 8, 0, 110, 30, 'Manutenzione', 'nuova / modifica', colors.white)
    box(d, 128, 0, 100, 30, 'Lettura libretto', 'OCR + Assegna a…', colors.white)
    box(d, 238, 0, 100, 30, 'Ritaglio foto', '', colors.white)
    box(d, 348, 0, 124, 30, 'Amministrazione', 'da Impostazioni, solo admin', colors.white)
    arrow(d, 240, 214, 240, 199)
    arrow(d, 240, 168, 240, 151)
    arrow(d, 180, 131, 129, 131)
    arrow(d, 300, 131, 351, 131)
    arrow(d, 210, 112, 70, 87)
    arrow(d, 230, 112, 178, 87)
    arrow(d, 250, 112, 288, 87)
    arrow(d, 270, 112, 410, 87)
    arrow(d, 63, 40, 63, 31)
    arrow(d, 100, 40, 160, 31)
    arrow(d, 288, 40, 288, 31)
    return d


def sync_diagram():
    W, H = 480, 170
    d = Drawing(W, H)
    box(d, 0, 100, 110, 50, 'Telefono A', 'AppState + LocalStore', colors.white)
    box(d, 370, 100, 110, 50, 'Telefono B', 'AppState + LocalStore', colors.white)
    box(d, 160, 96, 160, 60, 'Cloud Firestore', 'fleets/{gruppo}/vehicles\nfleets/{gruppo}/docs\nusers/{uid} · pro/{uid}',
        colors.HexColor('#F2ECF9'), colors.HexColor('#7B4FB8'))
    arrow(d, 111, 132, 159, 132)
    arrow(d, 321, 120, 369, 120)
    arrow(d, 159, 116, 111, 116)
    arrow(d, 369, 136, 321, 136)
    d.add(String(135, 138, 'scrive', fontName='DV', fontSize=6.6, fillColor=GREY, textAnchor='middle'))
    d.add(String(135, 106, 'ascolta', fontName='DV', fontSize=6.6, fillColor=GREY, textAnchor='middle'))
    d.add(String(345, 142, 'scrive', fontName='DV', fontSize=6.6, fillColor=GREY, textAnchor='middle'))
    d.add(String(345, 110, 'ascolta', fontName='DV', fontSize=6.6, fillColor=GREY, textAnchor='middle'))
    box(d, 160, 20, 160, 46, 'GroupWatch (Android)', 'controllo ogni ~15 min ad app chiusa\navvisa le attività del gruppo',
        colors.HexColor('#E8F5EA'), colors.HexColor('#3C8D4A'))
    arrow(d, 240, 67, 240, 95)
    box(d, 0, 20, 130, 46, 'Notifiche locali', 'scadenze programmate\nsul telefono, anche offline', colors.white)
    box(d, 350, 20, 130, 46, 'Push (FCM)', 'campagne e avvisi\ndalla console Firebase', colors.white)
    arrow(d, 55, 99, 55, 67)
    arrow(d, 425, 67, 425, 99)
    return d


story = []
story.append(NextPageTemplate('normal'))
story.append(PageBreak())

toc = TableOfContents()
toc.levelStyles = [
    ParagraphStyle('t0', parent=body, fontName='DVB', fontSize=9.6, leading=13, leftIndent=0, spaceBefore=3, spaceAfter=0),
    ParagraphStyle('t1', parent=body, fontSize=8.4, leading=11, leftIndent=14, spaceAfter=0),
]
story += [P('Sommario', h1), toc, PageBreak()]

story += [P('1. Introduzione', h1)]
story += [P('MyFleetManager è un\'app per Android (e in preparazione per iPhone) che raccoglie in un «quaderno» digitale i veicoli '
            'di una persona, di una famiglia o di una piccola flotta: scadenze (assicurazione, bollo, revisione, tagliando e '
            'personalizzate), promemoria, documenti, dati tecnici e storico delle manutenzioni. I veicoli possono essere '
            'condivisi in gruppi con ruoli diversi.')]
story += [P('Questo documento descrive come è costruita l\'app: i livelli dell\'architettura, ogni modulo con le sue '
            'responsabilità, le interfacce tra un modulo e l\'altro, il modello dei dati, i flussi principali e tutte le '
            'impostazioni, opzioni e possibilità offerte all\'utente.')]
story += [P('Dati principali', h3)]
story += [table([
    ['Voce', 'Valore'],
    ['Versione descritta', '%s (build %s)' % (VERSION, BUILD)],
    ['Tecnologia', 'Flutter 3.38 (linguaggio Dart), un solo codice per Android e iOS'],
    ['Cloud', 'Google Firebase: Authentication, Cloud Firestore, Cloud Messaging (piano gratuito Spark)'],
    ['Dimensione del codice', 'circa %s righe in %d file Dart sotto lib/' % ('{:,}'.format(round(TOT_RIGHE, -2)).replace(',', '.'), len(DART))],
    ['Lingue', '%d, con' % N_LINGUE + ' scelta automatica dalla lingua del telefono'],
    ['Piattaforme', 'Android (Google Play, APK diretto); web nel browser di PC e Mac (in prova); iOS compilato in prova, in attesa dell\'account sviluppatore Apple'],
    ['Modello commerciale', 'App gratuita con acquisto unico in-app «Pro» (prodotto myfleet_pro), nessun abbonamento'],
], [45 * mm, 125 * mm])]

story += [PageBreak(), P('2. Architettura generale', h1)]
story += [P('L\'app è organizzata in quattro livelli. Ogni livello usa solo quello immediatamente sotto: le schermate non '
            'parlano direttamente con Firebase o con i file, ma passano sempre dallo stato centrale (AppState), che a sua '
            'volta usa i servizi.')]
story += [layers(), P('Figura 1 – Livelli dell\'architettura e moduli principali', cap)]
story += B([
    '<b>Interfaccia</b>: schermate (lib/screens) e componenti riutilizzabili (lib/widgets). Disegnano il quaderno, ricevono '
    'i tocchi e chiamano i metodi di AppState.',
    '<b>Stato</b>: AppState è un unico oggetto osservabile (ChangeNotifier) raggiungibile da tutta l\'app come '
    '<font name="DVM">appState</font>. Contiene la sessione, i dati dell\'utente, il tema, lo stato Pro e le regole sui '
    'permessi; quando qualcosa cambia avvisa le schermate, che si ridisegnano da sole.',
    '<b>Servizi</b>: classi con un compito preciso (salvare i file, sincronizzare, programmare le notifiche, leggere il libretto…). '
    'Non conoscono le schermate.',
    '<b>Piattaforma e cloud</b>: memoria del telefono, Firebase, negozi di app, funzioni del sistema operativo '
    '(sveglie, riconoscimento testo ML Kit, lavori in background).',
])
story += [P('Principi di progetto', h3)]
story += B([
    '<b>Prima il telefono</b>: tutti i dati sono salvati in locale e l\'app funziona anche senza rete; il cloud serve per '
    'condividere e per avere i dati su più telefoni.',
    '<b>Un solo punto di verità</b>: ogni modifica passa da AppState, che salva in locale, invia al cloud e riprogramma le notifiche.',
    '<b>Nessun server proprio</b>: la logica gira sull\'app; il cloud è solo Firebase, protetto dalle regole di sicurezza Firestore.',
    '<b>Riservatezza</b>: la lettura del libretto avviene sul telefono; i documenti vanno online solo con il consenso dell\'utente.',
])

story += [PageBreak(), P('3. Struttura del codice', h1)]
story += [P('Elenco dei file sorgente con il loro ruolo. Le righe sono indicative e servono a dare l\'idea del peso di ogni parte.')]
files = [
    ['File', 'Righe', 'Ruolo'],
    ['main.dart', righe('main.dart'), 'Avvio: Firebase, lingua, tema, orientamento (telefoni in verticale), scala dei testi sui tablet, scelta tra intro, login e home'],
    ['models.dart', righe('models.dart'), 'Modello dei dati: veicolo, scadenze, manutenzioni, documenti, gruppi, preferiti, impostazioni notifiche, sessione'],
    ['platform.dart', righe('platform.dart'), 'Riconosce la piattaforma (Android, iPhone, browser) in modo sicuro anche sul web'],
    ['units.dart', righe('units.dart'), 'Unità di misura scelte dall\'utente: potenza (kW, CV o entrambe, con conversione automatica), distanze (km o miglia, salvate sempre in km), valuta (automatica dal telefono o scelta); formato degli importi'],
    ['l10n.dart', righe('l10n.dart'), 'Traduzioni: caricamento del file della lingua, funzione tr() con segnaposti e plurali'],
    ['theme.dart', righe('theme.dart'), 'Tema «quaderno»: colori copertina, carta (righe, quadretti, puntini, liscia), anelli, scala testi; tema calcolato una volta sola e riutilizzato (evita il lampeggio delle icone in alto)'],
    ['firebase_config.dart · version.dart', righe('firebase_config.dart', 'version.dart'), 'Parametri pubblici del progetto Firebase e numero di versione'],
    ['services/app_state.dart', righe('services/app_state.dart'), 'Stato centrale e orchestrazione di tutti i servizi'],
    ['services/local_store.dart', righe('services/local_store.dart'), 'Lettura e scrittura dei file JSON sul telefono (sessione, dati, impostazioni, storico notifiche)'],
    ['services/auth_service.dart', righe('services/auth_service.dart'), 'Accesso: account locale, email e password, Google, Apple; eliminazione account'],
    ['services/sync_service.dart', righe('services/sync_service.dart'), 'Sincronizzazione con Firestore: gruppi (ascolto continuo più lettura diretta dal server all\'avvio e a ogni «aggiorna»), veicoli, documenti, ruoli, Pro; registra i problemi per fonte (gruppi, veicoli, documenti, salvataggi) e li toglie quando la fonte torna a funzionare'],
    ['services/notification_service.dart', righe('services/notification_service.dart'), 'Promemoria delle scadenze programmati sul telefono, canali Android, prove'],
    ['services/push_service.dart', righe('services/push_service.dart'), 'Registrazione del telefono a Firebase Cloud Messaging'],
    ['services/app_check.dart', righe('services/app_check.dart'), 'Avvio di Firebase App Check (Play Integrity su Android, App Attest su iOS): certifica che le richieste al cloud arrivano dall\'app originale'],
    ['services/group_watch.dart', righe('services/group_watch.dart'), 'Controllo in background delle attività dei gruppi (Android, WorkManager) e registrazione nello storico'],
    ['services/notification_log.dart', righe('services/notification_log.dart'), 'Storico delle notifiche: voci, unione per veicolo, parti cambiate, lette e cancellate'],
    ['services/pro_service.dart', righe('services/pro_service.dart'), 'Acquisto in-app della versione Pro e ripristino'],
    ['services/registration_reader.dart', righe('services/registration_reader.dart'), 'Lettura del libretto: riconoscimento testo e interpretazione dei campi UE'],
    ['services/tyres.dart', righe('services/tyres.dart'), 'Pneumatici: riconoscimento misure, gruppi, divisione per cerchio'],
    ['services/doc_cloud.dart', righe('services/doc_cloud.dart'), 'Compressione dei documenti per la copia online (JPEG ≤ 700 KB)'],
    ['services/pdf_export.dart', righe('services/pdf_export.dart'), 'Esportazione del riepilogo in PDF'],
    ['services/update_service.dart', righe('services/update_service.dart'), 'Aggiornamenti automatici da Google Play'],
    ['services/support_service.dart', righe('services/support_service.dart'), 'Email al supporto, segnalazione problemi, richiesta cancellazione dati'],
    ['screens/home_screen.dart', righe('screens/home_screen.dart'), 'Schermata principale con le tre schede in basso; icona PDF in alto nei Veicoli e nei Gruppi (scelta tra tutti i gruppi o uno solo); campanella delle notifiche con il numero delle non lette'],
    ['screens/notifications_screen.dart', righe('screens/notifications_screen.dart'), 'Pagina Notifiche: storico diviso per giorno, segna come lette, elimina, selezione con pressione lunga; campanella con contatore'],
    ['screens/vehicle_detail_screen.dart', righe('screens/vehicle_detail_screen.dart'), 'Scheda del veicolo con le tre sotto-schede'],
    ['screens/vehicle_book.dart', righe('screens/vehicle_book.dart'), 'Sfoglia i veicoli con l\'animazione della pagina attorno agli anelli'],
    ['screens/vehicle_edit_screen.dart', righe('screens/vehicle_edit_screen.dart'), 'Creazione e modifica del veicolo'],
    ['screens/maintenance_screen.dart', righe('screens/maintenance_screen.dart'), 'Nuova manutenzione o modifica: interventi, ricambi liberi, codici, costi, manodopera e totale'],
    ['screens/family_screen.dart', righe('screens/family_screen.dart'), 'Scheda Gruppi, schermata del gruppo, spostamento veicoli'],
    ['screens/settings_screen.dart', righe('screens/settings_screen.dart'), 'Impostazioni, compresa la sezione «Unità di misura»'],
    ['screens/login_screen.dart', righe('screens/login_screen.dart'), 'Accesso e registrazione; in alto lo slogan «La tua flotta nel palmo della mano» e le quattro funzioni principali (Scadenze, Documenti, Manutenzioni, Gruppi)'],
    ['screens/pro_screen.dart', righe('screens/pro_screen.dart'), 'Presentazione e acquisto della versione Pro'],
    ['screens/web_pro_gate.dart', righe('screens/web_pro_gate.dart'), 'Versione web: pagina per chi accede senza la Pro'],
    ['screens/intro_screen.dart', righe('screens/intro_screen.dart'), 'Animazione iniziale con logo e slogan'],
    ['screens/photo_crop_screen.dart', righe('screens/photo_crop_screen.dart'), 'Ritaglio della foto del veicolo'],
    ['screens/admin_screen.dart', righe('screens/admin_screen.dart'), 'Pannello di amministrazione (solo account amministratore)'],
    ['widgets/common.dart', righe('widgets/common.dart'), 'Componenti comuni: card del veicolo, avvisi, stella dei preferiti, stati delle scadenze, formato e lettura degli importi, nome dell app in Lobster e slogan in corsivo anni 50 (Lobster Two) su due righe bilanciate'],
    ['widgets/ruled.dart', righe('widgets/ruled.dart'), 'Allineamento dei testi alle righe del quaderno'],
    ['widgets/group_qr.dart', righe('widgets/group_qr.dart'), 'QR code di invito con logo, scansione e lettura da immagine'],
    ['widgets/ocr_review.dart', righe('widgets/ocr_review.dart'), 'Finestra compatta (titolo su una riga, avviso ridotto, Annulla e Salva affiancati, «Testo letto» come collegamento) — Finestra «Dati trovati», testo letto e «Assegna a…»'],
    ['widgets/docs_consent.dart', righe('widgets/docs_consent.dart'), 'Richiesta di consenso per i documenti online'],
]
_noti = {r[0] for r in files[1:]} | {'firebase_config.dart', 'version.dart'}
_mancanti = [str(f.relative_to(ROOT / 'lib')) for f in DART if str(f.relative_to(ROOT / 'lib')) not in _noti]
if _mancanti:
    raise SystemExit('File non descritti nel documento: ' + ', '.join(_mancanti))
story += [table(files, [58 * mm, 13 * mm, 99 * mm]), Spacer(1, 6)]
story += [P('Fuori da lib/ si trovano: <font name="DVM">tool/</font> (script di preparazione Android e iOS, traduzioni, '
            'test, screenshot e materiale per gli store), <font name="DVM">docs/</font> (informativa privacy e pagina di invito ai '
            'gruppi, pubblicate insieme al sito su Firebase Hosting), <font name="DVM">firestore.rules</font> (regole di sicurezza del cloud) e '
            '<font name="DVM">.github/workflows</font> (compilazione automatica).', small)]

story += [PageBreak(), P('4. Modello dei dati', h1)]
story += [P('Tutti i dati sono oggetti Dart convertibili in JSON (metodi toJson/fromJson). Lo stesso formato è usato per i '
            'file sul telefono e per i documenti in Firestore. I campi nuovi vengono aggiunti in modo compatibile: un dato '
            'mancante assume un valore predefinito.')]
story += [P('Vehicle – veicolo', h2)]
story += [table([
    ['Campo', 'Contenuto'],
    ['id, fleetId', 'Identificativo e gruppo di appartenenza (vuoto o gruppo personale = «I miei veicoli»)'],
    ['type', 'Auto, moto, furgone, camion, rimorchio, veicolo agricolo'],
    ['name, plate, photoB64', 'Nome, targa, foto (compressa e codificata nel dato)'],
    ['registrationDate', 'Data di immatricolazione (base per il calcolo della revisione)'],
    ['deadlines', 'Elenco delle scadenze (vedi sotto)'],
    ['documents', 'Elenco dei documenti allegati (libretto, polizza…)'],
    ['maintenance', 'Storico delle manutenzioni (interventi, ricambi con codice e costo, manodopera)'],
    ['vin, powerKw, engineCc', 'Telaio, potenza (sempre salvata in kW, mostrata nell\'unità scelta), cilindrata'],
    ['tyres', 'Pneumatici: una riga per gruppo, es. «Anteriori: 225/40 R19 89W»'],
    ['fuel, oil, battery, plugs, filters', 'Alimentazione, olio motore, batteria, candele/candelette, codici filtri (dalla 2.1)'],
    ['notes', 'Note libere'],
    ['createdBy, createdAt, updatedAt, updatedBy, deleted', 'Proprietario, date e autore delle modifiche, cancellazione logica per la sincronizzazione'],
], [52 * mm, 118 * mm])]
story += [P('Altri oggetti', h2)]
story += [table([
    ['Oggetto', 'Contenuto e regole'],
    ['Deadline', 'Tipo (assicurazione, revisione, tagliando, bollo, personalizzata), attiva sì/no, data, etichetta. '
                 'La revisione si calcola dall\'immatricolazione; il tagliando si aggiorna con le manutenzioni marcate «conta come tagliando».'],
    ['MaintenanceRecord', 'Data, chilometri, interventi (olio motore, filtro olio, aria, abitacolo, carburante o voci libere), note.'],
    ['VehicleDocument', 'Nome, tipo (immagine/PDF), dimensione, data; stato online (cloud), autore, dimensione della copia online.'],
    ['FleetGroup', 'Gruppo: nome, proprietario, membri con email, amministratori, sola visualizzazione, condivisione documenti sì/no.'],
    ['GroupRole', 'Amministratore · Può modificare · Solo visualizzazione.'],
    ['NotifySettings', 'Anticipi dei promemoria (30, 7, 1, 0 giorni) e orario (predefinito 9:00).'],
    ['Favorites', 'Preferiti attivi sì/no, vista iniziale (Tutti / Preferiti), veicoli, gruppi interi ed esclusioni.'],
    ['UserData', 'Insieme dei dati di un account: veicoli, gruppi, impostazioni notifiche, preferiti.'],
    ['Session', 'Account attivo: modalità (locale o online), identificativo, nome visualizzato, email.'],
    ['TyreSet', 'Gruppo di pneumatici (nome + misure), con riconoscimento automatico delle misure e divisione per cerchio.'],
    ['RegistrationData', 'Dati letti dal libretto: targa, immatricolazione, telaio, potenza, cilindrata, pneumatici.'],
], [36 * mm, 134 * mm])]

story += [PageBreak(), P('5. I moduli e le loro interfacce', h1)]
story += [P('Per ogni modulo: a cosa serve, cosa offre agli altri moduli (interfaccia) e di chi ha bisogno (dipendenze).')]


def module(name, what, offers, uses):
    return KeepTogether([P(name, h2), P(what), table([
        ['Offre (metodi principali)', 'Usa'],
        [offers, uses],
    ], [110 * mm, 60 * mm], zebra=False)])


story += [module('AppState – stato centrale', 'Cuore dell\'app. Tiene in memoria sessione, dati e impostazioni, applica le regole '
                 '(limite della versione gratuita, permessi nei gruppi, Pro) e coordina tutti i servizi. Ogni schermata lo osserva.',
                 'avvio e apertura sessione · login/logout · saveVehicle, deleteVehicle, spostamento tra gruppi · documenti '
                 '(aggiunta, rinomina, eliminazione, copia online) · createGroup, joinGroup, ruoli, assegnazione proprietario · '
                 'impostazioni notifiche e tema · preferiti (toggleFavorite, toggleFavoriteGroup, setHomeView) · isPro, '
                 'canEdit, canAddVehicle, limitedIds · elenchi (myVehicles, homeVehicles, groupVehicles, activeVehicles)',
                 'LocalStore, AuthService, SyncService, NotificationService, PushService, ProService, GroupWatch, '
                 'DocCloud, UpdateService')]
story += [module('LocalStore – memoria del telefono', 'Salva tutto in file JSON nella cartella privata dell\'app: elenco account, '
                 'sessione attiva, dati di ogni account, impostazioni generali e cartella dei documenti. '
                 'Nel browser usa la memoria del browser.',
                 'readSession / writeSession · readUserData / writeUserData / deleteUserData · readSettings / writeSettings · '
                 'writeAccounts · docsDir', 'File system del telefono (path_provider), memoria del browser (shared_preferences)')]
story += [module('AuthService – accesso', 'Gestisce gli account: «solo su questo telefono» (protetto da password con hash), '
                 'online con email e password, con Google e con Apple. Si occupa anche del reset password e della '
                 'cancellazione dell\'account.',
                 'registerLocal · loginLocal · registerCloud · loginCloud · loginGoogle · loginApple · resetPassword · '
                 'deleteCloudAccount · logout · appleAvailable', 'Firebase Authentication, Google Sign-In, Sign in with Apple')]
story += [module('SyncService – sincronizzazione', 'Collega l\'app a Cloud Firestore: crea il gruppo personale, crea ed entra '
                 'nei gruppi, ascolta in tempo reale i veicoli e i documenti dei gruppi, scrive le modifiche, gestisce ruoli, '
                 'condivisione documenti e registro Pro.',
                 'ensurePersonal · createGroup · joinGroup · leaveGroup · removeMember · setRole · renameGroup · deleteGroup · '
                 'reassignVehicle · uploadDoc / downloadDoc / renameDoc / deleteDoc · setShareDocs · registerPro / endPro · '
                 'checkUnlockCode · deleteAllData · stream dei gruppi, veicoli e documenti',
                 'Cloud Firestore')]
story += [module('NotificationService – promemoria', 'Programma sul telefono le notifiche delle scadenze, anche ad app chiusa e '
                 'senza rete. Raggruppa più scadenze dello stesso giorno, usa l\'orario preciso quando Android lo permette.',
                 'init · rescheduleAll(veicoli, impostazioni) · status (permessi, orario preciso) · requestPermission · '
                 'requestExactAlarms · scheduleTest · showTest · showRemote · showGroup (una notifica per gruppo che si '
                 'aggiorna, con elenco delle modifiche) · firedReminders (promemoria già scattati, per lo storico)',
                 'flutter_local_notifications, fuso orario del telefono')]
story += [module('NotificationLog – storico delle notifiche', 'Storico sul telefono, per account, di tutte le notifiche: '
                 'modifiche dei gruppi, promemoria delle scadenze e messaggi push. Le modifiche dello stesso veicolo fatte '
                 'dalla stessa persona si uniscono finché non sono lette, con le parti cambiate (dati, dati tecnici, '
                 'scadenze, manutenzione, documenti).',
                 'LogEntry · NotificationLog (addActivity, addReminder, addMessage, markRead, markAllRead, delete, clear, '
                 'unread, changedUnread) · changedParts', 'LocalStore (notif_<account>.json)')]
story += [module('PushService – notifiche push', 'Registra il telefono a Firebase Cloud Messaging e salva il codice del '
                 'dispositivo nel profilo; mostra le push ricevute ad app aperta.',
                 'start(uid, onForeground) · stop · registered · token', 'Firebase Messaging, Firestore (users/{uid})')]
story += [module('GroupWatch – attività dei gruppi in background', 'Solo Android: ogni circa 15 minuti, ad app chiusa, controlla '
                 'se altri membri hanno aggiunto, modificato o eliminato veicoli e mostra un avviso. Per l\'amministratore '
                 'segnala anche le nuove attivazioni Pro con codice.',
                 'scheduleGroupWatch(on) · initGroupWatch · findActivities · recordActivities · recordReminders',
                 'WorkManager, Firestore, NotificationService, NotificationLog, LocalStore')]
story += [module('ProService – acquisto Pro', 'Gestisce l\'acquisto unico «myfleet_pro» tramite Google Play (e App Store). '
                 'Su Android ripristina in automatico gli acquisti all\'avvio; su iPhone solo su richiesta, per non chiedere '
                 'ogni volta la password Apple.',
                 'init · buy · restore · prezzo localizzato', 'in_app_purchase')]
story += [module('RegistrationReader e TyreSet – lettura del libretto', 'Riconosce il testo della foto o del PDF del libretto '
                 'direttamente sul telefono e ricava i campi con i codici europei: (A) targa, (B) immatricolazione, (E) telaio, '
                 '(P.1) cilindrata, (P.2) potenza, più le misure dei pneumatici. Gestisce anche i libretti vecchi (solo anno, '
                 'telaio corto, pneumatici in pollici). L\'utente può assegnare a mano un testo selezionato a un campo.',
                 'readText(file) · parse(testo) · propose(campo, testo) · apply(dati, campo, valore) · TyreSet.findSizes / byRim / parse / format',
                 'Google ML Kit (riconoscimento testo), printing (pagine PDF)')]
story += [module('DocCloud, PdfExport, UpdateService, SupportService', 'Servizi di supporto. DocCloud comprime foto e prima '
                 'pagina dei PDF per la copia online. PdfExport crea il riepilogo stampabile. UpdateService propone gli '
                 'aggiornamenti da Google Play. SupportService prepara le email al supporto.',
                 'DocCloud.compress · PdfExport.build(titolo, veicoli) · UpdateService.start / check · SupportService.openEmail',
                 'image, pdf, printing, in_app_update, url_launcher')]

story += [PageBreak(), P('6. Interfacce tra i moduli', h1)]
story += [P('La tabella riassume chi chiama chi e perché. Le frecce vanno sempre dall\'alto verso il basso: interfaccia → '
            'stato → servizi → piattaforma.')]
story += [table([
    ['Da', 'A', 'Interfaccia', 'Scopo'],
    ['Schermate', 'AppState', 'metodi pubblici + ascolto (ListenableBuilder)', 'leggere i dati e chiedere modifiche; ridisegno automatico'],
    ['AppState', 'LocalStore', 'read/write*', 'salvare ogni modifica sul telefono'],
    ['AppState', 'AuthService', 'login*/register*/logout', 'aprire e chiudere la sessione'],
    ['AppState', 'SyncService', 'scritture + stream', 'inviare modifiche e ricevere quelle degli altri membri'],
    ['AppState', 'NotificationService', 'rescheduleAll', 'riprogrammare i promemoria dopo ogni modifica (con ritardo di 0,8 s)'],
    ['AppState', 'PushService', 'start/stop', 'registrare il telefono per le push'],
    ['AppState', 'ProService', 'buy/restore + callback', 'sbloccare la versione Pro'],
    ['AppState', 'GroupWatch', 'scheduleGroupWatch, stato condiviso', 'attivare il controllo in background e segnare le attività già viste'],
    ['AppState', 'DocCloud', 'compress', 'preparare la copia online dei documenti'],
    ['Scheda veicolo', 'RegistrationReader', 'readText, parse, apply', 'leggere il libretto e assegnare i campi'],
    ['Home / Gruppo', 'PdfExport', 'build', 'creare il riepilogo PDF'],
    ['Gruppi', 'group_qr', 'GroupQr, scanGroupQr', 'mostrare, condividere e leggere il QR di invito'],
    ['GroupWatch', 'Firestore, Notification', 'query + show', 'avvisi ad app chiusa'],
    ['SyncService', 'Firestore', 'collezioni fleets, users, pro, unlock', 'dati condivisi'],
    ['NotificationService', 'Android / iOS', 'sveglie programmate', 'promemoria ad app chiusa'],
], [27 * mm, 37 * mm, 46 * mm, 60 * mm])]
story += [P('Sincronizzazione tra telefoni', h2)]
story += [sync_diagram(), P('Figura 2 – Flusso dei dati tra telefoni, cloud e notifiche', cap)]

story += [PageBreak(), P('7. Schermate e navigazione', h1)]
story += [nav(), P('Figura 3 – Mappa delle schermate', cap)]
screens = [
    ['Schermata', 'Cosa si può fare'],
    ['Intro', 'Animazione di apertura; poi login o home se la sessione è già attiva.'],
    ['Login', 'Scegliere account solo sul telefono o online; accedere con email e password, Google o Apple (su iPhone); '
              'registrarsi; recuperare la password (con conferma prima dell\'invio).'],
    ['Home – Veicoli', 'Elenco dei veicoli con filtro per tipo, ordinamento (più vecchio / più recente), stato della prossima '
                       'scadenza; con i Preferiti attivi selettore Tutti / Preferiti e stella su ogni veicolo; '
                       'esportazione PDF; aggiunta veicolo; pressione lunga per spostare il veicolo in un gruppo.'],
    ['Home – Gruppi', 'Gruppi con i loro veicoli, stella sul gruppo intero, PDF del gruppo, aggiunta di veicoli al gruppo, '
                      'accesso alla schermata del gruppo.'],
    ['Home – Scadenze', 'Tutte le scadenze di tutti i veicoli in ordine di data, con filtro «In scadenza».'],
    ['Scheda veicolo', 'Tre sotto-schede: <b>Scadenze</b> (foto, targa, telaio, scadenze, documenti, note), <b>Dati tecnici</b> '
                       '(Pro) e <b>Manutenzioni</b> (Pro). Scorrendo a destra o a sinistra si passa al veicolo vicino con '
                       'l\'animazione della pagina; la sotto-scheda scelta resta la stessa.'],
    ['Modifica veicolo', 'Tipo, nome, targa, foto (con ritaglio), immatricolazione, telaio; con Pro alimentazione, potenza, '
                         'cilindrata, pneumatici a gruppi, olio, batteria, candele/candelette, filtri; scadenze attive e date; '
                         'scadenze personalizzate; note.'],
    ['Documento', 'Aprire, leggere i dati dal libretto (OCR), rinominare, eliminare; stato «solo sul telefono», «backup online» '
                  'o «condiviso nel gruppo».'],
    ['Manutenzione', 'Data, km, interventi eseguiti in lista compatta: toccando una voce si apre un pannello con codice/marca e costo. «Aggiungi ricambio» per voci libere (pastiglie, batteria…). Manodopera e totale calcolato. Note, opzione «conta come tagliando». Nella scheda ogni intervento mostra il costo e in alto il riepilogo «Speso nell\'anno · Totale»; nel PDF compare la colonna Costo. La valuta segue le impostazioni del telefono.'],
    ['Gruppo', 'Membri e ruoli, codice e QR di invito (con logo, condivisibile come immagine), condivisione documenti, '
               'rinomina, uscita o eliminazione del gruppo, assegnazione del proprietario dei veicoli.'],
    ['Pro', 'Vantaggi, prezzo, acquisto e ripristino.'],
    ['Amministrazione', 'Solo per l\'account amministratore: elenco degli acquisti Pro, codici sviluppatore, tutti i veicoli e '
                        'tutti i gruppi, con possibilità di riassegnare veicoli e revocare sblocchi.'],
]
story += [table(screens, [32 * mm, 138 * mm])]

story += [PageBreak(), P('8. Impostazioni, opzioni e possibilità per l\'utente', h1)]
story += [P('Tutte le voci della schermata Impostazioni, nell\'ordine in cui compaiono, e le altre scelte disponibili nell\'app.')]
sett = [
    ['Sezione / voce', 'Effetto'],
    ['<b>Account</b>', 'Mostra il tipo di account (solo sul telefono o online). Da account locale: passaggio a un account '
                       'online, portando con sé i veicoli.'],
    ['<b>Versione Pro</b>', 'Stato della versione Pro e accesso alla schermata di acquisto.'],
    ['<b>Lingua</b>', 'Come il telefono, oppure una delle 36 lingue disponibili.'],
    ['<b>Notifiche</b> – stato', 'Indica se le notifiche sono consentite, bloccate o non puntuali; un tocco apre le impostazioni '
                                 'di Android per sistemarle.'],
    ['Quando avvisare', '«Tutti gli avvisi» oppure singolarmente: 1 mese prima, 1 settimana prima, 1 giorno prima, il giorno della scadenza.'],
    ['Orario delle notifiche', 'Ora del giorno in cui arrivano i promemoria (predefinita 9:00).'],
    ['Prova notifica / Prova tra 1 minuto', 'Verifica immediata e verifica ad app chiusa; mostra quante notifiche sono programmate.'],
    ['Orario preciso', 'Su Android 12 e successivi chiede il permesso «Sveglie e promemoria»; senza, Android può ritardare gli avvisi.'],
    ['<b>Documenti online</b>', 'Consenso alla copia online dei documenti (backup personale e condivisione nei gruppi che la '
                               'permettono), limite 25 MB per utente.'],
    ['<b>Notifiche push</b>', 'Lo stato della registrazione compare solo all\'amministratore oppure se la registrazione non è riuscita (un tocco riprova).'],
    ['Avvisi attività dei gruppi', 'Avvisa quando un altro membro aggiunge, modifica o elimina un veicolo, anche ad app chiusa.'],
    ['<b>Gruppi</b>', 'Elenco dei propri gruppi, creazione di un gruppo, ingresso con codice invito o QR.'],
    ['<b>Aspetto</b> – Preferiti', 'Attiva i preferiti e il selettore della pagina iniziale.'],
    ['Tema', 'Chiaro, scuro o automatico.'],
    ['Colore copertina', 'Otto colori: blu, verde bosco, rosso corsa, arancio, petrolio, viola, grafite, cuoio.'],
    ['Sfondo delle pagine', 'Righe, quadretti, puntini o liscio; i testi si allineano alla rigatura.'],
    ['<b>Unità di misura</b>', 'Potenza in kW, CV o entrambe; distanze in chilometri o miglia; valuta automatica o scelta da un elenco. Nella modifica del veicolo kW e CV si compilano a vicenda.'],
    ['Diagnostica sincronizzazione', 'Solo account online: identificativi, gruppi ricevuti dal server, veicoli per gruppo e problemi; si copia per mandarla allo sviluppatore.'],
    ['<b>Supporto</b>', 'Segnala un problema (email precompilata) e informativa privacy; la richiesta di cancellazione via email resta indicata nell\'informativa.'],
    ['Elimina account', 'Solo account online: cancella dati e account dal cloud (con revoca di «Accedi con Apple»).'],
    ['Esci', 'Chiude la sessione; i dati restano sul telefono.'],
]
story += [table(sett, [48 * mm, 122 * mm])]
story += [P('Altre opzioni nelle schermate', h2)]
story += B([
    '<b>Ordinamento</b> dei veicoli (dal più vecchio / dal più recente) e <b>filtro per tipo</b> in Home.',
    '<b>Filtro «In scadenza»</b> nella scheda Scadenze.',
    '<b>Preferiti</b>: stella sul veicolo (lista e scheda) e sul gruppo intero; vista iniziale ricordata.',
    '<b>Spostamento</b> di un veicolo tra «I miei veicoli» e i gruppi (pressione lunga sulla card).',
    '<b>Solo visualizzazione</b>: chi ha questo ruolo in un gruppo (anche l\'amministratore dell\'app) non può modificare, eliminare, aggiungere manutenzioni né aggiungere o rinominare documenti.',
    '<b>Condivisione documenti</b> nel gruppo, decisa dall\'amministratore del gruppo.',
    '<b>Lettura del libretto</b> (beta) da foto o PDF, con conferma di ogni dato e assegnazione manuale del testo.',
    '<b>Esportazione PDF</b> di veicoli, scadenze e manutenzioni (i dati tecnici non sono inclusi). Dalla pagina Gruppi l\'icona in alto chiede se esportare tutti i gruppi o uno solo. Il PDF viene prima creato e poi si sceglie: apri, salva sul telefono, condividi o stampa.',
    '<b>Telefoni</b> bloccati in verticale; <b>tablet</b> liberi di ruotare e con testi più grandi.',
])

story += [PageBreak(), P('9. Versione gratuita e Pro', h1)]
story += [table([
    ['Funzione', 'Gratuita', 'Pro'],
    ['Veicoli', 'fino a 3 (auto o moto)', 'illimitati'],
    ['Tipi di veicolo', 'auto e moto', 'anche furgoni, camion, rimorchi, agricoli'],
    ['Scadenze e promemoria', 'sì', 'sì'],
    ['Gruppi e condivisione', 'sì', 'sì'],
    ['Preferiti', 'sì', 'sì'],
    ['Scheda Dati tecnici', 'bloccata (solo il telaio nella scheda Scadenze)', 'completa'],
    ['Scheda Manutenzioni', 'bloccata', 'sì'],
    ['Documenti e lettura del libretto', 'no', 'sì'],
    ['Vedere i documenti condivisi da altri', 'no', 'sì'],
    ['Esportazione PDF', 'no', 'sì'],
    ['Versione web (PC e Mac)', 'no', 'sì'],
], [62 * mm, 54 * mm, 54 * mm]), Spacer(1, 6)]
story += [P('La versione Pro si ottiene con l\'acquisto unico <font name="DVM">myfleet_pro</font> sul negozio dell\'app. '
            'L\'amministratore dell\'app la ha in automatico; sono previsti anche codici sviluppatore revocabili, registrati '
            'in Firestore (collezioni <font name="DVM">unlock</font> e <font name="DVM">pro</font>). Quando si superano i '
            'limiti gratuiti dopo una revoca, i veicoli in eccesso restano visibili ma bloccati.')]

story += [P('10. Flussi principali', h1)]
flows = [
    ('Avvio', ['main.dart inizializza Firebase (se disponibile), carica lingua e tema e mostra l\'intro.',
               'AppState legge la sessione da LocalStore; se l\'account online non è più valido torna al login.',
               'Con sessione attiva: carica i dati, programma le notifiche, avvia sincronizzazione, push, controllo dei '
               'gruppi e verifica degli aggiornamenti.']),
    ('Modifica di un veicolo', ['La schermata chiama appState.saveVehicle.',
                                'AppState aggiorna i dati, salva su LocalStore, invia a Firestore (se online) e riprogramma le notifiche.',
                                'Gli altri telefoni del gruppo ricevono la modifica tramite lo stream di SyncService; ad app chiusa la '
                                'segnala GroupWatch.']),
    ('Promemoria', ['A ogni cambiamento NotificationService cancella e riprogramma tutte le notifiche future.',
                    'Per ogni scadenza attiva e ogni anticipo scelto crea un avviso all\'orario impostato; più scadenze dello '
                    'stesso veicolo e giorno diventano un solo avviso.',
                    'Limiti: 400 avvisi su Android, 60 su iPhone (limite del sistema).']),
    ('Gruppi e inviti', ['L\'amministratore crea il gruppo e condivide codice o QR (il QR porta alla pagina web di invito '
                         'con il link a Google Play).',
                         'Chi entra con il codice è in sola visualizzazione; l\'amministratore può cambiarne il ruolo.',
                         'Le regole Firestore verificano ruoli e appartenenza a ogni lettura e scrittura.']),
    ('Documenti online', ['Il documento resta sempre sul telefono di chi lo carica.',
                          'Con il consenso, DocCloud ne crea una copia compressa (foto o prima pagina del PDF, max 700 KB) che '
                          'SyncService salva in Firestore.',
                          'Nei gruppi con condivisione attiva gli altri membri Pro possono scaricarlo e aprirlo.']),
    ('Lettura del libretto', ['RegistrationReader riconosce il testo sul telefono (ML Kit) da foto o dalle prime due pagine del PDF.',
                              'parse estrae i campi con i codici europei e le misure dei pneumatici.',
                              'L\'utente conferma ogni dato o assegna a mano un testo selezionato; i dati scelti vengono salvati.']),
    ('Acquisto Pro', ['ProScreen chiama ProService.buy; il negozio conferma l\'acquisto.',
                      'AppState registra lo stato Pro in locale e nel cloud; le funzioni Pro si sbloccano subito.']),
]
for t, steps in flows:
    story += [KeepTogether([P(t, h3)] + [Paragraph(s, bullet, bulletText='%d.' % (i + 1)) for i, s in enumerate(steps)])]

story += [PageBreak(), P('11. Dati, cloud e sicurezza', h1)]
story += [table([
    ['Dove', 'Cosa', 'Protezione'],
    ['Telefono (cartella privata)', 'Sessione, dati di ogni account, impostazioni, file dei documenti', 'Sandbox del sistema operativo'],
    ['Firestore users/{uid}', 'Profilo, codici dei dispositivi per le push', 'Solo il proprietario (lettura anche admin)'],
    ['Firestore fleets/{gruppo}', 'Gruppo: nome, membri, ruoli, condivisione documenti', 'Membri; modifiche ai membri solo dagli amministratori'],
    ['fleets/{gruppo}/vehicles', 'Veicoli del gruppo (e del gruppo personale)', 'Lettura membri; scrittura amministratori e «può modificare»'],
    ['fleets/{gruppo}/docs', 'Copie online dei documenti, a parti', 'Autore e membri, solo se la condivisione è attiva; limite di dimensione'],
    ['pro/{uid}, unlock/{codice}', 'Registro Pro e codici sviluppatore', 'Lettura limitata; i codici non si possono elencare'],
], [44 * mm, 66 * mm, 60 * mm]), Spacer(1, 6)]
story += B([
    'Connessioni cifrate verso Firebase; accesso al cloud solo con utente autenticato.',
    'Uscita dall\'account in un solo passaggio (un secondo tocco non avvia una seconda uscita) e con tempo massimo; l\'accesso con Google mostra sempre la scelta dell\'account.',
    'Se la sincronizzazione non riesce (errore, nessuna risposta dal server sui gruppi entro un minuto o account Firebase diverso da quello dell\'app) in alto a sinistra compare un\'icona rossa «!!»: un tocco mostra cosa non va e permette di riprovare.',
    'L\'account «solo su questo telefono» non invia nulla in rete.',
    'Il riconoscimento del libretto avviene interamente sul telefono.',
    'Cancellazione completa dei dati e dell\'account dall\'app, più richiesta via email per i dati residui.',
    'Nessuna pubblicità e nessun identificativo pubblicitario (permesso AD_ID rimosso).',
    'Codice Dart offuscato nelle build Android e iOS (nomi di classi e funzioni resi illeggibili) e codice Java ridotto da R8; '
    'la versione web è compilata e minimizzata.',
    'Sito web con intestazioni di sicurezza: HTTPS obbligatorio (HSTS), divieto di inserimento in altre pagine, '
    'nessun accesso a fotocamera, microfono e posizione dal browser.',
    'Firebase App Check attivo nell\'app: ogni richiesta al cloud porta un certificato che attesta l\'app originale; '
    'il blocco delle richieste senza certificato si accende dalla console Firebase.',
    'Ancora da fare prima della produzione (vedi BACKLOG.md): repository privato e verifica della Pro sul server con Firebase Blaze.',
])

story += [P('12. Lingue', h1)]
story += [P('Le traduzioni stanno in <font name="DVM">assets/l10n/&lt;codice&gt;.json</font> (circa %d chiavi per lingua)' % N_CHIAVI + '. '
            'La funzione <font name="DVM">tr(chiave, valori)</font> sostituisce i segnaposti come {n} o {name}. Le nuove chiavi '
            'si aggiungono con gli script numerati in <font name="DVM">tool/l10n_src</font>, che aggiornano tutte le lingue '
            'insieme e verificano che nessuna manchi.')]
story += [P('Lingue disponibili: italiano, inglese, francese, tedesco, spagnolo, portoghese, olandese, croato, sloveno, polacco, '
            'ceco, slovacco, ungherese, rumeno, bulgaro, greco, svedese, danese, norvegese, finlandese, islandese, estone, '
            'lettone, lituano, maltese, irlandese, ucraino, russo, turco, cinese, giapponese, coreano, hindi, indonesiano, '
            'vietnamita, thailandese.', small)]

story += [P('13. Compilazione e rilascio', h1)]
story += B([
    '<b>Android</b>: a ogni modifica su main GitHub Actions crea il progetto Flutter, applica '
    '<font name="DVM">tool/patch_android.py</font> (permessi, notifiche, firma, ML Kit, icone, target SDK 36) e pubblica '
    'una release con APK e AAB per la Play Console.',
    '<b>iOS</b>: compilazione di prova senza firma su macOS con <font name="DVM">tool/patch_ios.py</font> (iOS 15.5, '
    'testi dei permessi, «Accedi con Apple», notifiche). Per TestFlight e App Store servono l\'account Apple Developer e '
    'la configurazione Firebase per iOS.',
    '<b>Qualità</b>: analisi statica (flutter analyze) e test automatici in <font name="DVM">tool/tests</font> (lettura '
    'libretto, pneumatici, QR, documenti, preferiti, assegnazione manuale) più screenshot generati con dati inventati.',
    '<b>Versioni</b>: numero in pubspec.yaml e lib/version.dart; Google Play aggiorna l\'app in automatico.',
])

story += [P('14. Versione web', h1)]
story += [P('La stessa app gira nel browser di PC e Mac ed è <b>riservata agli utenti Pro</b>: si accede solo con un '
            'account online e, se l\'account non ha la Pro, compare una pagina che invita ad attivarla dall\'app sul telefono. '
            'I dati sono gli stessi del telefono, sincronizzati tramite Firestore. La pubblicazione avviene con un workflow dedicato '
            '(<font name="DVM">.github/workflows/build-web.yml</font>) su Firebase Hosting; '
            '<font name="DVM">tool/patch_web.py</font> imposta titolo, icone e schermata di caricamento (logo, nome in Lobster e slogan).')]
story += [table([
    ['Funzione', 'Nel browser'],
    ['Veicoli, scadenze, dati tecnici, manutenzioni, gruppi, preferiti, PDF', 'sì'],
    ['Accesso', 'solo account online (email o Google) con la Pro attiva'],
    ['Documenti', 'consultazione delle copie online condivise (Pro); aggiunta solo dal telefono'],
    ['Lettura del libretto (OCR), scansione QR', 'no'],
    ['Promemoria e notifiche push', 'no: arrivano sul telefono con lo stesso account'],
    ['Acquisto Pro', 'no; la Pro acquistata sul telefono è riconosciuta dal registro Pro dell\'account'],
    ['Prova automatica', 'Chrome, Firefox e WebKit (Safari) a ogni modifica, con tool/web_test/browser_test.py'],
], [80 * mm, 90 * mm]), Spacer(1, 6)]

story += [P('15. Limiti noti e sviluppi previsti', h1)]
story += B([
    'Preferiti salvati per telefono e account, non sincronizzati tra dispositivi.',
    'I telefoni del gruppo con versioni precedenti alla 2.1 non conoscono i nuovi dati tecnici e, modificando un veicolo, li perdono.',
    'Lettura del libretto in prova: va sempre controllata dall\'utente.',
    'iPhone: in attesa di account Apple Developer, configurazione Firebase iOS, chiave APNs e TestFlight.',
    'Avvisi dei gruppi ad app chiusa disponibili solo su Android.',
    'Versione web: la Pro si basa sul registro cloud, che oggi l\'app stessa scrive; prima del lancio va verificata su server (Firebase Blaze).',
])

doc = Doc(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=18 * mm, bottomMargin=18 * mm,
          title='MyFleetManager %s – Architettura software' % VERSION, author='MyFleetManager')
fr = Frame(18 * mm, 18 * mm, 174 * mm, 262 * mm, id='f')
doc.addPageTemplates([PageTemplate('cover', [fr], onPage=cover), PageTemplate('normal', [fr], onPage=deco)])
doc.multiBuild(story)
print('ok')
