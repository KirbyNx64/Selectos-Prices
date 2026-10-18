import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/screens/homePage/barcode_scanner_screen.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/services/android_platform_version.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/widgets/product_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String? categoryCode;
  final String? landingUrl;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    this.categoryCode,
    this.landingUrl,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SuperSelectosService _service = SuperSelectosService();
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  SearchResponse? _searchResponse;
  int _paginaActual = 1;
  String? _currentCategoryCode;
  String? _currentCategoryNombre;
  String? _currentLandingUrl;
  String _currentQuery = '';
  ProductFilterSelection _selectedFilters = const ProductFilterSelection();
  List<ProductFilterGroup> _filterGroups = const [];
  bool _consumeBackForActiveSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    _currentCategoryCode = widget.categoryCode;
    _currentCategoryNombre = widget.initialQuery;
    _currentLandingUrl = widget.landingUrl;
    _searchFocusNode.addListener(_trackActiveSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.landingUrl != null && widget.landingUrl!.isNotEmpty) {
          _ejecutarLanding();
        } else if (widget.categoryCode != null &&
            widget.categoryCode!.isNotEmpty) {
          _ejecutarBusquedaCategoria(widget.categoryCode!, widget.initialQuery);
        } else if (widget.initialQuery.trim().isNotEmpty) {
          _ejecutarBusqueda(widget.initialQuery);
        }
      }
    });
  }

  Future<void> _ejecutarLanding({int pagina = 1}) async {
    final landingUrl = _currentLandingUrl;
    if (landingUrl == null || landingUrl.isEmpty) return;

    _dismissSearch();
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _errorMessage = null;
      _paginaActual = pagina;
      _currentCategoryCode = null;
    });

    if (!await _verificarConexion()) return;

    try {
      final response = await _service.obtenerProductosLanding(
        landingUrl,
        pagina: pagina,
        filters: _selectedFilters,
      );
      if (!mounted) return;
      setState(() {
        _searchResponse = response;
        _isLoading = false;
        _isOffline = false;
        _errorMessage = response.error;
        if (response.filterGroups.isNotEmpty) {
          _filterGroups = response.filterGroups;
        }
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOffline = false;
        _errorMessage = 'landing_search_failed';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.removeListener(_trackActiveSearch);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _ejecutarBusquedaCategoria(
    String code,
    String nombre, {
    int pagina = 1,
  }) async {
    _dismissSearch();
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _errorMessage = null;
      _paginaActual = pagina;
      _currentCategoryCode = code;
      _currentCategoryNombre = nombre;
      _currentLandingUrl = null;
    });

    if (!await _verificarConexion()) return;

    try {
      final response = await _service.buscarPorCategoria(
        code,
        categoryNombre: nombre,
        pagina: pagina,
        filters: _selectedFilters,
      );
      if (!mounted) return;

      setState(() {
        _searchResponse = response;
        _isLoading = false;
        _isOffline = false;
        if (response.error != null) {
          _errorMessage = response.error;
        }
        if (response.filterGroups.isNotEmpty) {
          _filterGroups = response.filterGroups;
        }
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOffline = false;
        _errorMessage = 'category_search_failed';
      });
    }
  }

  Future<void> _ejecutarBusqueda(String query, {int pagina = 1}) async {
    final queryLimpio = query.trim();
    if (queryLimpio.isEmpty) return;

    _dismissSearch();
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _errorMessage = null;
      _paginaActual = pagina;
      _currentQuery = queryLimpio;
      _currentCategoryCode = null;
      _currentLandingUrl = null;
    });

    if (!await _verificarConexion()) return;

    try {
      final response = await _service.buscarProductosDetallado(
        queryLimpio,
        pagina: pagina,
        filters: _selectedFilters,
      );
      if (!mounted) return;

      setState(() {
        _searchResponse = response;
        _isLoading = false;
        _isOffline = false;
        if (response.error != null) {
          _errorMessage = response.error;
        }
        if (response.filterGroups.isNotEmpty) {
          _filterGroups = response.filterGroups;
        }
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOffline = false;
        _errorMessage = 'product_search_failed';
      });
    }
  }

  Future<bool> _verificarConexion() async {
    try {
      final connections = await _connectivity.checkConnectivity();
      final hasConnection = connections.any(
        (connection) => connection != ConnectivityResult.none,
      );
      if (hasConnection) return true;

      if (!mounted) return false;
      setState(() {
        _isLoading = false;
        _isOffline = true;
        _errorMessage = 'Conéctate a una red Wi-Fi o activa los datos móviles para buscar productos.';
      });
      return false;
    } catch (_) {
      // Si el sistema no puede informar el tipo de red, dejamos que la
      // solicitud determine si existe conexión.
      return true;
    }
  }

  void _reintentarBusqueda() {
    if (_currentLandingUrl != null && _currentLandingUrl!.isNotEmpty) {
      _ejecutarLanding(pagina: _paginaActual);
      return;
    }
    if (_currentCategoryCode != null && _currentCategoryCode!.isNotEmpty) {
      _ejecutarBusquedaCategoria(
        _currentCategoryCode!,
        _currentCategoryNombre ?? '',
        pagina: _paginaActual,
      );
      return;
    }
    _ejecutarBusqueda(_currentQuery, pagina: _paginaActual);
  }

  void _ejecutarNuevaBusqueda(String query) {
    setState(() {
      _selectedFilters = const ProductFilterSelection();
      _filterGroups = const [];
      _currentLandingUrl = null;
    });
    _ejecutarBusqueda(query);
  }

  Future<void> _mostrarFiltros() async {
    final supportsSorting =
        (_currentCategoryCode?.isNotEmpty ?? false) ||
        (_currentLandingUrl?.isNotEmpty ?? false);
    final draft = <String, Set<String>>{
      for (final entry in _selectedFilters.values.entries)
        entry.key: {...entry.value},
    };
    var draftSortOrder = _selectedFilters.sortOrder;

    final selection = await showModalBottomSheet<ProductFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedCount =
                draft.values.fold<int>(
                  0,
                  (total, values) => total + values.length,
                ) +
                (supportsSorting &&
                        draftSortOrder != ProductSortOrder.alphabetically
                    ? 1
                    : 0);

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            supportsSorting ? 'Filtros y orden' : 'Filtros',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: selectedCount == 0
                              ? null
                              : () => setSheetState(() {
                                  draft.clear();
                                  draftSortOrder =
                                      ProductSortOrder.alphabetically;
                                }),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      children: [
                        if (supportsSorting)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFilterGroupTitle(
                                      context,
                                      'Ordenar por',
                                    ),
                                    RadioGroup<ProductSortOrder>(
                                      groupValue: draftSortOrder,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setSheetState(
                                          () => draftSortOrder = value,
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          for (final order
                                              in ProductSortOrder.values)
                                            RadioListTile<ProductSortOrder>(
                                              value: order,
                                              title: Text(order.label),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        for (final group in _filterGroups)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFilterGroupTitle(
                                      context,
                                      group.title,
                                    ),
                                    for (final option in group.options)
                                      CheckboxListTile(
                                        value:
                                            draft[group.queryParameter]
                                                ?.contains(option.value) ??
                                            false,
                                        title: Text(option.label),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (checked) {
                                          setSheetState(() {
                                            final selected = draft.putIfAbsent(
                                              group.queryParameter,
                                              () => <String>{},
                                            );
                                            if (checked ?? false) {
                                              selected.add(option.value);
                                            } else {
                                              selected.remove(option.value);
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          ProductFilterSelection(
                            values: draft,
                            sortOrder: supportsSorting
                                ? draftSortOrder
                                : ProductSortOrder.alphabetically,
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          selectedCount == 0
                              ? 'Mostrar resultados'
                              : 'Aplicar $selectedCount ${selectedCount == 1 ? 'filtro' : 'filtros'}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selection == null || !mounted) return;
    setState(() => _selectedFilters = selection);
    if (_currentLandingUrl != null && _currentLandingUrl!.isNotEmpty) {
      _ejecutarLanding();
    } else if (_currentCategoryCode != null &&
        _currentCategoryCode!.isNotEmpty) {
      _ejecutarBusquedaCategoria(
        _currentCategoryCode!,
        _currentCategoryNombre ?? '',
      );
    } else {
      _ejecutarBusqueda(_currentQuery);
    }
  }

  Widget _buildFilterGroupTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _irAPagina(int nuevaPagina) {
    if (nuevaPagina == _paginaActual || _isLoading) return;
    if (_currentLandingUrl != null && _currentLandingUrl!.isNotEmpty) {
      _ejecutarLanding(pagina: nuevaPagina);
    } else if (_currentCategoryCode != null &&
        _currentCategoryCode!.isNotEmpty) {
      _ejecutarBusquedaCategoria(
        _currentCategoryCode!,
        _currentCategoryNombre ?? '',
        pagina: nuevaPagina,
      );
    } else {
      _ejecutarBusqueda(_currentQuery, pagina: nuevaPagina);
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

  void _trackActiveSearch() {
    if (_searchFocusNode.hasFocus) {
      _consumeBackForActiveSearch = true;
    }
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AndroidPlatformVersion.isAndroid16OrNewer) return;
      if (MediaQuery.viewInsetsOf(context).bottom == 0 &&
          _consumeBackForActiveSearch) {
        setState(() => _consumeBackForActiveSearch = false);
      }
    });
  }

  void _dismissSearch() {
    _consumeBackForActiveSearch = false;
    _searchFocusNode.unfocus();
  }

  void _handleSearchTapOutside(PointerDownEvent event) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets;
    final leftGestureWidth = gestureInsets.left > 32
        ? gestureInsets.left
        : 32.0;
    final rightGestureWidth = gestureInsets.right > 32
        ? gestureInsets.right
        : 32.0;
    final isSystemBackGesture =
        event.position.dx <= leftGestureWidth ||
        event.position.dx >= mediaQuery.size.width - rightGestureWidth;

    if (isSystemBackGesture) {
      _searchFocusNode.unfocus();
      return;
    }
    _dismissSearch();
  }

  void _handleBack() {
    if (_consumeBackForActiveSearch) {
      setState(() => _consumeBackForActiveSearch = false);
      _searchFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productos = _searchResponse?.productos ?? [];

    final scaffold = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        titleSpacing: 0,
        leading: Center(
          child: M3EIconButton(
            icon: const Icon(Icons.arrow_back),
            variant: M3EIconButtonVariant.tonal,
            size: M3EIconButtonSize.sm,
            shape: M3EIconButtonShapeVariant.round,
            tooltip: 'Volver',
            onPressed: _handleBack,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: M3ESearchBar(
            focusNode: _searchFocusNode,
            onTapOutside: _handleSearchTapOutside,
            margin: 12,
            focusedMargin: 0,
            expandOnFocus: true,
            controller: _searchController,
            hintText: 'Buscar producto...',
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  final hasQuery = value.text.trim().isNotEmpty;
                  return M3EIconButton(
                    icon: Icon(
                      hasQuery
                          ? Icons.search_rounded
                          : Icons.qr_code_scanner_rounded,
                    ),
                    variant: M3EIconButtonVariant.filled,
                    size: M3EIconButtonSize.sm,
                    shape: M3EIconButtonShapeVariant.round,
                    tooltip: hasQuery ? 'Buscar' : 'Escanear código de barras',
                    onPressed: hasQuery
                        ? () => _ejecutarNuevaBusqueda(value.text)
                        : () {
                            _dismissSearch();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BarcodeScannerScreen(),
                              ),
                            );
                          },
                  );
                },
              ),
            ],
            showClearButton: true,
            onSubmitted: _ejecutarNuevaBusqueda,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody(context, productos)),
    );

    return ListenableBuilder(
      listenable: _searchFocusNode,
      child: scaffold,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack();
          },
          child: child!,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, List<Product> productos) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            M3ELoadingIndicator(
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _isOffline
                    ? 'Sin conexión a Internet'
                    : 'No se pudo completar la búsqueda',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isOffline
                    ? 'Revisa tu conexión e inténtalo nuevamente.'
                    : 'Inténtalo nuevamente en unos momentos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              M3EButton.filled(
                onPressed: _reintentarBusqueda,
                shape: M3EButtonShape.round,
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                label: Text(
                  'Reintentar',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResponse != null && productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilters.count > 0
                    ? 'No hay productos que coincidan con los filtros seleccionados.'
                    : 'Intenta con otro término o verifica el código de barras ingresado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (_selectedFilters.count > 0) ...[
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _selectedFilters = const ProductFilterSelection();
                    });
                    if (_currentLandingUrl != null &&
                        _currentLandingUrl!.isNotEmpty) {
                      _ejecutarLanding();
                    } else if (_currentCategoryCode != null &&
                        _currentCategoryCode!.isNotEmpty) {
                      _ejecutarBusquedaCategoria(
                        _currentCategoryCode!,
                        _currentCategoryNombre ?? '',
                      );
                    } else {
                      _ejecutarBusqueda(_currentQuery);
                    }
                  },
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Quitar filtros'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_searchResponse == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Escribe un producto o código de barras',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Encabezado con contador y Grid de productos con soporte de paginación
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : (constraints.maxWidth > 550 ? 3 : 2);

        final paginacion = _searchResponse?.paginacion;
        final mostrarPaginacion =
            paginacion != null && paginacion.tienePaginacion;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Row(
                  children: [
                    M3EButton.tonal(
                      onPressed: _mostrarFiltros,
                      shape: M3EButtonShape.round,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _selectedFilters.count == 0
                            ? 'Filtros'
                            : 'Filtros (${_selectedFilters.count})',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Paginación superior adaptada al espacio disponible (sin scroll)
                    if (mostrarPaginacion)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildPaginationWidget(paginacion),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.54,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final prod = productos[index];
                  return ProductCard(
                    product: prod,
                    onTap: () => _mostrarDetalleProducto(prod),
                  );
                }, childCount: productos.length),
              ),
            ),
            if (mostrarPaginacion)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 28),
                  child: Center(child: _buildPaginationWidget(paginacion)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationWidget(PaginationInfo paginacion) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final availableWidth = constraints.maxWidth;
        // 76px reservados para los botones Anterior/Siguiente (32px cada uno) y padding (12px)
        final availableForNumbers = availableWidth - 76;
        final maxNumbers = (availableForNumbers / 34).floor();

        List<int> visiblePages = [];
        bool showNumberButtons = false;

        if (maxNumbers >= paginacion.paginasDisponibles.length) {
          visiblePages = paginacion.paginasDisponibles;
          showNumberButtons = true;
        } else if (maxNumbers >= 2) {
          final count = maxNumbers.clamp(
            2,
            paginacion.paginasDisponibles.length,
          );
          final currentIndex = paginacion.paginasDisponibles.indexOf(
            paginacion.paginaActual,
          );
          final safeIndex = currentIndex >= 0 ? currentIndex : 0;
          final start = (safeIndex - (count ~/ 2)).clamp(
            0,
            paginacion.paginasDisponibles.length - count,
          );
          visiblePages = paginacion.paginasDisponibles.sublist(
            start,
            start + count,
          );
          showNumberButtons = true;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Anterior
              _buildArrowButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Página anterior',
                onTap: paginacion.tieneAnterior
                    ? () => _irAPagina(paginacion.paginaActual - 1)
                    : null,
              ),

              if (showNumberButtons) ...[
                for (final num in visiblePages)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: num == paginacion.paginaActual
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: num == paginacion.paginaActual
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: num == paginacion.paginaActual
                              ? null
                              : () => _irAPagina(num),
                          child: Center(
                            child: Text(
                              '$num',
                              style: TextStyle(
                                color: num == paginacion.paginaActual
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                                fontSize: 13,
                                fontWeight: num == paginacion.paginaActual
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${paginacion.paginaActual} / ${paginacion.paginasDisponibles.isNotEmpty ? paginacion.paginasDisponibles.last : paginacion.paginaActual}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // Botón Siguiente
              _buildArrowButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Página siguiente',
                onTap: paginacion.tieneSiguiente
                    ? () => _irAPagina(paginacion.paginaActual + 1)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
