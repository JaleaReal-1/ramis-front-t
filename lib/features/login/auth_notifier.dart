import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._authService, this._storage) : super(AuthStatus.initial) {
    _checkAuthStatus();
  }

  // ✅ CAMBIO 1: La firma usa 'email'
  Future<void> login(String email, String password) async {
    state = AuthStatus.loading;
    try {
      // ✅ Usa el parámetro 'email'
      final token = await _authService.login(email, password);
      
      await _storage.write(key: 'jwt_token', value: token.accessToken);
      
      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.unauthenticated;
      rethrow; 
    }
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storage.deleteAll();
    state = AuthStatus.unauthenticated;
  }
}

// Proveedores de Riverpod
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final authServiceProvider = Provider((ref) {
  // Aquí está el truco: le pasamos el Dio que ya tiene el Interceptor
  final dio = ref.watch(dioProvider); 
  return AuthService(dio);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStatus>(
  (ref) => AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
  ),
);