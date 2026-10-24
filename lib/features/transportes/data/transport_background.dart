import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import 'transport_queue.dart';

@pragma('vm:entry-point')
void transportCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return true;
    final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Authorization': 'Bearer $token'}));
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final current = await storage.read(key: 'jwt_token');
      if (current != token) {
        handler.reject(DioException(
            requestOptions: options, type: DioExceptionType.cancel));
        return;
      }
      handler.next(options);
    }));
    final queue = TransportQueue(dio);
    await queue.flush();
    return queue.lastError == null;
  });
}

Future<void> initializeTransportBackground() async {
  if (kIsWeb ||
      ![TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform)) {
    return;
  }
  await Workmanager().initialize(transportCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
      'com.ramis.transport.sync', 'transport-sync',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected));
}
