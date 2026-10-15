import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/widgets/product_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String? categoryCode;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    this.categoryCode,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SuperSelectosService _service = SuperSelectosService();

  bool _isLoading = false;
  String? _errorMessage;
  SearchResponse? _searchResponse;
  int _paginaActual = 1;
  String? _currentCategoryCode;
  String? _currentCategoryNombre;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    _currentCategoryCode = widget.categoryCode;
    _currentCategoryNombre = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.categoryCode != null && widget.categoryCode!.isNotEmpty) {
          _ejecutarBusquedaCategoria(widget.categoryCode!, widget.initialQuery);
        } else if (widget.initialQuery.trim().isNotEmpty) {
          _ejecutarBusqueda(widget.initialQuery);
        }
      }
    });
  }

  @override
  void dispose() {
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
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paginaActual = pagina;
      _currentCategoryCode = code;
      _currentCategoryNombre = nombre;
    });

    try {
      final response = await _service.buscarPorCategoria(
        code,
        categoryNombre: nombre,
        pagina: pagina,
      );
      if (!mounted) return;

      setState(() {
        _searchResponse = response;
        _isLoading = false;
        if (response.error != null) {
          _errorMessage = response.error;
        }
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Ocurrió un error inesperado al cargar la categoría: $e';
      });
    }
  }

  Future<void> _ejecutarBusqueda(String query, {int pagina = 1}) async {
    final queryLimpio = query.trim();
    if (queryLimpio.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paginaActual = pagina;
      _currentQuery = queryLimpio;
      _currentCategoryCode = null;
    });

    try {
      final response = await _service.buscarProductosDetallado(
        queryLimpio,
        pagina: pagina,
      );
      if (!mounted) return;

      setState(() {
        _searchResponse = response;
        _isLoading = false;
        if (response.error != null) {
          _errorMessage = response.error;
        }
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ocurrió un error inesperado al buscar: $e';
      });
    }
  }

  void _irAPagina(int nuevaPagina) {
    if (nuevaPagina == _paginaActual || _isLoading) return;
    if (_currentCategoryCode != null && _currentCategoryCode!.isNotEmpty) {
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
        titleSpacing: 0,
        leading: Center(
          child: M3EIconButton(
            icon: const Icon(Icons.arrow_back),
            variant: M3EIconButtonVariant.tonal,
            size: M3EIconButtonSize.sm,
            shape: M3EIconButtonShapeVariant.round,
            tooltip: 'Volver',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: M3ESearchBar(
            focusNode: _searchFocusNode,
            onTapOutside: (_) => _searchFocusNode.unfocus(),
            margin: 0,
            focusedMargin: 0,
            expandOnFocus: false,
            controller: _searchController,
            hintText: 'Buscar producto...',
            leading: const Icon(Icons.search),
            showClearButton: true,
            onSubmitted: _ejecutarBusqueda,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
          ),
        ),
      ),
      body: _buildBody(context, productos),
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


  Widget _buildBody(BuildContext context, List<Product> productos) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [M3ELoadingIndicator(size: 48, color: Color(0xFF2E6C37))],
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
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No se pudo completar la búsqueda',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 20),
              M3EButton.filled(
                onPressed: () => _ejecutarBusqueda(_searchController.text),
                shape: M3EButtonShape.round,
                decoration: const M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(Color(0xFF2E6C37)),
                ),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
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
                'Intenta con otro término o verifica el código de barras ingresado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
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
                    // Botón de filtro de resultados (sin funcionamiento aún)
                    M3EButton.tonal(
                      onPressed: () {
                        // Sin funcionamiento aún (placeholder para filtros)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filtros próximamente disponibles'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      shape: M3EButtonShape.round,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text(
                        'Filtros',
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
            color: const Color(0xFFF1F5ED),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF2E6C37).withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                            ? const Color(0xFF2E6C37)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: num == paginacion.paginaActual
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2E6C37)
                                      .withValues(alpha: 0.28),
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
                                    ? Colors.white
                                    : const Color(0xFF2E6C37),
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
                    style: const TextStyle(
                      color: Color(0xFF2E6C37),
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
                  ? const Color(0xFF2E6C37)
                  : const Color(0xFFBDBDBD),
            ),
          ),
        ),
      ),
    );
  }
}
