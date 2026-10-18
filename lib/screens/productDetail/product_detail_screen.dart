import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/services/super_selectos_service.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product producto;
  final SuperSelectosService? service;

  const ProductDetailScreen({super.key, required this.producto, this.service});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _producto;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _cantidad = 1;
  bool _verificandoDisponibilidad = false;
  bool? _disponibleEnSala;
  bool _falloDisponibilidad = false;
  bool _abriendoGaleria = false;
  late final SuperSelectosService _service;
  late final bool _ownsService;
  late final Future<void> _cargaDetalles;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? SuperSelectosService();
    _producto = widget.producto;
    _cargaDetalles = _cargarDetallesCompletos();
    _comprobarDisponibilidad();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  Future<void> _cargarDetallesCompletos() async {
    if (_producto.id.isEmpty) return;

    // Si no cuenta con descripción o tiene 1 o menos imágenes, cargamos la ficha web completa
    if (_producto.descripcion == null || _producto.imagenes.length <= 1) {
      try {
        final detalleWeb = await _service.obtenerDetalleProductoWeb(
          _producto.id,
          productoBase: _producto,
        );
        if (mounted && detalleWeb != null) {
          setState(() {
            _producto = detalleWeb;
          });
        }
      } catch (_) {
        // En caso de fallo de red se mantiene la información base
      }
    }
  }

  Future<void> _comprobarDisponibilidad() async {
    if (_producto.id.isEmpty ||
        StoreSelectionController.instance.selectedBranchId == null) {
      return;
    }

    _verificandoDisponibilidad = true;
    try {
      final disponible = await _service
          .comprobarDisponibilidadEnSalaSeleccionada(_producto.id);
      if (!mounted) return;
      setState(() {
        _disponibleEnSala = disponible;
        _verificandoDisponibilidad = false;
        _falloDisponibilidad = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verificandoDisponibilidad = false;
        _falloDisponibilidad = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const brandGreen = Color(0xFF2E6C37);
    const selectosLime = Color(0xFF7EB424);
    const discountRed = Color(0xFFB3261E);

    final imagenes = _producto.todasLasImagenes;
    final tieneInformacionAdicional =
        (_producto.codigoBarra?.trim().isNotEmpty ?? false) ||
        (_producto.categoria?.trim().isNotEmpty ?? false);
    final selectedItem = ShoppingCartItem(
      key: ShoppingCartItem.keyFor(_producto),
      product: _producto,
      quantity: _cantidad,
    );
    final tienePrecio =
        _producto.precioFinal != null || _producto.precio != null;
    final selectedBranch = StoreSelectionController.instance.selectedBranch;
    final productoNoDisponible = _disponibleEnSala == false;
    final controlesDeshabilitados =
        _verificandoDisponibilidad || productoNoDisponible;
    final availabilityContainerColor = productoNoDisponible
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainer;
    final availabilityBorderColor = productoNoDisponible
        ? colorScheme.error.withValues(alpha: 0.45)
        : colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        notificationPredicate: (_) => false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
        title: const Text(
          'Detalle del producto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: M3EIconButton(
                icon: const Icon(Icons.share_outlined),
                variant: M3EIconButtonVariant.tonal,
                size: M3EIconButtonSize.sm,
                shape: M3EIconButtonShapeVariant.round,
                tooltip: 'Compartir enlace',
                onPressed: () => _compartirEnlace(context),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Galería de Imágenes (Main Media Slider) ───────────────
              Center(
                child: Container(
                  width: double.infinity,
                  height: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: imagenes.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: imagenes.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Semantics(
                              button: true,
                              label: 'Abrir imagen en pantalla completa',
                              child: GestureDetector(
                                key: ValueKey('product-image-$index'),
                                behavior: HitTestBehavior.opaque,
                                onTap: _abriendoGaleria
                                    ? null
                                    : () => _abrirImagenPantallaCompleta(index),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: imagenes[index],
                                      fadeInDuration: Duration.zero,
                                      fadeOutDuration: Duration.zero,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) =>
                                          Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 72,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                    ),
                                    if (_abriendoGaleria &&
                                        index == _currentImageIndex)
                                      ColoredBox(
                                        color: colorScheme.surface.withValues(
                                          alpha: 0.62,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 72,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),

              // ── Indicador de Puntos (Dots) ───────────────────────────
              if (imagenes.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imagenes.length, (index) {
                    final isSelected = index == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectosLime
                            : colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // ── Miniaturas (Thumbs Slider) ─────────────────────────
                SizedBox(
                  height: 64,
                  child: Center(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: imagenes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentImageIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? selectosLime
                                    : colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imagenes[index],
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 24,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Categoría y Promoción ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_producto.categoria != null &&
                      _producto.categoria!.isNotEmpty)
                    Expanded(
                      child: Text(
                        _producto.categoria!.toUpperCase(),
                        style: const TextStyle(
                          color: selectosLime,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  if (_producto.promocion != null &&
                      _producto.promocion!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: discountRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        compactPromotionLabel(_producto.promocion!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Nombre del Producto ──────────────────────────────────
              Text(
                _producto.nombre,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // ── Precios y Descuento ──────────────────────────────────
              M3ECard(
                variant: M3ECardVariant.filled,
                borderRadius: BorderRadius.circular(18),
                color: availabilityContainerColor,
                border: BorderSide(color: availabilityBorderColor),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _producto.precioFinal != null
                              ? '\$${_producto.precioFinal!.toStringAsFixed(2)}'
                              : 'No disponible',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_producto.tieneDescuento &&
                            _producto.precioOriginal != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '\$${_producto.precioOriginal!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: colorScheme.onSurfaceVariant,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_producto.tieneDescuento &&
                        _producto.descuento > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ahorras \$${_producto.descuento.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (selectedBranch != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: availabilityContainerColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: availabilityBorderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_verificandoDisponibilidad)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        Icon(
                          productoNoDisponible
                              ? Icons.location_off_outlined
                              : _falloDisponibilidad
                              ? Icons.cloud_off_outlined
                              : Icons.storefront_outlined,
                          size: 22,
                          color: productoNoDisponible
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _verificandoDisponibilidad
                                  ? 'Comprobando disponibilidad'
                                  : productoNoDisponible
                                  ? 'No disponible en esta sala'
                                  : _falloDisponibilidad
                                  ? 'No se pudo comprobar la disponibilidad'
                                  : 'Disponible en esta sala',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: productoNoDisponible
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedBranch.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: productoNoDisponible
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Sección Descripción ──────────────────────────────────
              if (_producto.descripcion != null &&
                  _producto.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Descripción',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _producto.descripcion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // ── Detalles Adicionales ─────────────────────────────────
              if (tieneInformacionAdicional) ...[
                const SizedBox(height: 20),
                Text(
                  'Información adicional',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                if (_producto.codigoBarra != null &&
                    _producto.codigoBarra!.trim().isNotEmpty) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: brandGreen,
                      ),
                    ),
                    title: const Text('Código de Barras'),
                    subtitle: Text(
                      _producto.codigoBarra!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Copiar',
                      onPressed: () =>
                          _copiarCodigo(context, _producto.codigoBarra!),
                    ),
                  ),
                  const Divider(height: 1),
                ],

                if (_producto.categoria != null &&
                    _producto.categoria!.trim().isNotEmpty) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        color: brandGreen,
                      ),
                    ),
                    title: const Text('Categoría'),
                    subtitle: Text(
                      _producto.categoria!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],

              const SizedBox(height: 32),
              Text(
                'Tu producto',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    if (tienePrecio && selectedItem.totalSavings > 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Precio regular',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$${selectedItem.regularSubtotal.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ahorras',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '−\$${selectedItem.totalSavings.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total a pagar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (tienePrecio)
                          Text(
                            '\$${selectedItem.subtotal.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        else
                          Text(
                            'No disponible',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Disminuir cantidad',
                            onPressed: !controlesDeshabilitados && _cantidad > 1
                                ? () => setState(() => _cantidad--)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$_cantidad',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Aumentar cantidad',
                            onPressed: controlesDeshabilitados
                                ? null
                                : () => setState(() => _cantidad++),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: M3EButton.filled(
                          onPressed: controlesDeshabilitados
                              ? null
                              : _agregarALista,
                          shape: M3EButtonShape.round,
                          decoration: M3EButtonDecoration(
                            backgroundColor: WidgetStatePropertyAll(
                              controlesDeshabilitados
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.primary,
                            ),
                          ),
                          label: Text(
                            _verificandoDisponibilidad
                                ? 'Comprobando...'
                                : productoNoDisponible
                                ? 'No disponible'
                                : 'Agregar',
                            style: TextStyle(
                              color: controlesDeshabilitados
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onPrimary,
                            ),
                          ),
                          icon: Icon(
                            Icons.add_shopping_cart_rounded,
                            color: controlesDeshabilitados
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirImagenPantallaCompleta(int requestedIndex) async {
    if (_abriendoGaleria) return;
    setState(() => _abriendoGaleria = true);

    await _cargaDetalles;
    if (!mounted) return;

    final imagenes = _producto.todasLasImagenes;
    if (imagenes.isEmpty) {
      setState(() => _abriendoGaleria = false);
      return;
    }

    final initialIndex = requestedIndex.clamp(0, imagenes.length - 1);
    setState(() => _abriendoGaleria = false);

    final selectedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenProductGallery(
          images: imagenes,
          initialIndex: initialIndex,
        ),
      ),
    );
    if (!mounted || selectedIndex == null) return;

    _pageController.jumpToPage(selectedIndex);
    setState(() => _currentImageIndex = selectedIndex);
  }

  Future<void> _agregarALista() async {
    if (_disponibleEnSala == false || _verificandoDisponibilidad) return;
    try {
      await ShoppingCartRepository.instance.addProduct(_producto, _cantidad);
      if (!mounted) return;
      AppSnackbar.success(
        context,
        message: '${_producto.nombre} ($_cantidad) agregado a tu lista',
        icon: Icons.add_shopping_cart_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, message: 'No se pudo guardar el producto');
    }
  }

  void _compartirEnlace(BuildContext context) {
    final enlace = (_producto.enlace != null && _producto.enlace!.isNotEmpty)
        ? _producto.enlace!
        : 'https://www.superselectos.com/products?productId=${_producto.id}';
    Clipboard.setData(ClipboardData(text: enlace));
  }

  void _copiarCodigo(BuildContext context, String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código $codigo copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FullscreenProductGallery extends StatefulWidget {
  const _FullscreenProductGallery({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenProductGallery> createState() =>
      _FullscreenProductGalleryState();
}

class _FullscreenProductGalleryState extends State<_FullscreenProductGallery> {
  late final PageController _pageController;
  late final List<PhotoViewController> _photoControllers;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _photoControllers = List.generate(
      widget.images.length,
      (_) => PhotoViewController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _photoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _close() => Navigator.pop(context, _currentIndex);

  PhotoViewScaleState _toggleZoom(PhotoViewScaleState currentState) {
    return currentState == PhotoViewScaleState.initial
        ? PhotoViewScaleState.covering
        : PhotoViewScaleState.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('fullscreen-product-gallery'),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: _close,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.images.length > 1
              ? '${_currentIndex + 1} de ${widget.images.length}'
              : 'Imagen del producto',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        loadingBuilder: (context, progress) => Center(
          child: CircularProgressIndicator(
            value: progress?.expectedTotalBytes == null
                ? null
                : progress!.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!,
            color: Colors.white,
          ),
        ),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.images[index]),
          controller: _photoControllers[index],
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 5,
          scaleStateCycle: _toggleZoom,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
