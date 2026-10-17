import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:ota_update/ota_update.dart';
import 'package:super_selectos/models/selectos_branch.dart';
import 'package:super_selectos/services/android_platform_version.dart';
import 'package:super_selectos/services/app_update_service.dart';
import 'package:super_selectos/services/app_theme_controller.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/services/store_selection_controller.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppUpdateService _updateService = AppUpdateService();
  StreamSubscription<OtaEvent>? _updateSubscription;
  bool _checkingForUpdate = false;
  bool _downloadingUpdate = false;
  double? _downloadProgress;

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _updateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.instance;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final storeController = StoreSelectionController.instance;

        return Scaffold(
          appBar: AppBar(
            notificationPredicate: (_) => false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Center(
              child: M3EIconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                variant: M3EIconButtonVariant.tonal,
                size: M3EIconButtonSize.sm,
                shape: M3EIconButtonShapeVariant.round,
                tooltip: 'Volver',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: const Text(
              'Ajustes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Tienda',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: storeController,
                  builder: (context, _) {
                    final branch = storeController.selectedBranch;
                    return Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainer,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => _selectBranch(context),
                        leading: const Icon(Icons.storefront_rounded),
                        title: const Text('Sala de venta'),
                        subtitle: Text(
                          branch?.name ?? 'Selecciona tu sala más cercana',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Text(
                    'La app mostrará únicamente productos disponibles en la sala seleccionada.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Apariencia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    value: themeController.isDarkMode,
                    onChanged: themeController.setDarkMode,
                    secondary: Icon(
                      themeController.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.dark_mode_outlined,
                    ),
                    title: const Text('Tema oscuro'),
                    subtitle: const Text(
                      'Usar colores oscuros en toda la aplicación',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aplicación',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    enabled: !_checkingForUpdate && !_downloadingUpdate,
                    onTap: _checkForUpdate,
                    leading: const Icon(Icons.system_update_rounded),
                    title: Text(
                      _downloadingUpdate
                          ? 'Descargando actualización'
                          : 'Buscar actualizaciones',
                    ),
                    subtitle: Text(_updateSubtitle),
                    trailing: _checkingForUpdate || _downloadingUpdate
                        ? SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              value: _downloadingUpdate
                                  ? _downloadProgress
                                  : null,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Datos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.errorContainer,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => _confirmDeleteAllLists(context),
                    leading: Icon(
                      Icons.delete_sweep_outlined,
                      color: colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      'Eliminar todas las listas',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Borra todas las listas y los productos guardados',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _updateSubtitle {
    if (_checkingForUpdate) return 'Consultando el último release en GitHub…';
    if (_downloadingUpdate) {
      final progress = _downloadProgress;
      return progress == null
          ? 'Preparando descarga…'
          : '${(progress * 100).round()} % completado';
    }
    final version = AndroidPlatformVersion.appVersion;
    return version == null
        ? 'Comprobar la versión disponible en GitHub'
        : 'Versión instalada: $version';
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingForUpdate = true);
    try {
      final update = await _updateService.checkForUpdate();
      if (!mounted) return;
      if (!update.updateAvailable) {
        AppSnackbar.success(
          context,
          message: 'Ya tienes la versión más reciente',
          icon: Icons.verified_rounded,
        );
        return;
      }

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
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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

      if (shouldInstall == true && mounted) {
        _installUpdate(update);
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, message: _readableUpdateError(error));
    } finally {
      if (mounted) setState(() => _checkingForUpdate = false);
    }
  }

  void _installUpdate(AppUpdateCheck update) {
    _updateSubscription?.cancel();
    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = null;
    });

    try {
      _updateSubscription = _updateService
          .install(update)
          .listen(
            _handleOtaEvent,
            onError: (Object error) {
              if (!mounted) return;
              setState(() => _downloadingUpdate = false);
              AppSnackbar.error(
                context,
                message: 'No se pudo descargar la actualización',
              );
            },
            onDone: () {
              if (mounted && _downloadingUpdate) {
                setState(() => _downloadingUpdate = false);
              }
            },
          );
    } catch (error) {
      setState(() => _downloadingUpdate = false);
      AppSnackbar.error(context, message: _readableUpdateError(error));
    }
  }

  void _handleOtaEvent(OtaEvent event) {
    if (!mounted) return;
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final percent = double.tryParse(event.value ?? '');
        setState(() {
          _downloadingUpdate = true;
          _downloadProgress = percent == null
              ? null
              : (percent / 100).clamp(0.0, 1.0);
        });
      case OtaStatus.INSTALLING:
        setState(() => _downloadingUpdate = false);
        AppSnackbar.success(
          context,
          message: 'Descarga completa. Confirma la instalación.',
          icon: Icons.install_mobile_rounded,
        );
      case OtaStatus.INSTALLATION_DONE:
        setState(() => _downloadingUpdate = false);
      case OtaStatus.ALREADY_RUNNING_ERROR:
        _showUpdateError('Ya hay una actualización en curso.');
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _showUpdateError(
          'Autoriza la instalación de apps desconocidas para continuar.',
        );
      case OtaStatus.CANCELED:
        _showUpdateError('La descarga fue cancelada.');
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.DOWNLOAD_ERROR:
      case OtaStatus.CHECKSUM_ERROR:
        _showUpdateError(
          event.value?.isNotEmpty == true
              ? event.value!
              : 'No se pudo instalar la actualización.',
        );
    }
  }

  void _showUpdateError(String message) {
    setState(() => _downloadingUpdate = false);
    AppSnackbar.error(context, message: message);
  }

  String _readableUpdateError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Unsupported operation: ', '');
  }

  Future<void> _selectBranch(BuildContext context) async {
    final controller = StoreSelectionController.instance;
    final selected = await showModalBottomSheet<SelectosBranch>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) => BranchPickerSheet(
        branches: controller.branches,
        selectedBranchId: controller.selectedBranchId,
      ),
    );

    if (selected == null || !context.mounted) return;
    await controller.selectBranch(selected);
    if (!context.mounted) return;
    AppSnackbar.success(
      context,
      message: 'Sala seleccionada: ${selected.name}',
      icon: Icons.storefront_rounded,
    );
  }

  Future<void> _confirmDeleteAllLists(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldDelete = await M3EDialog.show<bool>(
      context,
      dialog: Material(
        type: MaterialType.transparency,
        child: M3EDialog(
          title: '¿Eliminar todas las listas?',
          icon: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
          content: Text(
            'Se eliminarán permanentemente todas las listas de compras y sus productos.',
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
                'Eliminar todo',
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    try {
      await ShoppingCartRepository.instance.deleteAllLists();
      if (!context.mounted) return;
      AppSnackbar.success(
        context,
        message: 'Todas las listas fueron eliminadas',
        icon: Icons.delete_sweep_outlined,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.error(context, message: 'No se pudieron eliminar las listas');
    }
  }
}

class BranchPickerSheet extends StatefulWidget {
  final List<SelectosBranch> branches;
  final String? selectedBranchId;

  const BranchPickerSheet({
    super.key,
    required this.branches,
    required this.selectedBranchId,
  });

  @override
  State<BranchPickerSheet> createState() => _BranchPickerSheetState();
}

class _BranchPickerSheetState extends State<BranchPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedQuery = _normalize(_query);
    final filtered = normalizedQuery.isEmpty
        ? widget.branches
        : widget.branches
              .where((branch) {
                return _normalize(branch.name).contains(normalizedQuery) ||
                    _normalize(branch.address).contains(normalizedQuery);
              })
              .toList(growable: false);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona una sala',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La app mostrará únicamente productos disponibles en la sala seleccionada.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Buscar sala o ubicación',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron salas',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final branch = filtered[index];
                        final selected = branch.id == widget.selectedBranchId;
                        return ListTile(
                          selected: selected,
                          leading: Icon(
                            selected
                                ? Icons.storefront_rounded
                                : Icons.storefront_outlined,
                          ),
                          title: Text(
                            branch.name,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: branch.address.isEmpty
                              ? null
                              : Text(
                                  branch.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, branch),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u');
  }
}
