import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../providers/jornadas_provider.dart';
import '../screens/transportes_v3_screen.dart';

class TransportNotificationBell extends ConsumerStatefulWidget {
  const TransportNotificationBell({super.key});
  @override
  ConsumerState<TransportNotificationBell> createState() =>
      _TransportNotificationBellState();
}

class _TransportNotificationBellState
    extends ConsumerState<TransportNotificationBell> {
  Timer? _timer;
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _messages;
  int _count = 0;
  @override
  void initState() {
    super.initState();
    _load();
    _register();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  Future<void> _register() async {
    if (Firebase.apps.isEmpty) return;
    Future<void> register(String token) async {
      try {
        await ref
            .read(transporteRepositoryProvider)
            .postV3('/api/transportes/dispositivos', {'token': token});
      } catch (_) {/* Reintento en próxima sesión. */}
    }

    try {
      final token = await FirebaseMessaging.instance.getToken(
          vapidKey: const String.fromEnvironment('FIREBASE_VAPID_KEY').isEmpty
              ? null
              : const String.fromEnvironment('FIREBASE_VAPID_KEY'));
      if (token != null) await register(token);
      _tokens = FirebaseMessaging.instance.onTokenRefresh.listen(register);
      _messages = FirebaseMessaging.onMessage.listen((message) {
        _load();
        if (mounted && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(message.notification!.body ??
                  message.notification!.title ??
                  'Nueva alerta')));
        }
      });
    } catch (_) {/* La campana sigue funcionando sin permisos push. */}
  }

  Future<void> _load() async {
    try {
      final items = await ref
          .read(transporteRepositoryProvider)
          .getV3('/api/transportes/notificaciones') as List;
      if (mounted) setState(() => _count = items.length);
    } catch (_) {/* Se conserva el último contador al perder conexión. */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tokens?.cancel();
    _messages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: 'Alertas, documentos y hoja de vida',
      icon: Badge(
          isLabelVisible: _count > 0,
          label: Text('$_count'),
          child: const Icon(Icons.notifications_outlined)),
      onPressed: () async {
        await Navigator.push<void>(context,
            MaterialPageRoute(builder: (_) => const TransportesV3Screen()));
        await _load();
      });
}
