// lib/services/auth_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  // ===========================
  // 🔹 LOGIN
  // ===========================
  Future<TokenModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔥 RESPONSE COMPLETO DEL LOGIN 🔥');
        print('Todo el JSON recibido: $data');

        final tokenModel = TokenModel.fromJson(data);

        // Guardar token y role
        await _storage.write(key: 'jwt_token', value: tokenModel.accessToken);
        await _storage.write(key: 'user_role', value: tokenModel.role ?? 'user');

        print('Role recibido: ${tokenModel.role ?? "No recibido"}');

        // Guardar usuario completo en storage
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          // Inyectamos el rol crudo desde la raíz, ya que el backend lo omite dentro de 'user'
          userJson['role'] = tokenModel.role;
          print('Datos del usuario con rol inyectado: $userJson');
          
          final user = UserModel.fromJson(userJson);
          await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
          print('Usuario completo guardado en secure storage OK');
        } else {
          print('⚠️ ADVERTENCIA: No se recibió el objeto "user" en el login');
        }

        return tokenModel;
      }

      throw Exception('Login falló con código ${response.statusCode}');
    } on DioException catch (e) {
      print('--- ERROR DIO DETALLADO ---');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      throw Exception('Error de conexión o servidor: ${e.message}');
    }
  }

  // ===========================
  // 🔹 OBTENER USUARIO ACTUAL
  // ===========================
  Future<UserModel?> getCurrentUser() async {
    final userJsonStr = await _storage.read(key: 'user_data');
    if (userJsonStr == null) return null;

    try {
      final userJson = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      print('Error al parsear user guardado: $e');
      return null;
    }
  }

  // ===========================
  // 🔹 LOGOUT
  // ===========================
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ===========================
  // 🔹 OBTENER TODOS LOS TRABAJADORES
  // ===========================
  Future<List<Map<String, dynamic>>> getTrabajadores() async {
    try {
      final response = await _dio.get(
        '/auth/trabajadores',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _storage.read(key: 'jwt_token')}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        // Retornamos la lista de trabajadores como Map
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      throw Exception('Error al obtener trabajadores: ${response.statusCode}');
    } on DioException catch (e) {
      print('Error Dio getTrabajadores: ${e.response?.statusCode} ${e.message}');
      throw Exception('Error de conexión o servidor: ${e.message}');
    }
  }
}