import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/category.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/screens/categories/subcategories_screen.dart';
import 'package:super_selectos/screens/homePage/barcode_scanner_screen.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
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
    _cargarProductosInicio();
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

  Future<void> _cargarProductosInicio() async {
    setState(() {
      _cargandoProductosInicio = true;
      _errorProductosInicio = null;
    });

    try {
      final productos = await _service.obtenerProductosInicio();
      if (!mounted) return;
      setState(() {
        _productosInicio = productos;
        _cargandoProductosInicio = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoProductosInicio = false;
        _errorProductosInicio = 'No se pudieron cargar los productos: $e';
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
            label: 'Carrito',
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
        title: const Text(
          'Mi Carrito',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return AppBar(
      notificationPredicate: (_) => false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 12,
      title: Row(
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
              showClearButton: true,
              onSubmitted: _irAResultados,
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Botón circular para abrir el escáner de código de barras
          M3EIconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            variant: M3EIconButtonVariant.filled,
            size: M3EIconButtonSize.sm,
            shape: M3EIconButtonShapeVariant.round,
            tooltip: 'Escanear código de barras',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
              );
            },
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
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            barIndex = 1;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver todas',
                                style: TextStyle(
                                  color: Color(0xFF2E6C37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF2E6C37),
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
                            child: _buildCategoriaCard(item),
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
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grid o Estado de Carga de Productos de Inicio ────────────
                if (_cargandoProductosInicio)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          M3ELoadingIndicator(
                            size: 40,
                            color: Color(0xFF2E6C37),
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
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorProductosInicio!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          M3EButton.filled(
                            onPressed: _cargarProductosInicio,
                            shape: M3EButtonShape.round,
                            decoration: const M3EButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                Color(0xFF2E6C37),
                              ),
                            ),
                            label: const Text(
                              'Reintentar',
                              style: TextStyle(color: Colors.white),
                            ),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prod = _productosInicio[index];
                  return ProductCard(
                    product: prod,
                    onTap: () => _mostrarDetalleProducto(prod),
                  );
                },
                childCount: _productosInicio.take(_cantidadAMostrar).length,
              ),
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildCategoriaCard(MainCategory item) {
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
              color: const Color(0xFF2E6C37),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E6C37).withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(item.icon, size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: Color(0xFF1E293B),
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
                  color: const Color(0xFF2E6C37),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E6C37).withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(item.icon, size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfertasView(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Muestrar que aun no esta implementado
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Aún no está implementado',
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
        ],
      ),
    );
  }

  Widget _buildCarritoView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
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
              'Tu carrito está vacío',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora tus productos favoritos y agrégalos a tu lista para comparar precios y promociones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            M3EButton.filled(
              onPressed: () {
                setState(() => barIndex = 0);
              },
              shape: M3EButtonShape.round,
              decoration: const M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(Color(0xFF2E6C37)),
              ),
              label: const Text(
                'Explorar productos',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.search, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
