import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_config.dart';
import 'l10n.dart';
import 'screens/home_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';
import 'services/local_store.dart';
import 'theme.dart';

late final AppState appState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lingua: quella scelta nelle impostazioni, altrimenti quella del telefono.
  try {
    final settings = await LocalStore().readSettings();
    await L10n.load(L10n.resolve(settings?['lang'] as String?));
  } catch (_) {
    await L10n.load('en');
  }
  if (FirebaseConfig.isConfigured) {
    try {
      // Android: configurazione letta da google-services.json (inserito dalla build).
      await Firebase.initializeApp();
    } catch (_) {
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            appId: FirebaseConfig.appId,
            messagingSenderId: FirebaseConfig.messagingSenderId,
            projectId: FirebaseConfig.projectId,
            storageBucket: FirebaseConfig.storageBucket,
          ),
        );
      } catch (_) {}
    }
  }
  appState = AppState();
  runApp(const FleetApp());
  appState.init();
}

class FleetApp extends StatefulWidget {
  const FleetApp({super.key});

  @override
  State<FleetApp> createState() => _FleetAppState();
}

class _FleetAppState extends State<FleetApp> with WidgetsBindingObserver {
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _introDone = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && appState.syncStatus == SyncStatus.offline) {
      appState.retrySync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final t = appState.theme;
        // Calendario, orologio e pulsanti di sistema nella lingua dell'app
        // (se Flutter non la conosce, ad es. maltese, si usa l'inglese).
        final supported = <Locale>[
          for (final c in L10n.available)
            if (GlobalMaterialLocalizations.delegate.isSupported(Locale(c))) Locale(c),
        ];
        if (!supported.contains(const Locale('en'))) supported.add(const Locale('en'));
        final current = Locale(L10n.code);
        return MaterialApp(
          title: 'MyFleetManager',
          debugShowCheckedModeBanner: false,
          locale: supported.contains(current) ? current : const Locale('en'),
          supportedLocales: supported,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: t.mode,
          theme: buildTheme(t, Brightness.light),
          darkTheme: buildTheme(t, Brightness.dark),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: (!_introDone || appState.loading)
                ? const IntroScreen(key: ValueKey('intro'))
                : appState.session == null
                    ? const LoginScreen(key: ValueKey('login'))
                    : const HomeScreen(key: ValueKey('home')),
          ),
        );
      },
    );
  }
}
