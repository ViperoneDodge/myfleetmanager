import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';

late final AppState appState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (FirebaseConfig.isConfigured) {
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        return MaterialApp(
          title: 'MyFleetManager',
          debugShowCheckedModeBanner: false,
          locale: const Locale('it', 'IT'),
          supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: t.mode,
          theme: buildTheme(t, Brightness.light),
          darkTheme: buildTheme(t, Brightness.dark),
          home: appState.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : appState.session == null
                  ? const LoginScreen()
                  : const HomeScreen(),
        );
      },
    );
  }
}
