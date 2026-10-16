import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _cantidad = 1;

  void _incrementar() => setState(() => _cantidad++);

  void _decrementar() {
    if (_cantidad > 1) setState(() => _cantidad--);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final m3eTheme = M3ETheme.of(context);
    final colorScheme = m3eTheme.colorScheme;

    // Colores de marca Súper Selectos
    const brandGreen = Color(0xFF2E6C37);
    const discountRed = Color(0xFFB3261E);
    const discountRedContainer = Color(0xFFF9DEDC);

    return RepaintBoundary(
      child: M3ECard(
        variant: M3ECardVariant.elevated,
        borderRadius: BorderRadius.circular(20),
        onPressed: widget.onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Imagen ─────────────────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fondo suave de imagen
                    Container(color: colorScheme.surfaceContainerLowest),

                    // Imagen o placeholder
                    Center(
                      child:
                          product.imagen != null && product.imagen!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imagen!,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              fit: BoxFit.contain,
                              memCacheWidth: 320,
                              errorWidget: (_, _, _) =>
                                  _buildImagePlaceholder(colorScheme),
                              placeholder: (_, _) => const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: brandGreen,
                                  ),
                                ),
                              ),
                            )
                          : _buildImagePlaceholder(colorScheme),
                    ),

                    // Badge de descuento / promoción en esquina superior-derecha
                    if (product.tieneDescuento && product.descuento > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _DiscountBadge(
                          label: '-\$${product.descuento.toStringAsFixed(2)}',
                          backgroundColor: discountRed,
                          foregroundColor: discountRedContainer,
                        ),
                      )
                    else if (product.promocion != null &&
                        product.promocion!.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _DiscountBadge(
                          label: compactPromotionLabel(product.promocion!),
                          backgroundColor: discountRed,
                          foregroundColor: discountRedContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Contenido textual ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría — chip-like label
                  if (product.categoria != null &&
                      product.categoria!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        product.categoria!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  // Nombre del producto
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Precios
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          product.precioFinal != null
                              ? '\$${product.precioFinal!.toStringAsFixed(2)}'
                              : '--',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (product.tieneDescuento &&
                            product.precioOriginal != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${product.precioOriginal!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Controles: cantidad + carrito ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  // Selector de cantidad — ocupa el espacio sobrante sin desbordar
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkResponse(
                              radius: 16,
                              onTap: _decrementar,
                              child: SizedBox(
                                width: 28,
                                height: 36,
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$_cantidad',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkResponse(
                              radius: 16,
                              onTap: _incrementar,
                              child: SizedBox(
                                width: 28,
                                height: 36,
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Botón carrito — tamaño fijo, solo icono
                  M3EIconButton(
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    variant: M3EIconButtonVariant.filled,
                    size: M3EIconButtonSize.sm,
                    shape: M3EIconButtonShapeVariant.round,
                    onPressed: () async {
                      try {
                        await ShoppingCartRepository.instance.addProduct(
                          product,
                          _cantidad,
                        );
                        if (!context.mounted) return;
                        AppSnackbar.success(
                          context,
                          message:
                              '${product.nombre} ($_cantidad) agregado a tu lista',
                          icon: Icons.add_shopping_cart_rounded,
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        AppSnackbar.error(
                          context,
                          message: 'No se pudo guardar el producto',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(M3EColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 4),
        Text(
          'Sin imagen',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Badge compacto para descuentos/promociones, estilo M3E.
class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
