import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/login/login_provider.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';
import 'package:sistema_ocs/features/almacen/escanear_qr_screen.dart';
import 'package:sistema_ocs/features/almacen/prestamo/screens/articulo_disponible.dart';


// Importa las pantallas que iremos creando después
// import 'solicitar_prestamo_screen.dart';
// import 'mis_pendientes_screen.dart';
// import 'escanear_qr_screen.dart';
// import 'prestamo_manual_screen.dart';

class AlmacenDashboardScreen extends ConsumerWidget {
  const AlmacenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: const FlutterSecureStorage().read(key: 'user_role'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = (snapshot.data ?? 'user').toLowerCase();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Almacén - Préstamos de Equipos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  ref.read(navigatorKeyProvider).currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de bienvenida / info de rol
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            role == 'trabajador' ? LucideIcons.user : LucideIcons.userCog,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bienvenido al Módulo de Almacén',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rol: ${role.toUpperCase()}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color.fromARGB(255, 12, 16, 13),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Opciones según rol
                  if (role == 'trabajador') ...[
                    _buildActionCard(
                      context,
                      icon: LucideIcons.plusCircle,
                      title: 'Solicitar Préstamo',
                      subtitle: 'Elige equipos y genera QR para el almacenero',
                      color: AppTheme.primary,
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const SolicitarPrestamoScreen()));
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticulosDisponiblesScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      icon: LucideIcons.refreshCw,
                      title: 'Devolver Equipos',
                      subtitle: 'Revisa tus pendientes y genera QR de devolución',
                      color: AppTheme.secondary,
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const MisPendientesScreen()));
                        _showProximamente(context);
                      },
                    ),
                  ],

                  if (role == 'almacenero') ...[
                    _buildActionCard(
                      context,
                      icon: LucideIcons.qrCode,
                      title: 'Escanear QR',
                      subtitle: 'Confirma préstamos o devoluciones escaneando',
                      color: Colors.deepPurple,
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanearQrScreen()));
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQRScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      icon: LucideIcons.userPlus,
                      title: 'Préstamo Manual',
                      subtitle: 'Para trabajadores sin celular o app',
                      color: AppTheme.warning,
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const PrestamoManualScreen()));
                        _showProximamente(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      icon: LucideIcons.search,
                      title: 'Buscar Artículo / Trabajador',
                      subtitle: 'Ver estado o préstamos actuales',
                      color: AppTheme.secondary,
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const BusquedaAlmacenScreen()));
                        _showProximamente(context);
                      },
                    ),
                  ],

                  if (role != 'trabajador' && role != 'almacenero')
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No tienes acceso al módulo de Almacén.\nContacta al administrador.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.error,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showProximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo - Próximamente disponible'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}