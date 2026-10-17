import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:ota_update/ota_update.dart';
import 'package:super_selectos/services/android_platform_version.dart';
import 'package:super_selectos/services/app_update_service.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';

class AppUpdateDialog {
  AppUpdateDialog._();

  static bool _hasCheckedThisSession = false;

  /// Comprueba en segundo plano si hay actualización disponible al iniciar la app.
  /// Si existe una nueva versión, muestra el diálogo para actualizar.
  /// En caso de error de red o de estar en la última versión, no interrumpe al usuario.
  static Future<void> checkOnStartup(BuildContext context) async {
    if (_hasCheckedThisSession) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final appVersion = AndroidPlatformVersion.appVersion;
    if (appVersion == null || appVersion.isEmpty) return;

    _hasCheckedThisSession = true;

    try {
      final updateService = AppUpdateService();
      final update = await updateService.checkForUpdate();
      if (!context.mounted) return;

      if (update.updateAvailable) {
        await showUpdatePrompt(context, update, service: updateService);
      }
    } catch (_) {
      // Ignorar errores silenciosamente en el inicio (sin conexión, timeout, etc.)
    }
  }

  /// Muestra el diálogo de confirmación de actualización.
  static Future<bool> showUpdatePrompt(
    BuildContext context,
    AppUpdateCheck update, {
    AppUpdateService? service,
  }) async {
    final shouldInstall = await M3EDialog.show<bool>(
      context,
      dialog: Material(
        type: MaterialType.transparency,
        child: M3EDialog(
          title: 'Actualización ${update.manifest.version}',
          icon: Icon(
            Icons.system_update_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versión instalada: ${update.installedVersion}\n'
                'Nueva versión: ${update.manifest.version}',
              ),
              const SizedBox(height: 16),
              Text(
                'Novedades',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                update.manifest.changelog.isEmpty
                    ? 'Esta versión incluye mejoras y correcciones.'
                    : update.manifest.changelog,
              ),
            ],
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Más tarde'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );

    if (shouldInstall == true && context.mounted) {
      await _downloadAndInstallWithProgress(
        context,
        update,
        service ?? AppUpdateService(),
      );
      return true;
    }
    return false;
  }

  static Future<void> _downloadAndInstallWithProgress(
    BuildContext context,
    AppUpdateCheck update,
    AppUpdateService service,
  ) async {
    StreamSubscription<OtaEvent>? subscription;
    final progressNotifier = ValueNotifier<double?>(null);
    final statusTextNotifier = ValueNotifier<String>('Preparando descarga…');
    BuildContext? dialogContext;

    void closeDialog() {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return PopScope(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: M3EDialog(
              title: 'Descargando actualización',
              icon: Icon(
                Icons.downloading_rounded,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              content: AnimatedBuilder(
                animation: Listenable.merge(
                  [progressNotifier, statusTextNotifier],
                ),
                builder: (animContext, _) {
                  final progress = progressNotifier.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusTextNotifier.value,
                        style: Theme.of(animContext).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
              actions: [
                M3EButton.text(
                  onPressed: () {
                    subscription?.cancel();
                    closeDialog();
                    AppSnackbar.error(context, message: 'Descarga cancelada.');
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      subscription = service.install(update).listen(
        (event) {
          if (!context.mounted) return;
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final percent = double.tryParse(event.value ?? '');
              final clamped = percent == null
                  ? null
                  : (percent / 100).clamp(0.0, 1.0);
              progressNotifier.value = clamped;
              statusTextNotifier.value = clamped == null
                  ? 'Descargando…'
                  : '${(clamped * 100).round()} % completado';
            case OtaStatus.INSTALLING:
              closeDialog();
              AppSnackbar.success(
                context,
                message: 'Descarga completa. Confirma la instalación.',
                icon: Icons.install_mobile_rounded,
              );
            case OtaStatus.INSTALLATION_DONE:
              closeDialog();
            case OtaStatus.ALREADY_RUNNING_ERROR:
              closeDialog();
              AppSnackbar.error(
                context,
                message: 'Ya hay una actualización en curso.',
              );
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              closeDialog();
              AppSnackbar.error(
                context,
                message:
                    'Autoriza la instalación de apps desconocidas para continuar.',
              );
            case OtaStatus.CANCELED:
              closeDialog();
              AppSnackbar.error(context, message: 'La descarga fue cancelada.');
            case OtaStatus.INSTALLATION_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
              closeDialog();
              AppSnackbar.error(
                context,
                message: event.value?.isNotEmpty == true
                    ? event.value!
                    : 'No se pudo instalar la actualización.',
              );
          }
        },
        onError: (Object _) {
          closeDialog();
          if (context.mounted) {
            AppSnackbar.error(
              context,
              message: 'No se pudo descargar la actualización.',
            );
          }
        },
        onDone: () {
          closeDialog();
        },
      );
    } catch (_) {
      closeDialog();
      if (context.mounted) {
        AppSnackbar.error(context, message: 'Error al iniciar la descarga.');
      }
    }
  }
}
