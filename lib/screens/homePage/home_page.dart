import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/category.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/screens/categories/subcategories_screen.dart';
import 'package:super_selectos/screens/homePage/barcode_scanner_screen.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';
import 'package:super_selectos/screens/settings/settings_screen.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';
import 'package:super_selectos/widgets/product_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final M3ENavigationBarController _navController;
  int barIndex = 0;

  final SuperSelectosService _service = SuperSelectosService();
  final ShoppingCartRepository _cart = ShoppingCartRepository.instance;
  List<Product> _productosInicio = [];
  bool _cargandoProductosInicio = true;
  String? _errorProductosInicio;
  int _cantidadAMostrar = 12;

  final List<MainCategory> _categorias = listaCategoriasPrincipales;

  @override
  void initState() {
    super.initState();
    _navController = M3ENavigationBarController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectInitialBranchAndLoadProducts();
    });
  }

  Future<void> _selectInitialBranchAndLoadProducts() async {
    final storeController = StoreSelectionController.instance;

    // Algunos widget tests construyen esta pantalla sin ejecutar main().
    if (storeController.branches.isEmpty) {
      await _cargarProductosInicio();
      return;
    }

    if (storeController.selectedBranch == null) {
      final selected = await showModalBottomSheet<SelectosBranch>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        builder: (_) => PopScope(
          canPop: false,
          child: BranchPickerSheet(
            branches: storeController.branches,
            selectedBranchId: null,
          ),
        ),
      );

      if (selected == null || !mounted) return;
      await storeController.selectBranch(selected);
      if (!mounted) return;
    }

    await _cargarProductosInicio(forzarRefresco: true);
  }

  void _onScroll() {
    if (barIndex == 0 &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400) {
      if (_cantidadAMostrar < _productosInicio.length) {
        setState(() {
          _cantidadAMostrar = (_cantidadAMostrar + 12).clamp(
            0,
            _productosInicio.length,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _cargarProductosInicio({bool forzarRefresco = false}) async {
    setState(() {
      _cargandoProductosInicio = true;
      _errorProductosInicio = null;
    });

    try {
      final productos = await _service.obtenerProductosInicio(
        forzarRefresco: forzarRefresco,
      );
      if (!mounted) return;
      setState(() {
        _productosInicio = productos;
        _cargandoProductosInicio = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoProductosInicio = false;
        _errorProductosInicio = 'home_products_load_failed';
      });
    }
  }

  void _mostrarDetalleProducto(Product producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(producto: producto),
      ),
    );
  }

  void _irAResultados(String query, {String? categoryCode}) {
    final queryLimpio = query.trim();
    if (queryLimpio.isEmpty) return;

    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialQuery: queryLimpio,
          categoryCode: categoryCode,
        ),
      ),
    );
  }

  void _abrirCategoria(MainCategory cat) {
    if (cat.grupos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SubcategoriesScreen(category: cat)),
      );
    } else {
      _irAResultados(cat.tituloCompleto, categoryCode: cat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scaffold = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context, theme, colorScheme),
      body: _buildBody(context, theme, colorScheme),
      bottomNavigationBar: M3ENavigationBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        controller: _navController,
        scrollController: barIndex == 0 ? _scrollController : null,
        hideOnScroll: true,
        destinations: const [
          M3ENavigationBarDestination(
            icon: Icon(M3EIcons.home_outlined),
            selectedIcon: Icon(M3EIcons.home),
            label: 'Inicio',
          ),
          M3ENavigationBarDestination(
            icon: Icon(M3EIcons.category_outlined),
            selectedIcon: Icon(M3EIcons.category),
            label: 'Categorías',
          ),
          M3ENavigationBarDestination(
            icon: Icon(M3EIcons.local_offer_outlined),
            selectedIcon: Icon(M3EIcons.local_offer),
            label: 'Ofertas',
          ),
          M3ENavigationBarDestination(
            icon: Icon(M3EIcons.shopping_cart_outlined),
            selectedIcon: Icon(M3EIcons.shopping_cart),
            label: 'Mi lista',
          ),
        ],
        selectedIndex: barIndex,
        onDestinationSelected: (i) {
          setState(() {
            barIndex = i;
            if (i != 0) {
              _searchFocusNode.unfocus();
            }
          });
        },
      ),
    );

    return ListenableBuilder(
      listenable: _searchFocusNode,
      child: scaffold,
      builder: (context, child) {
        return PopScope(
          canPop: !_searchFocusNode.hasFocus,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _searchFocusNode.unfocus();
            FocusScope.of(context).unfocus();
          },
          child: child!,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (barIndex == 1) {
      return AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Categorías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    if (barIndex == 2) {
      return AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Ofertas y Promociones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    if (barIndex == 3) {
      return AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lista de compras',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_cart.selectedList != null)
              Text(
                _cart.selectedList!.dateTimeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          M3EMenu(
            position: M3EMenuAnchorPosition.bottomEnd,
            selectedValue: _cart.selectedList?.id,
            onSelected: (value) {
              if (value is int) {
                _handleShoppingListSelection(value);
              }
            },
            anchorBuilder: (context, openMenu) {
              return Center(
                child: M3EIconButton(
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  shape: M3EIconButtonShapeVariant.round,
                  tooltip: 'Seleccionar lista',
                  onPressed: openMenu,
                ),
              );
            },
            children: [
              M3EMenuGroup(
                label: 'Tus listas',
                children: [
                  for (final list in _cart.lists)
                    M3EMenuSelectable(
                      label: list.dateTimeLabel,
                      value: list.id,
                      selected: list.id == _cart.selectedList?.id,
                      leading: const Icon(Icons.shopping_bag_outlined),
                    ),
                ],
              ),
              const M3EMenuGroup(
                children: [
                  M3EMenuEntry(
                    label: 'Crear nueva lista',
                    value: -1,
                    leading: Icon(Icons.add_rounded),
                  ),
                  M3EMenuEntry(
                    label: 'Eliminar lista actual',
                    value: -2,
                    leading: Icon(Icons.delete_outline_rounded),
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      notificationPredicate: (_) => false,
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      titleSpacing: 12,
      toolbarHeight: 124,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4, bottom: 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/shopping_cart.svg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                  semanticsLabel: 'Carrito de compras',
                ),
                const SizedBox(width: 10),
                Text(
                  'Selectos Prices',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                M3EIconButton(
                  icon: const Icon(Icons.settings_rounded),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  shape: M3EIconButtonShapeVariant.round,
                  tooltip: 'Ajustes',
                  onPressed: () async {
                    final previousBranchId =
                        StoreSelectionController.instance.selectedBranchId;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    if (!mounted) return;
                    if (previousBranchId !=
                        StoreSelectionController.instance.selectedBranchId) {
                      _cargarProductosInicio(forzarRefresco: true);
                    }
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: M3ESearchBar(
                  focusNode: _searchFocusNode,
                  onTapOutside: (_) => _searchFocusNode.unfocus(),
                  margin: 12,
                  focusedMargin: 0,
                  expandOnFocus: true,
                  controller: _searchController,
                  hintText: '¿Qué estás buscando?',
                  leading: const Icon(Icons.search),
                  trailing: [
                    M3EIconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      variant: M3EIconButtonVariant.filled,
                      size: M3EIconButtonSize.sm,
                      shape: M3EIconButtonShapeVariant.round,
                      tooltip: 'Escanear código de barras',
                      onPressed: () {
                        _searchFocusNode.unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarcodeScannerScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  showClearButton: true,
                  onSubmitted: _irAResultados,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (barIndex) {
      case 1:
        return _buildCategoriasView(theme, colorScheme);
      case 2:
        return _buildOfertasView(theme, colorScheme);
      case 3:
        return _buildCarritoView(theme, colorScheme);
      case 0:
      default:
        return _buildInicioView(theme, colorScheme);
    }
  }

  Widget _buildInicioView(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Categorías (Header) ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categorías',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            barIndex = 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver todas',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Primeras 4 Categorías en Home ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in _categorias.take(4))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildCategoriaCard(item, colorScheme),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Título Productos Destacados ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos Destacados',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grid o Estado de Carga de Productos de Inicio ────────────
                if (_cargandoProductosInicio)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          M3ELoadingIndicator(
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorProductosInicio != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No se pudieron cargar los productos',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inténtalo nuevamente en unos momentos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          M3EButton.filled(
                            onPressed: _cargarProductosInicio,
                            shape: M3EButtonShape.round,
                            decoration: M3EButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colorScheme.primary,
                              ),
                            ),
                            label: Text(
                              'Reintentar',
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                            icon: Icon(
                              Icons.refresh,
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_productosInicio.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'No hay productos disponibles por el momento.',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_cargandoProductosInicio &&
            _errorProductosInicio == null &&
            _productosInicio.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.54,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final prod = _productosInicio[index];
                return ProductCard(
                  product: prod,
                  onTap: () => _mostrarDetalleProducto(prod),
                );
              }, childCount: _productosInicio.take(_cantidadAMostrar).length),
            ),
          ),
          if (_cantidadAMostrar < _productosInicio.length)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: M3EButton.outlined(
                    onPressed: () {
                      setState(() {
                        _cantidadAMostrar = (_cantidadAMostrar + 12).clamp(
                          0,
                          _productosInicio.length,
                        );
                      });
                    },
                    shape: M3EButtonShape.round,
                    label: Text(
                      'Cargar más (${_productosInicio.length - _cantidadAMostrar} restantes)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildCategoriaCard(MainCategory item, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _abrirCategoria(item),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(item.icon, size: 30, color: colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriasView(ThemeData theme, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 20,
        childAspectRatio: 0.78,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final item = _categorias[index];
        return InkWell(
          onTap: () => _abrirCategoria(item),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 32,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfertasView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no está implementado',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos trabajando en ello, gracias por tu paciencia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarritoView(ThemeData theme, ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        if (_cart.loading && _cart.items.isEmpty) {
          return Center(
            child: M3ELoadingIndicator(size: 48, color: colorScheme.primary),
          );
        }

        if (_cart.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      M3EIcons.shopping_cart_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tu lista está vacía',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora productos y agrega todo lo que necesitas comprar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  M3EButton.filled(
                    onPressed: () => setState(() => barIndex = 0),
                    shape: M3EButtonShape.round,
                    decoration: M3EButtonDecoration(
                      backgroundColor: WidgetStatePropertyAll(
                        colorScheme.primary,
                      ),
                    ),
                    label: const Text('Explorar productos'),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _cart.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildShoppingListItem(
                    _cart.items[index],
                    theme,
                    colorScheme,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_cart.totalItems} ${_cart.totalItems == 1 ? 'producto' : 'productos'}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total estimado',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${_cart.estimatedTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleShoppingListSelection(int listId) async {
    try {
      if (listId == -2) {
        await _confirmDeleteSelectedList();
        return;
      } else if (listId == -1) {
        await _cart.createList();
      } else {
        await _cart.selectList(listId);
      }
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        message: 'No se pudo abrir la lista seleccionada',
      );
    }
  }

  Future<void> _confirmDeleteSelectedList() async {
    final selectedList = _cart.selectedList;
    if (selectedList == null) return;
    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await M3EDialog.show<bool>(
      context,
      dialog: Material(
        type: MaterialType.transparency,
        child: M3EDialog(
          title: '¿Eliminar esta lista?',
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          content: Text(
            'Se eliminará la lista del ${selectedList.dateTimeLabel} y todos sus productos.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(context, true),
              shape: M3EButtonShape.round,
              decoration: M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(colorScheme.error),
                foregroundColor: WidgetStatePropertyAll(colorScheme.onError),
              ),
              child: Text(
                'Eliminar',
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _cart.deleteSelectedList();
      if (!mounted) return;
      setState(() {});
      AppSnackbar.success(
        context,
        message: 'Lista eliminada',
        icon: Icons.playlist_remove_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo eliminar la lista');
    }
  }

  Widget _buildShoppingListItem(
    ShoppingCartItem item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final product = item.product;
    final quantityPromotion = item.quantityPromotion;
    final hasAppliedPromotion = item.appliedPromotionBundles > 0;
    final isDarkMode = theme.brightness == Brightness.dark;
    final swipeBackgroundColor = isDarkMode
        ? colorScheme.error
        : colorScheme.errorContainer;
    final deleteButtonColor = isDarkMode
        ? colorScheme.errorContainer
        : colorScheme.error;
    final deleteIconColor = isDarkMode
        ? colorScheme.onErrorContainer
        : colorScheme.onError;
    return M3ECard(
      variant: M3ECardVariant.outlined,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      padding: EdgeInsets.zero,
      onPressed: () => _mostrarDetalleProducto(product),
      swipeMode: M3ECardSwipeMode.reveal,
      trailingSwipeColor: swipeBackgroundColor,
      trailingSwipeAction: M3EIconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        variant: M3EIconButtonVariant.filled,
        size: M3EIconButtonSize.sm,
        shape: M3EIconButtonShapeVariant.round,
        tooltip: 'Quitar de la lista',
        decoration: M3EIconButtonDecoration(
          backgroundColor: WidgetStatePropertyAll(deleteButtonColor),
          foregroundColor: WidgetStatePropertyAll(deleteIconColor),
        ),
        onPressed: () => _removeCartItem(item),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: product.imagen?.isNotEmpty ?? false
                  ? Image.network(
                      product.imagen!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (quantityPromotion != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${quantityPromotion.quantity} por '
                      '\$${quantityPromotion.price.toStringAsFixed(2)}'
                      '${hasAppliedPromotion ? ' · Oferta aplicada' : ''}',
                      style: TextStyle(
                        color: hasAppliedPromotion
                            ? colorScheme.primary
                            : colorScheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Disminuir cantidad',
                          colorScheme: colorScheme,
                          onPressed: item.quantity > 1
                              ? () =>
                                    _updateCartQuantity(item, item.quantity - 1)
                              : null,
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Aumentar cantidad',
                          colorScheme: colorScheme,
                          onPressed: () =>
                              _updateCartQuantity(item, item.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.promotionSavings > 0)
                  Text(
                    '\$${item.regularSubtotal.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: item.promotionSavings > 0
                        ? colorScheme.primary
                        : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          radius: 16,
          onTap: onPressed,
          child: SizedBox(
            width: 28,
            height: 36,
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateCartQuantity(ShoppingCartItem item, int quantity) async {
    try {
      await _cart.updateQuantity(item.key, quantity);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo actualizar la cantidad');
    }
  }

  Future<void> _removeCartItem(ShoppingCartItem item) async {
    try {
      await _cart.removeProduct(item.key);
      if (!mounted) return;
      AppSnackbar.success(
        context,
        message: '${item.product.nombre} eliminado de tu lista',
        icon: Icons.delete_outline_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo eliminar el producto');
    }
  }
}
