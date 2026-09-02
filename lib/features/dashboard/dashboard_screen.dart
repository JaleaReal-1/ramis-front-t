import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/features/almacen/prestamo/providers/carrito_provider.dart';
import 'package:sistema_ocs/features/almacen/prestamo/screens/carrito_screen.dart';
import 'package:sistema_ocs/features/compras/items_to_buy_screen.dart';
import 'package:sistema_ocs/features/dashboard/custom_drawer.dart';
import 'package:sistema_ocs/features/dashboard/dashboard_home_view.dart';
import 'package:sistema_ocs/features/inventario/inventory_screen.dart';
import 'package:sistema_ocs/features/logistica/shipping_list_screen.dart';

// Importaciones de servicios y modelos
import 'package:sistema_ocs/features/ordenes_compra/screens/resumen_oc_screen.dart';
import 'package:sistema_ocs/features/ordenes_compra/providers/oc_provider.dart';
import 'package:sistema_ocs/data/services/orden_compra_service.dart';
import 'package:sistema_ocs/features/ordenes_compra/screens/subircomprobantescreen.dart';
import 'package:sistema_ocs/features/requerimientos/rqs_list_screen.dart';
import 'package:sistema_ocs/features/requerimientos/upload_pdf_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/rq_list_screen.dart'; // Nueva
import 'package:sistema_ocs/features/transportes/screens/transportes_home_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // Lista de vistas (Se mantiene tu estructura original)
  late final List<Widget> _views = [
    const DashboardHomeView(),
    const RQsListScreen(),
    const ComprasMainScreen(), // TabBarView: Artículos | Por Enviar
    const RQListScreen(),
    const ShippingListScreen(),
    const InventoryScreen(),
    const UploadPDFScreen(),
    const TransportesHomeScreen(role: 'user'),
  ];

  void _onMenuItemTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final ocItems = ref.watch(ocProvider);
    final bool hasOCItems = ocItems.isNotEmpty;
    final carrito = ref.watch(carritoProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_getCurrentTitle()),
        actions: [
          if (hasOCItems) _buildCartBadge(ocItems.length),
          if (carrito.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${carrito.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarritoScreen()),
                );
              },
            ),
        ],
      ),
      body: _views[_selectedIndex],
      drawer: CustomDrawer(onMenuItemTap: _onMenuItemTap),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getCurrentTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Requerimientos';
      case 2:
        return 'Gestión de Compras';
      case 3:
        return 'Urgentes';
      case 7:
        return 'Transportes';
      default:
        return 'Sistema OCS';
    }
  }

  Widget _buildCartBadge(int count) {
    return IconButton(
      icon: Badge(
        label: Text('$count'),
        child: const Icon(LucideIcons.shoppingCart),
      ),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ResumenOCScreen())),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: 'RQs'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.shoppingCart), label: 'Compras'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.zap), label: 'Urgente'),
      ],
      onTap: (index) => _onMenuItemTap(index),
    );
  }
}

// ==========================================================
// 💡 VISTA PRINCIPAL DE COMPRAS (TABS)
// ==========================================================
class ComprasMainScreen extends StatelessWidget {
  const ComprasMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: "ARTÍCULOS", icon: Icon(LucideIcons.shoppingBag)),
                Tab(text: "POR ENVIAR", icon: Icon(LucideIcons.clock)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ItemsToBuyScreen(), // Selección de ítems de RQs
                OrdenesGuardadasLocalView(), // Borradores guardados localmente
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// 💡 VISTA DE BORRADORES (EDITAR, ELIMINAR, MANDAR)
// ==========================================================
class OrdenesGuardadasLocalView extends ConsumerWidget {
  const OrdenesGuardadasLocalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenes = ref.watch(listaOrdenesLocalesProvider);

    if (ordenes.isEmpty) {
      return const Center(child: Text("No hay órdenes pendientes de envío"));
    }

    return ListView.builder(
      itemCount: ordenes.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final orden = ordenes[index];
        final bool esEnviado = orden.estado == 'enviado';

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
              esEnviado ? LucideIcons.checkCircle2 : LucideIcons.fileText,
              color: esEnviado ? AppTheme.success : AppTheme.primary,
            ),
            title: Text(orden.proveedor,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                "S/ ${orden.total.toStringAsFixed(2)} - ${orden.itemsComprados.length} items"),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // ELIMINAR
                    TextButton.icon(
                      onPressed: esEnviado
                          ? null
                          : () => ref
                              .read(listaOrdenesLocalesProvider.notifier)
                              .eliminarOrden(orden.idLocal!),
                      icon: const Icon(LucideIcons.trash2,
                          color: AppTheme.error, size: 18),
                      label: Text('Eliminar',
                          style: TextStyle(color: AppTheme.error)),
                    ),
                    const SizedBox(width: 10),
                    // EDITAR
                    if (!esEnviado)
                      TextButton.icon(
                        onPressed: () {
                          /* Navegar de vuelta al formulario final con datos */
                        },
                        icon: const Icon(LucideIcons.edit3, size: 18),
                        label: const Text("Editar"),
                      ),
                    const SizedBox(width: 10),
                    // MANDAR (EL PASO CRÍTICO)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esEnviado
                            ? AppTheme.textDisabled
                            : AppTheme.primary,
                        foregroundColor: AppTheme.textOnPrimary,
                      ),
                      onPressed: esEnviado
                          ? null
                          : () =>
                              _enviarJSONYSolicitarFotos(context, ref, orden),
                      icon: Icon(
                          esEnviado ? LucideIcons.check : LucideIcons.send,
                          size: 18),
                      label: Text(esEnviado ? "ENVIADO" : "MANDAR"),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // 💡 LÓGICA DE ENVÍO: 1. JSON -> 2. Pantalla de Fotos
  Future<void> _enviarJSONYSolicitarFotos(
      BuildContext context, WidgetRef ref, dynamic orden) async {
    final service = OrdenCompraService();

    try {
      // Mostrar loading
      showDialog(
          context: context,
          builder: (_) => const Center(child: CircularProgressIndicator()));

      // 1. Enviar JSON al servidor (Crea el registro en DB)
      final int ordenId = await service.crearOrden(orden);

      if (context.mounted) {
        Navigator.pop(context); // Quitar loading

        // 2. Abrir Formulario de Fotos pasando el ordenId obtenido
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubirComprobantesScreen(
              ordenId: ordenId,
              ordenLocal: orden,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
