import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  late AccountMode _mode =
      appState.auth.cloudAvailable ? AccountMode.cloud : AccountMode.local;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Session> Function() action) async {
    setState(() => _busy = true);
    try {
      final s = await action();
      await appState.login(s);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final u = _user.text.trim();
    final p = _pass.text;
    if (u.isEmpty || p.isEmpty) {
      showSnack(context, 'Compila tutti i campi.');
      return;
    }
    if (_register && p != _pass2.text) {
      showSnack(context, 'Le password non coincidono.');
      return;
    }
    final auth = appState.auth;
    if (_mode == AccountMode.local) {
      _run(() => _register ? auth.registerLocal(u, p) : auth.loginLocal(u, p));
    } else {
      _run(() => _register ? auth.registerCloud(u, p) : auth.loginCloud(u, p));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = appState.auth.cloudAvailable;
    final scheme = Theme.of(context).colorScheme;
    final isLocal = _mode == AccountMode.local;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.garage_rounded, size: 72, color: scheme.primary),
                  const SizedBox(height: 8),
                  Text('MyFleetManager',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Scadenze di auto e moto, sempre sotto controllo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  if (cloud) ...[
                    SegmentedButton<AccountMode>(
                      segments: const [
                        ButtonSegment(
                            value: AccountMode.cloud,
                            icon: Icon(Icons.family_restroom),
                            label: Text('Account online')),
                        ButtonSegment(
                            value: AccountMode.local,
                            icon: Icon(Icons.phone_android),
                            label: Text('Solo telefono')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) => setState(() => _mode = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocal
                          ? 'Account salvato solo su questo telefono. Nessuna condivisione.'
                          : 'Permette di condividere il parco auto con la famiglia. I dati restano anche sul telefono.',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _user,
                    keyboardType:
                        isLocal ? TextInputType.text : TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: isLocal ? 'Nome utente' : 'Email',
                      prefixIcon: Icon(isLocal ? Icons.person : Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    textInputAction:
                        _register ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_register) _submit();
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass2,
                      obscureText: _hide,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Ripeti password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _busy
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'Crea account' : 'Accedi'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Hai già un account? Accedi'
                        : 'Non hai un account? Registrati'),
                  ),
                  if (cloud && !isLocal) ...[
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('oppure')),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(appState.auth.loginGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text('Accedi con Google'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                    const SizedBox(height: 6),
                    Text('Con Google l\'app riceve solo il tuo indirizzo email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                  if (!cloud) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: scheme.surfaceContainerHighest,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Modalità solo telefono: i dati restano su questo dispositivo. '
                          'Accesso con Google e parco auto familiare si attivano dopo la '
                          'configurazione online (vedi guida).',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
