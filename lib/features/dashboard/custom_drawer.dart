import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/almacen/almacen_main_screen.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/asignacion_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/admin_transportes_screen.dart';
import 'package:sistema_ocs/features/login/login_provider.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';

class CustomDrawer extends ConsumerWidget {
  final Function(int) onMenuItemTap;

  const CustomDrawer({super.key, required this.onMenuItemTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserModel?>(
      future: ref.read(authServiceProvider).getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userRole = user?.role ?? 'user';
        final String currentRole = userRole.toLowerCase();
        final bool canViewTransportes =
            currentRole.contains('admin') || currentRole.contains('conductor');
        final userName = user?.nombresCompletos ?? userRole.toUpperCase();
        final userEmail = user?.email ?? 'Sin correo';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  userName,
                  style: AppTheme.titleMedium
                      .copyWith(color: AppTheme.textOnPrimary),
                ),
                accountEmail: Text(
                  '$userEmail\nRol: $userRole',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: Icon(Icons.business_center,
                      color: AppTheme.textOnPrimary),
                ),
                decoration: const BoxDecoration(
                  gradient: AppTheme.statusHeaderGradient,
                ),
              ),
              _buildDrawerTile(
                  context, Icons.dashboard, 'Dashboard', 0, onMenuItemTap),
              _buildDrawerTile(context, Icons.list_alt, 'Requerimientos (RQ)',
                  1, onMenuItemTap),
              _buildDrawerTile(context, Icons.shopping_cart,
                  'Ítems para Comprar', 2, onMenuItemTap),
              _buildDrawerTile(context, Icons.receipt_long,
                  'Órdenes de Compra (OCs)', 6, onMenuItemTap),
              _buildDrawerTile(context, Icons.local_shipping,
                  'Logística / Envíos', 3, onMenuItemTap),
              _buildDrawerTile(
                  context, Icons.inventory, 'Inventario', 4, onMenuItemTap),
              _buildDrawerTile(
                  context, Icons.add_box, 'Cargar RQ (PDF)', 5, onMenuItemTap),
              if (canViewTransportes) ...[
                _buildTransportesTile(context, userRole),
                const Divider(color: AppTheme.divider),
                ListTile(
                  leading: const Icon(Icons.warehouse_outlined,
                      color: AppTheme.primary),
                  title: const Text('Almacén / Préstamos de Equipos'),
                  subtitle: Text(
                    'Solicitar, devolver, confirmar',
                    style: AppTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlmacenMainScreen()),
                    );
                  },
                ),
              ],
              const Divider(color: AppTheme.divider),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.error),
                title: const Text('Cerrar Sesión'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).logout();
                  ref
                      .read(navigatorKeyProvider)
                      .currentState
                      ?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportesTile(BuildContext context, String role) {
    final String currentRole = role.toLowerCase();

    if (currentRole.contains('admin')) {
      // Para admin, mostramos un ExpansionTile con submódulos
      return ExpansionTile(
        leading: const Icon(Icons.local_shipping, color: AppTheme.primary),
        title: Text('Transportes', style: AppTheme.bodyMedium),
        children: [
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('Asignar Jornada'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AsignacionJornadaScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Gestión de Flota'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminTransportesScreen()),
              );
            },
          ),
          ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Conductores'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AdminTransportesScreen(initialIndex: 5)));
              }),
        ],
      );
    } else {
      // Para conductor
      return ExpansionTile(
        leading: const Icon(Icons.local_shipping, color: AppTheme.primary),
        title: Text('Transportes', style: AppTheme.bodyMedium),
        initiallyExpanded: true,
        children: [
          ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Mi Jornada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConductorJornadaScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Mis Documentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ConductorJornadaScreen(initialIndex: 2)));
              }),
        ],
      );
    }
  }

  Widget _buildDrawerTile(
    BuildContext context,
    IconData icon,
    String title,
    int index,
    Function(int) onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: AppTheme.bodyMedium),
      onTap: () {
        Navigator.pop(context);
        onTap(index);
      },
    );
  }
}
