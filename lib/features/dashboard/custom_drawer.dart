import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/almacen/almacen_main_screen.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';

class CustomDrawer extends ConsumerWidget {
  final Function(int) onMenuItemTap;

  const CustomDrawer({super.key, required this.onMenuItemTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: const FlutterSecureStorage().read(key: 'user_role'),
      builder: (context, snapshot) {
        final userRole = snapshot.data ?? 'user';
        const userEmail = 'usuario@ramis.com';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  userRole.toUpperCase(),
                  style: AppTheme.titleMedium
                      .copyWith(color: AppTheme.textOnPrimary),
                ),
                accountEmail: Text(
                  userEmail,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textOnPrimary.withOpacity(0.8)),
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
              if (userRole == 'trabajador' ||
                  userRole == 'almacenero' ||
                  userRole == 'admin') ...[
                _buildDrawerTile(context, Icons.local_shipping, 'Transportes',
                    7, onMenuItemTap),
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
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
        onTap(index);
        Navigator.pop(context);
      },
    );
  }
}
