import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/services/favorites_repository.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/widgets/product_card.dart';

enum FavoriteSortOrder {
  alphabetically('A - Z'),
  alphabeticallyDesc('Z - A'),
  newestFirst('Últimos agregados'),
  oldestFirst('Primeros agregados');

  const FavoriteSortOrder(this.label);

  final String label;
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const int _pageSize = 10;
  static const int _maxConcurrentRequests = 4;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SuperSelectosService _service = SuperSelectosService();

  String _query = '';
  FavoriteSortOrder _sortOrder = FavoriteSortOrder.alphabetically;
  int _currentPage = 1;
  int _refreshGeneration = 0;
  bool _isRefreshing = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCurrentPage());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _dismissSearch() {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  bool _matchesQuery(Product product) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return [
      product.nombre,
      product.categoria,
      product.codigoBarra,
      product.supermercado,
    ].whereType<String>().any((value) => value.toLowerCase().contains(query));
  }

  List<Product> _filteredFavorites() {
    return _sortProducts(
      FavoritesRepository.instance.products.where(_matchesQuery).toList(),
    );
  }

  List<Product> _sortProducts(List<Product> products) {
    switch (_sortOrder) {
      case FavoriteSortOrder.alphabetically:
        products.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
      case FavoriteSortOrder.alphabeticallyDesc:
        products.sort(
          (a, b) => b.nombre.toLowerCase().compareTo(a.nombre.toLowerCase()),
        );
      case FavoriteSortOrder.newestFirst:
        break;
      case FavoriteSortOrder.oldestFirst:
        return products.reversed.toList();
    }
    return products;
  }

  List<Product> _productsForPage(List<Product> products, int page) {
    final start = (page - 1) * _pageSize;
    if (start >= products.length) return const [];
    final end = (start + _pageSize).clamp(0, products.length);
    return products.sublist(start, end);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _query = value;
      _currentPage = 1;
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      _refreshCurrentPage,
    );
  }

  Future<void> _goToPage(int page) async {
    if (page == _currentPage || _isRefreshing) return;
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    await _refreshCurrentPage();
  }

  Future<void> _showFilters() async {
    var draftSortOrder = _sortOrder;
    final selection = await showModalBottomSheet<FavoriteSortOrder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasCustomOrder =
                draftSortOrder != FavoriteSortOrder.alphabetically;
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.58,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros y orden',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: hasCustomOrder
                              ? () => setSheetState(
                                  () => draftSortOrder =
                                      FavoriteSortOrder.alphabetically,
                                )
                              : null,
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
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    6,
                                  ),
                                  child: Text(
                                    'Ordenar por',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                RadioGroup<FavoriteSortOrder>(
                                  groupValue: draftSortOrder,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(() => draftSortOrder = value);
                                  },
                                  child: Column(
                                    children: [
                                      for (final order
                                          in FavoriteSortOrder.values)
                                        RadioListTile<FavoriteSortOrder>(
                                          value: order,
                                          title: Text(order.label),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.pop(sheetContext, draftSortOrder),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aplicar'),
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

    if (selection == null || !mounted || selection == _sortOrder) return;
    setState(() {
      _sortOrder = selection;
      _currentPage = 1;
    });
    await _refreshCurrentPage();
  }

  Future<void> _refreshCurrentPage() async {
    if (!mounted) return;
    final favorites = _filteredFavorites();
    if (favorites.isEmpty) {
      if (mounted) setState(() => _isRefreshing = false);
      return;
    }

    final totalPages = (favorites.length / _pageSize).ceil();
    final page = _currentPage.clamp(1, totalPages);
    final products = _productsForPage(favorites, page);
    final generation = ++_refreshGeneration;

    setState(() {
      _currentPage = page;
      _isRefreshing = true;
    });

    final refreshed = <Product>[];
    var nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < products.length) {
        final product = products[nextIndex++];
        if (product.id.trim().isEmpty) {
          refreshed.add(product);
          continue;
        }
        final updated = await _service.obtenerDetalleProductoWeb(
          product.id,
          productoBase: product,
        );
        refreshed.add(updated ?? product);
      }
    }

    try {
      final workerCount = products.length.clamp(1, _maxConcurrentRequests);
      await Future.wait(List.generate(workerCount, (_) => worker()));
      if (!mounted || generation != _refreshGeneration) return;
      await FavoritesRepository.instance.updateProducts(refreshed);
    } finally {
      if (mounted && generation == _refreshGeneration) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = FavoritesRepository.instance;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: M3ESearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onTapOutside: (_) => _dismissSearch(),
            margin: 12,
            focusedMargin: 0,
            expandOnFocus: true,
            hintText: 'Buscar en favoritos...',
            leading: const Icon(Icons.search_rounded),
            showClearButton: true,
            onChanged: _onSearchChanged,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: repository,
          builder: (context, _) {
            if (repository.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final favorites = repository.products;
            if (favorites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          Icons.favorite_border_rounded,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aún no tienes productos favoritos',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Abre el detalle de un producto y toca el corazón para guardarlo aquí.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredProducts = _sortProducts(
              favorites.where(_matchesQuery).toList(),
            );
            if (filteredProducts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          Icons.search_off_rounded,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No hay favoritos que coincidan',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prueba con otro nombre, categoría o código de barras.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_isRefreshing) {
              return Center(
                child: M3ELoadingIndicator(
                  size: 48,
                  color: colorScheme.primary,
                ),
              );
            }

            final totalPages = (filteredProducts.length / _pageSize).ceil();
            final safePage = _currentPage.clamp(1, totalPages);
            final products = _productsForPage(filteredProducts, safePage);

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800
                    ? 4
                    : (constraints.maxWidth > 550 ? 3 : 2);

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                        child: Row(
                          children: [
                            M3EButton.tonal(
                              onPressed: _showFilters,
                              shape: M3EButtonShape.round,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: Text(
                                _sortOrder == FavoriteSortOrder.alphabetically
                                    ? 'Filtros'
                                    : 'Filtros (1)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (totalPages > 1) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildPaginationWidget(totalPages),
                                ),
                              ),
                            ],
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
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _openProduct(context, product),
                          );
                        }, childCount: products.length),
                      ),
                    ),
                    if (totalPages > 1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 28),
                          child: Center(
                            child: _buildPaginationWidget(totalPages),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(producto: product)),
    );
  }

  Widget _buildPaginationWidget(int totalPages) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final availableForNumbers = constraints.maxWidth - 76;
        final maxNumbers = (availableForNumbers / 34).floor();
        final allPages = List.generate(totalPages, (index) => index + 1);

        List<int> visiblePages = [];
        var showNumberButtons = false;
        if (maxNumbers >= totalPages) {
          visiblePages = allPages;
          showNumberButtons = true;
        } else if (maxNumbers >= 2) {
          final count = maxNumbers.clamp(2, totalPages);
          final start = (_currentPage - 1 - (count ~/ 2)).clamp(
            0,
            totalPages - count,
          );
          visiblePages = allPages.sublist(start, start + count);
          showNumberButtons = true;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
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
              _buildArrowButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Página anterior',
                onTap: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
              ),
              if (showNumberButtons)
                for (final page in visiblePages)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: page == _currentPage
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: page == _currentPage
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
                          onTap: page == _currentPage
                              ? null
                              : () => _goToPage(page),
                          child: Center(
                            child: Text(
                              '$page',
                              style: TextStyle(
                                color: page == _currentPage
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                                fontSize: 13,
                                fontWeight: page == _currentPage
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_currentPage / $totalPages',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              _buildArrowButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Página siguiente',
                onTap: _currentPage < totalPages
                    ? () => _goToPage(_currentPage + 1)
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
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 20,
              color: onTap != null
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
