import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';

/// Pantalla de escaneo de código de barras con cámara.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _procesando = false;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_procesando) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final code = barcode.rawValue!.trim();
    if (code.isEmpty) return;

    // Marcamos como procesando sin setState — evita rebuild innecesario
    _procesando = true;
    await _controller.stop();

    if (!mounted) return;

    // pushReplacement elimina este widget del árbol,
    // NO llamar setState después porque el State ya estará disposed.
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          initialQuery: code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          'Escanear código',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              final isUnavailable = state.torchState == TorchState.unavailable;

              return Center(
                child: M3EIconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  ),
                  variant: M3EIconButtonVariant.tonal,
                  size: M3EIconButtonSize.sm,
                  shape: M3EIconButtonShapeVariant.round,
                  tooltip: isTorchOn ? 'Apagar linterna' : 'Encender linterna',
                  onPressed: isUnavailable ? null : () => _controller.toggleTorch(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cámara ─────────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // ── Overlay oscuro con recorte central ─────────────────────────
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanAreaColor: colorScheme.primary,
            ),
          ),

          // ── Etiqueta de instrucción ─────────────────────────────────────
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Apunta la cámara al código de barras',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_procesando) ...[
                  const SizedBox(height: 16),
                  const M3ELoadingIndicator(size: 32, color: Colors.white),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el overlay oscuro semitransparente con la ventana de escaneo.
class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({required this.scanAreaColor});

  final Color scanAreaColor;

  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 260.0;
    const cl = 28.0; // corner line length
    const cw = 4.0;  // corner line width
    const borderRadius = 16.0;

    final cx = size.width / 2;
    final cy = size.height / 2 - 40;

    final scanRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: scanSize,
      height: scanSize,
    );

    // ── Overlay oscuro con hueco cuadrado-redondeado ────────────────────
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        scanRect,
        const Radius.circular(borderRadius),
      ));
    canvas.drawPath(
      overlayPath..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withValues(alpha: 0.60),
    );

    // ── Esquinas verdes ────────────────────────────────────────────────
    final paint = Paint()
      ..color = scanAreaColor
      ..strokeWidth = cw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final l = scanRect.left + borderRadius;
    final t = scanRect.top + borderRadius;
    final r = scanRect.right - borderRadius;
    final b = scanRect.bottom - borderRadius;

    // Cada esquina: path con dos segmentos en L que se unen en el vértice
    // Superior-izquierda
    canvas.drawPath(
      Path()
        ..moveTo(l, scanRect.top)
        ..lineTo(l + cl, scanRect.top)
        ..moveTo(scanRect.left, t)
        ..lineTo(scanRect.left, t + cl),
      paint,
    );

    // Superior-derecha
    canvas.drawPath(
      Path()
        ..moveTo(r - cl, scanRect.top)
        ..lineTo(r, scanRect.top)
        ..moveTo(scanRect.right, t)
        ..lineTo(scanRect.right, t + cl),
      paint,
    );

    // Inferior-izquierda
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, b - cl)
        ..lineTo(scanRect.left, b)
        ..moveTo(l, scanRect.bottom)
        ..lineTo(l + cl, scanRect.bottom),
      paint,
    );

    // Inferior-derecha
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, b - cl)
        ..lineTo(scanRect.right, b)
        ..moveTo(r - cl, scanRect.bottom)
        ..lineTo(r, scanRect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.scanAreaColor != scanAreaColor;
}
