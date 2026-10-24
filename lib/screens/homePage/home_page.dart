import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:super_selectos/models/category.dart';
import 'package:super_selectos/models/offer_campaign.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/screens/categories/subcategories_screen.dart';
import 'package:super_selectos/screens/favorites/favorites_screen.dart';
import 'package:super_selectos/screens/homePage/barcode_scanner_screen.dart';
import 'package:super_selectos/screens/productDetail/product_detail_screen.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';
import 'package:super_selectos/screens/settings/settings_screen.dart';
import 'package:super_selectos/services/android_platform_version.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';
import 'package:super_selectos/widgets/app_update_dialog.dart';
import 'package:super_selectos/widgets/product_card.dart';

enum _ShoppingListEditAction { editName, editDate, editTime, sort, delete }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static const int _offerBannerCacheWidth = 1200;
  static const double _expandedHomeAppBarHeight = 124;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _offersScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();
  final PageController _offerBannerController = PageController();
  late final M3ENavigationBarController _navController;
  Timer? _offerBannerTimer;
  int barIndex = 0;
  bool _consumeBackForActiveSearch = false;
  bool _isCartSummaryExpanded = false;

  final SuperSelectosService _service = SuperSelectosService();
  final ShoppingCartRepository _cart = ShoppingCartRepository.instance;
  List<Product> _productosInicio = [];
  bool _cargandoProductosInicio = true;
  String? _errorProductosInicio;
  int _cantidadAMostrar = 12;
  List<OfferCampaign> _offerCampaigns = const [];
  List<OfferCampaign> _offerBanners = const [];
  bool _loadingOfferCampaigns = false;
  bool _offerCampaignsLoaded = false;
  bool _offerCampaignsError = false;
  List<Product> _officialAppOffers = const [];
  bool _loadingOfficialAppOffers = false;
  bool _officialAppOffersLoaded = false;
  bool _officialAppOffersError = false;

  final List<MainCategory> _categorias = listaCategoriasPrincipales;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navController = M3ENavigationBarController();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_trackActiveSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectInitialBranchAndLoadProducts();
    });
  }

  Future<void> _selectInitialBranchAndLoadProducts() async {
    final storeController = StoreSelectionController.instance;

    // Algunos widget tests construyen esta pantalla sin ejecutar main().
    if (storeController.branches.isEmpty) {
      await _cargarProductosInicio();
      if (mounted) {
        AppUpdateDialog.checkOnStartup(context);
      }
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
    if (!mounted) return;
    AppUpdateDialog.checkOnStartup(context);
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
    WidgetsBinding.instance.removeObserver(this);
    _offerBannerTimer?.cancel();
    _offerBannerController.dispose();
    _navController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoriesScrollController.dispose();
    _offersScrollController.dispose();
    _cartScrollController.dispose();
    _searchFocusNode.removeListener(_trackActiveSearch);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
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

  void _scrollActiveSectionToTop(int index) {
    final controller = switch (index) {
      0 => _scrollController,
      1 => _categoriesScrollController,
      2 => _offersScrollController,
      3 => _cartScrollController,
      _ => null,
    };

    if (controller == null || !controller.hasClients) return;
    final top = controller.position.minScrollExtent;
    if (controller.offset <= top) return;

    controller.animateTo(
      top,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
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
      // Android 16 puede retirar el foco al comenzar el gesto predictivo.
      // Conservamos la marca hasta que PopScope reciba el final del gesto.
      _searchFocusNode.unfocus();
      return;
    }

    _dismissSearch();
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

  Future<void> _loadOfferCampaigns() async {
    if (_loadingOfferCampaigns) return;
    setState(() {
      _loadingOfferCampaigns = true;
      _offerCampaignsError = false;
    });
    try {
      final content = await _service.obtenerContenidoOfertas();
      if (!mounted) return;
      await _precacheOfferBanners(content.banners);
      if (!mounted) return;
      setState(() {
        _offerCampaigns = content.campaigns;
        _offerBanners = content.banners;
        _loadingOfferCampaigns = false;
        _offerCampaignsLoaded = true;
      });
      _startOfferBannerTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingOfferCampaigns = false;
        _offerCampaignsLoaded = true;
        _offerCampaignsError = true;
      });
    }
  }

  Future<void> _loadOfficialAppOffers({bool forceRefresh = false}) async {
    if (_loadingOfficialAppOffers) return;
    setState(() {
      _loadingOfficialAppOffers = true;
      _officialAppOffersError = false;
    });
    try {
      final products = await _service.obtenerOfertasAppOficial(
        forzarRefresco: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _officialAppOffers = products;
        _loadingOfficialAppOffers = false;
        _officialAppOffersLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingOfficialAppOffers = false;
        _officialAppOffersLoaded = true;
        _officialAppOffersError = true;
      });
    }
  }

  Future<void> _precacheOfferBanners(List<OfferCampaign> banners) async {
    await Future.wait(
      banners.map((banner) async {
        try {
          final provider = ResizeImage.resizeIfNeeded(
            _offerBannerCacheWidth,
            null,
            CachedNetworkImageProvider(banner.imageUrl),
          );
          await precacheImage(provider, context);
        } catch (_) {
          // Un banner fallido no debe impedir que se muestren los demás.
        }
      }),
    );
  }

  void _startOfferBannerTimer() {
    _offerBannerTimer?.cancel();
    if (_offerBanners.length < 2) return;
    _offerBannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || barIndex != 2 || !_offerBannerController.hasClients) {
        return;
      }
      final currentPage = _offerBannerController.page?.round() ?? 0;
      if (currentPage >= _offerBanners.length - 1) {
        _offerBannerController.jumpToPage(0);
      } else {
        _offerBannerController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _openOfferCampaign(OfferCampaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          initialQuery: campaign.title,
          landingUrl: campaign.url,
        ),
      ),
    );
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

    _dismissSearch();

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
      bottomNavigationBar: ColoredBox(
        color: colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            M3ENavigationBar(
              backgroundColor: colorScheme.surface,
              elevation: 0,
              controller: _navController,
              scrollController: barIndex == 0 ? _scrollController : null,
              hideOnScroll: true,
              safeArea: false,
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
                if (i == barIndex) {
                  _scrollActiveSectionToTop(i);
                  return;
                }
                if (i == 2 &&
                    !_offerCampaignsLoaded &&
                    !_loadingOfferCampaigns) {
                  _loadOfferCampaigns();
                }
                if (i == 2 &&
                    !_officialAppOffersLoaded &&
                    !_loadingOfficialAppOffers) {
                  _loadOfficialAppOffers();
                }
                setState(() {
                  barIndex = i;
                  if (i != 0) {
                    _dismissSearch();
                  }
                });
              },
            ),
            // M3ENavigationBar colapsa toda su altura al ocultarse. Conserva
            // fuera de ella el área reservada para la navegación del sistema.
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );

    return ListenableBuilder(
      listenable: _searchFocusNode,
      child: scaffold,
      builder: (context, child) {
        return PopScope(
          // Debe permanecer estable durante todo el gesto predictivo. Android
          // 16 puede cerrar el IME antes de terminarlo y reconstruir este árbol.
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_consumeBackForActiveSearch) {
              setState(() => _consumeBackForActiveSearch = false);
              _searchFocusNode.unfocus();
              FocusScope.of(context).unfocus();
              return;
            }
            if (barIndex != 0) {
              setState(() => barIndex = 0);
              return;
            }
            SystemNavigator.pop();
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
            ListenableBuilder(
              listenable: _cart,
              builder: (context, _) {
                final selectedList = _cart.selectedList;
                return Text(
                  selectedList?.displayName ?? 'Lista de compras',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            ListenableBuilder(
              listenable: _cart,
              builder: (context, _) {
                final selectedList = _cart.selectedList;
                if (selectedList == null) return const SizedBox.shrink();
                final itemLabel = _cart.totalItems == 1
                    ? '1 producto'
                    : '${_cart.totalItems} productos';
                return Text(
                  '${selectedList.dateTimeLabel} · $itemLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          M3EMenu(
            position: M3EMenuAnchorPosition.bottomEnd,
            onSelected: (value) {
              if (value is _ShoppingListEditAction) {
                _handleShoppingListEditAction(value);
              }
            },
            anchorBuilder: (context, openMenu) {
              return Center(
                child: M3EIconButton(
                  icon: const Icon(Icons.edit_calendar_rounded),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  shape: M3EIconButtonShapeVariant.round,
                  tooltip: 'Editar lista',
                  onPressed: _cart.selectedList == null ? null : openMenu,
                ),
              );
            },
            children: const [
              M3EMenuGroup(
                label: 'Editar lista',
                children: [
                  M3EMenuEntry(
                    label: 'Cambiar nombre',
                    value: _ShoppingListEditAction.editName,
                    leading: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                  M3EMenuEntry(
                    label: 'Editar fecha',
                    value: _ShoppingListEditAction.editDate,
                    leading: Icon(Icons.calendar_today_rounded),
                  ),
                  M3EMenuEntry(
                    label: 'Editar hora',
                    value: _ShoppingListEditAction.editTime,
                    leading: Icon(Icons.schedule_rounded),
                  ),
                  M3EMenuEntry(
                    label: 'Ordenar productos',
                    value: _ShoppingListEditAction.sort,
                    leading: Icon(Icons.sort_rounded),
                  ),
                  M3EMenuEntry(
                    label: 'Eliminar lista',
                    value: _ShoppingListEditAction.delete,
                    leading: Icon(Icons.delete_outline_rounded),
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
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
                      label: list.displayName,
                      supportingText: list.dateTimeLabel,
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
      toolbarHeight: _expandedHomeAppBarHeight,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selectos Prices',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ListenableBuilder(
                        listenable: StoreSelectionController.instance,
                        builder: (context, _) {
                          final branch =
                              StoreSelectionController.instance.selectedBranch;
                          if (branch == null) return const SizedBox.shrink();
                          return Text(
                            branch.name,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.82,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                M3EIconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  shape: M3EIconButtonShapeVariant.round,
                  tooltip: 'Mis productos',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
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
                      if (_officialAppOffersLoaded) {
                        _loadOfficialAppOffers(forceRefresh: true);
                      }
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
                  onTapOutside: _handleSearchTapOutside,
                  margin: 12,
                  focusedMargin: 0,
                  expandOnFocus: true,
                  controller: _searchController,
                  hintText: '¿Qué estás buscando?',
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
                          tooltip: hasQuery
                              ? 'Buscar'
                              : 'Escanear código de barras',
                          onPressed: hasQuery
                              ? () => _irAResultados(value.text)
                              : () {
                                  _dismissSearch();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BarcodeScannerScreen(),
                                    ),
                                  );
                                },
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
    return IndexedStack(
      index: barIndex,
      children: [
        TickerMode(
          enabled: barIndex == 0,
          child: _buildInicioView(theme, colorScheme),
        ),
        TickerMode(
          enabled: barIndex == 1,
          child: _buildCategoriasView(theme, colorScheme),
        ),
        TickerMode(
          enabled: barIndex == 2,
          child: _buildOfertasView(theme, colorScheme),
        ),
        TickerMode(
          enabled: barIndex == 3,
          child: _buildCarritoView(theme, colorScheme),
        ),
      ],
    );
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
              ],
            ),
          ),
        ),

        // ── Grid o Estado de Carga de Productos de Inicio ────────────
        if (_cargandoProductosInicio)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: M3ELoadingIndicator(size: 40, color: colorScheme.primary),
            ),
          )
        else if (_errorProductosInicio != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
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
              ),
            ),
          )
        else if (_productosInicio.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('No hay productos disponibles por el momento.'),
              ),
            ),
          )
        else ...[
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
    return _PressableInkWell(
      onTap: () => _abrirCategoria(item),
      borderRadius: BorderRadius.circular(22),
      semanticLabel: 'Abrir categoría ${item.nombre}',
      showInkEffect: false,
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
      controller: _categoriesScrollController,
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
        return _PressableInkWell(
          onTap: () => _abrirCategoria(item),
          borderRadius: BorderRadius.circular(22),
          semanticLabel: 'Abrir categoría ${item.nombre}',
          showInkEffect: false,
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
    if ((_loadingOfferCampaigns || !_offerCampaignsLoaded) &&
        (_loadingOfficialAppOffers || !_officialAppOffersLoaded)) {
      return Center(
        child: M3ELoadingIndicator(size: 48, color: colorScheme.primary),
      );
    }

    if (_offerCampaignsError && _officialAppOffersError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudieron cargar las ofertas',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Revisa tu conexión e inténtalo nuevamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              M3EButton.filled(
                onPressed: () {
                  _loadOfferCampaigns();
                  _loadOfficialAppOffers(forceRefresh: true);
                },
                label: const Text('Reintentar'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      );
    }

    if (_offerCampaigns.isEmpty &&
        _officialAppOffers.isEmpty &&
        !_loadingOfficialAppOffers) {
      return Center(
        child: Text(
          'No hay campañas disponibles por el momento.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final campaignCrossAxisCount = constraints.maxWidth >= 1000
            ? 6
            : (constraints.maxWidth >= 700
                  ? 4
                  : (constraints.maxWidth >= 480 ? 3 : 2));
        return CustomScrollView(
          controller: _offersScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (_offerBanners.isNotEmpty)
              SliverToBoxAdapter(child: _buildOfferBannerCarousel(colorScheme)),
            if (_offerCampaigns.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  _offerBanners.isEmpty ? 12 : 4,
                  12,
                  24,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: campaignCrossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final campaign = _offerCampaigns[index];
                    return _OfferCampaignCard(
                      campaign: campaign,
                      colorScheme: colorScheme,
                      onTap: () => _openOfferCampaign(campaign),
                    );
                  }, childCount: _offerCampaigns.length),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Más ofertas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (_loadingOfficialAppOffers || !_officialAppOffersLoaded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: M3ELoadingIndicator(
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              )
            else if (_officialAppOffersError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    children: [
                      Text(
                        'No se pudieron cargar las ofertas de productos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      M3EButton.outlined(
                        onPressed: () =>
                            _loadOfficialAppOffers(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_officialAppOffers.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Text(
                    'No hay ofertas de productos disponibles por el momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 1000
                        ? 4
                        : (constraints.maxWidth >= 700 ? 3 : 2),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.54,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = _officialAppOffers[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _mostrarDetalleProducto(product),
                    );
                  }, childCount: _officialAppOffers.length),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfferBannerCarousel(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth >= 700 ? 4.0 : 2.45;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: PageView.builder(
                  controller: _offerBannerController,
                  itemCount: _offerBanners.length,
                  itemBuilder: (context, index) {
                    final banner = _offerBanners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: colorScheme.surfaceContainerLow,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: _PressableInkWell(
                          onTap: () => _openOfferCampaign(banner),
                          borderRadius: BorderRadius.circular(18),
                          semanticLabel: 'Ver oferta ${banner.title}',
                          pressedScale: 0.98,
                          child: CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            memCacheWidth: _offerBannerCacheWidth,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            errorWidget: (_, _, _) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_offerBanners.length > 1) ...[
                const SizedBox(height: 10),
                SmoothPageIndicator(
                  controller: _offerBannerController,
                  count: _offerBanners.length,
                  effect: ExpandingDotsEffect(
                    dotWidth: 7,
                    dotHeight: 7,
                    spacing: 5,
                    expansionFactor: 3,
                    activeDotColor: colorScheme.primary,
                    dotColor: colorScheme.outlineVariant,
                  ),
                  onDotClicked: (index) {
                    _offerBannerController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
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
                controller: _cartScrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _cart.items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildShoppingProgress(theme, colorScheme);
                  }
                  return _buildShoppingListItem(
                    _cart.items[index - 1],
                    theme,
                    colorScheme,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.bottomCenter,
                        child: _isCartSummaryExpanded
                            ? Column(
                                children: [
                                  _buildCartSummaryRow(
                                    label: 'Total de compra',
                                    amount: _cart.purchaseTotal,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildCartSummaryRow(
                                    label: 'Ahorro total',
                                    amount: _cart.totalSavings,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 7),
                                    child: Divider(height: 1),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Semantics(
                      button: true,
                      expanded: _isCartSummaryExpanded,
                      label: _isCartSummaryExpanded
                          ? 'Ocultar desglose de compra'
                          : 'Mostrar desglose de compra',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(
                          () =>
                              _isCartSummaryExpanded = !_isCartSummaryExpanded,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildCartSummaryRow(
                                  label: 'Total final',
                                  amount: _cart.estimatedTotal,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  emphasized: true,
                                  amountColor: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: _isCartSummaryExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOutCubic,
                                child: Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildCartSummaryRow({
    required String label,
    required double amount,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool emphasized = false,
    Color? amountColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              (emphasized
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: emphasized
                        ? (amountColor ?? colorScheme.onSurface)
                        : colorScheme.onSurfaceVariant,
                    fontSize: emphasized ? 20 : null,
                    fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                  ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style:
              (emphasized
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(
                    color: amountColor,
                    fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                  ),
        ),
      ],
    );
  }

  Widget _buildShoppingProgress(ThemeData theme, ColorScheme colorScheme) {
    final total = _cart.totalItems;
    final checked = _cart.checkedItems;
    final remaining = _cart.remainingItems;
    final progress = total == 0 ? 0.0 : checked / total;
    final finished = remaining == 0;

    return Semantics(
      label: '$checked de $total productos tomados. $remaining faltantes.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  finished ? Icons.task_alt_rounded : Icons.checklist_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finished
                        ? 'Compra completada'
                        : '$checked de $total tomados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: finished
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!finished)
                  Text(
                    '$remaining ${remaining == 1 ? 'falta' : 'faltan'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShoppingListSelection(int listId) async {
    try {
      if (listId == -1) {
        await _promptCreateNewList();
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

  Future<void> _promptCreateNewList() async {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: Material(
        type: MaterialType.transparency,
        child: M3EDialog(
          title: 'Nueva lista de compras',
          icon: Icon(
            Icons.add_shopping_cart_rounded,
            color: colorScheme.primary,
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej. Supermercado semanal (opcional)',
                labelText: 'Nombre de la lista',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => Navigator.pop(context, true),
            ),
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(context, true),
              shape: M3EButtonShape.round,
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final name = controller.text.trim();
    await _cart.createList(name: name.isEmpty ? null : name);
    if (!mounted) return;
    setState(() {});
    AppSnackbar.success(
      context,
      message: 'Lista creada',
      icon: Icons.playlist_add_rounded,
    );
  }

  Future<void> _handleShoppingListEditAction(
    _ShoppingListEditAction action,
  ) async {
    switch (action) {
      case _ShoppingListEditAction.editName:
        await _editSelectedListName();
      case _ShoppingListEditAction.editDate:
        await _editSelectedListDate();
      case _ShoppingListEditAction.editTime:
        await _editSelectedListTime();
      case _ShoppingListEditAction.sort:
        await _showShoppingListSortOptions();
      case _ShoppingListEditAction.delete:
        await _confirmDeleteSelectedList();
    }
  }

  Future<void> _showShoppingListSortOptions() async {
    final options = <(ShoppingListSortOrder, String, IconData)>[
      (
        ShoppingListSortOrder.nameAscending,
        'Nombre: A a Z',
        Icons.sort_by_alpha_rounded,
      ),
      (
        ShoppingListSortOrder.nameDescending,
        'Nombre: Z a A',
        Icons.sort_by_alpha_rounded,
      ),
      (
        ShoppingListSortOrder.priceAscending,
        'Precio más bajo',
        Icons.arrow_upward_rounded,
      ),
      (
        ShoppingListSortOrder.priceDescending,
        'Precio más alto',
        Icons.arrow_downward_rounded,
      ),
      (
        ShoppingListSortOrder.addedAscending,
        'Primero añadido',
        Icons.first_page_rounded,
      ),
      (
        ShoppingListSortOrder.addedDescending,
        'Último añadido',
        Icons.last_page_rounded,
      ),
    ];

    final selected = await showModalBottomSheet<ShoppingListSortOrder>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ordenar productos',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(option.$3),
                title: Text(option.$2),
                selected: option.$1 == _cart.sortOrder,
                trailing: option.$1 == _cart.sortOrder
                    ? Icon(Icons.check_rounded, color: colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, option.$1),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );

    if (selected != null) {
      _cart.setSortOrder(selected);
    }
  }

  Future<void> _editSelectedListName() async {
    final selectedList = _cart.selectedList;
    if (selectedList == null) return;
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: selectedList.name ?? '');

    final newName = await M3EDialog.show<String>(
      context,
      dialog: Material(
        type: MaterialType.transparency,
        child: M3EDialog(
          title: 'Nombre de la lista',
          icon: Icon(
            Icons.drive_file_rename_outline_rounded,
            color: colorScheme.primary,
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej. Supermercado semanal',
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => controller.clear(),
                ),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(context, controller.text),
              shape: M3EButtonShape.round,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (newName == null || !mounted) return;

    try {
      await _cart.updateSelectedListName(newName);
      if (!mounted) return;
      setState(() {});
      AppSnackbar.success(
        context,
        message: 'Nombre actualizado',
        icon: Icons.drive_file_rename_outline_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo actualizar el nombre');
    }
  }

  Future<void> _editSelectedListDate() async {
    final selectedList = _cart.selectedList;
    if (selectedList == null) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: selectedList.createdAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Editar fecha de la lista',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (selectedDate == null || !mounted) return;

    final updatedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedList.createdAt.hour,
      selectedList.createdAt.minute,
    );
    await _saveSelectedListDateTime(updatedDateTime, 'Fecha actualizada');
  }

  Future<void> _editSelectedListTime() async {
    final selectedList = _cart.selectedList;
    if (selectedList == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedList.createdAt),
      helpText: 'Editar hora de la lista',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (selectedTime == null || !mounted) return;

    final updatedDateTime = DateTime(
      selectedList.createdAt.year,
      selectedList.createdAt.month,
      selectedList.createdAt.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    await _saveSelectedListDateTime(updatedDateTime, 'Hora actualizada');
  }

  Future<void> _saveSelectedListDateTime(
    DateTime dateTime,
    String successMessage,
  ) async {
    try {
      await _cart.updateSelectedListDateTime(dateTime);
      if (!mounted) return;
      setState(() {});
      AppSnackbar.success(
        context,
        message: successMessage,
        icon: Icons.edit_calendar_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo actualizar la lista');
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
    final takeAndPayPromotion = item.takeAndPayPromotion;
    final secondUnitDiscountPromotion = item.secondUnitDiscountPromotion;
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
    final contentColor = item.isChecked
        ? colorScheme.onSurface.withValues(alpha: 0.55)
        : colorScheme.onSurface;
    final quantityControlColor = item.isChecked
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final quantityContentColor = item.isChecked
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    return M3ECard(
      variant: M3ECardVariant.outlined,
      elevation: 0,
      color: item.isChecked
          ? colorScheme.primaryContainer.withValues(alpha: 0.18)
          : colorScheme.surfaceContainerLowest,
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCheckedVisual(item, colorScheme),
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
                          color: contentColor,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              color: item.unitDiscount > 0
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: item.unitDiscount > 0
                                  ? FontWeight.w700
                                  : null,
                            ),
                          ),
                          if (item.unitDiscount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '\$${item.regularUnitPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.unitDiscount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '-\$${item.unitDiscount.toStringAsFixed(2)} de descuento',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                      ] else if (takeAndPayPromotion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${takeAndPayPromotion.takeQuantity}x'
                          '${takeAndPayPromotion.payQuantity}'
                          '${hasAppliedPromotion ? ' · Oferta aplicada' : ''}',
                          style: TextStyle(
                            color: hasAppliedPromotion
                                ? colorScheme.primary
                                : colorScheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else if (secondUnitDiscountPromotion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '2ª unidad -${secondUnitDiscountPromotion.discountPercent}%'
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
                          color: quantityControlColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Disminuir cantidad',
                              colorScheme: colorScheme,
                              foregroundColor: quantityContentColor,
                              onPressed: item.quantity > 1
                                  ? () => _updateCartQuantity(
                                      item,
                                      item.quantity - 1,
                                    )
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
                                  color: quantityContentColor,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Aumentar cantidad',
                              colorScheme: colorScheme,
                              foregroundColor: quantityContentColor,
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
                    if (item.totalSavings > 0)
                      Text(
                        '\$${item.regularSubtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 17,
                        color: item.totalSavings > 0
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 104,
            child: _buildCheckedHitTarget(item),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required Color foregroundColor,
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
                  ? foregroundColor
                  : foregroundColor.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckedVisual(ShoppingCartItem item, ColorScheme colorScheme) {
    final product = item.product;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colorScheme.surfaceContainerLowest,
              ),
              child: product.imagen?.isNotEmpty ?? false
                  ? CachedNetworkImage(
                      imageUrl: product.imagen!,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.isChecked
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: item.isChecked
                    ? null
                    : Border.all(color: colorScheme.outline, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                item.isChecked ? Icons.check_rounded : null,
                size: 24,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedHitTarget(ShoppingCartItem item) {
    final label = item.isChecked
        ? 'Marcar como pendiente'
        : 'Marcar como tomado';

    return Semantics(
      button: true,
      checked: item.isChecked,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _updateCartChecked(item, !item.isChecked),
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

  Future<void> _updateCartChecked(ShoppingCartItem item, bool isChecked) async {
    try {
      await _cart.updateChecked(item.key, isChecked);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        message: 'No se pudo actualizar el estado del producto',
      );
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

class _OfferCampaignCard extends StatefulWidget {
  const _OfferCampaignCard({
    required this.campaign,
    required this.colorScheme,
    required this.onTap,
  });

  final OfferCampaign campaign;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  State<_OfferCampaignCard> createState() => _OfferCampaignCardState();
}

class _OfferCampaignCardState extends State<_OfferCampaignCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return Semantics(
      button: true,
      label: 'Ver campaña ${widget.campaign.title}',
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: Duration(milliseconds: _pressed ? 80 : 140),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: Material(
          color: colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            onTap: widget.onTap,
            child: CachedNetworkImage(
              imageUrl: widget.campaign.imageUrl,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              errorWidget: (_, _, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.campaign.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableInkWell extends StatefulWidget {
  const _PressableInkWell({
    required this.onTap,
    required this.borderRadius,
    required this.semanticLabel,
    required this.child,
    this.pressedScale = 0.94,
    this.showInkEffect = true,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final String semanticLabel;
  final Widget child;
  final double pressedScale;
  final bool showInkEffect;

  @override
  State<_PressableInkWell> createState() => _PressableInkWellState();
}

class _PressableInkWellState extends State<_PressableInkWell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _pressed ? 80 : 140),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: InkWell(
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          splashFactory: widget.showInkEffect ? null : NoSplash.splashFactory,
          overlayColor: widget.showInkEffect
              ? null
              : const WidgetStatePropertyAll(Colors.transparent),
          child: widget.child,
        ),
      ),
    );
  }
}
