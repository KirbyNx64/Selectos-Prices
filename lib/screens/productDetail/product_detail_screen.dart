import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/services/super_selectos_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _producto;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _cantidad = 1;
  final SuperSelectosService _service = SuperSelectosService();

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    _cargarDetallesCompletos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _service.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const brandGreen = Color(0xFF2E6C37);
    const selectosLime = Color(0xFF7EB424);
    const discountRed = Color(0xFFB3261E);
    const discountRedContainer = Color(0xFFF9DEDC);

    final imagenes = _producto.todasLasImagenes;
    final tieneInformacionAdicional =
        (_producto.codigoBarra?.trim().isNotEmpty ?? false) ||
        (_producto.categoria?.trim().isNotEmpty ?? false);

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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                            return Image.network(
                              imagenes[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 72,
                                      color: Colors.grey,
                                    ),
                                  ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 72,
                            color: Colors.grey,
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
                        color: isSelected ? selectosLime : Colors.grey.shade300,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? selectosLime
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Image.network(
                              imagenes[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 24,
                                    color: Colors.grey,
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
                        _producto.promocion!,
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
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: const Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 16),

              // ── Precios y Descuento ──────────────────────────────────
              M3ECard(
                variant: M3ECardVariant.filled,
                borderRadius: BorderRadius.circular(18),
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
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: brandGreen,
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
                              color: Colors.grey.shade600,
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
                          color: discountRedContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ahorras \$${_producto.descuento.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: discountRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Sección Descripción ──────────────────────────────────
              if (_producto.descripcion != null &&
                  _producto.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Descripción',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _producto.descripcion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
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
                ),
              ),
              const SizedBox(height: 12),
              Row(
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
                          onPressed: _cantidad > 1
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
                          onPressed: () => setState(() => _cantidad++),
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
                        onPressed: () {},
                        shape: M3EButtonShape.round,
                        decoration: const M3EButtonDecoration(
                          backgroundColor: WidgetStatePropertyAll(brandGreen),
                        ),
                        label: const Text(
                          'Agregar',
                          style: TextStyle(color: Colors.white),
                        ),
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
