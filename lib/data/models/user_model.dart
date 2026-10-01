// lib/models/user_model.dart
class UserModel {
  final int id;
  final String nombre;
  final String apellidos;
  final String? dni;
  final String? cargo;
  final String? codigoUnico;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.dni,
    this.cargo,
    this.codigoUnico,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Buscamos la clave del rol (puede venir como 'role', 'rol', o caer en 'cargo')
    final rawRole = json['role'] ?? json['rol'] ?? json['cargo'];
    final parsedRole = rawRole?.toString().trim();

    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      dni: json['dni'] as String?,
      cargo: json['cargo'] as String?,
      codigoUnico: json['codigo_unico'] as String?,
      email: json['email'] as String,
      // Se asigna 'user' por defecto en vez de un valor inválido
      role: parsedRole == null || parsedRole.isEmpty ? 'user' : parsedRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': dni,
      'cargo': cargo,
      'codigo_unico': codigoUnico,
      'email': email,
      'role': role,
    };
  }

  String get nombresCompletos => '$nombre $apellidos';

  void operator [](String other) {}
}
