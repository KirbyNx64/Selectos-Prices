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
  String? _selectedDepartment;
  String? _selectedMunicipality;
  SelectosBranch? _selectedBranch;

  bool _isDirectSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedBranchId != null) {
      final match = widget.branches.where((b) => b.id == widget.selectedBranchId).firstOrNull;
      if (match != null) {
        _selectedBranch = match;
        _selectedDepartment = _getDepartment(match);
        _selectedMunicipality = _getMunicipality(match);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDepartment(SelectosBranch branch) {
    if (branch.department.trim().isNotEmpty) return branch.department.trim();
    final addr = branch.address.toLowerCase();
    final name = branch.name.toLowerCase();
    if (addr.contains('sonsonate') || name.contains('sonsonate') || addr.contains('izalco') || addr.contains('juayua') || addr.contains('acajutla') || addr.contains('armenia')) return 'Sonsonate';
    if (addr.contains('ahuachap') || name.contains('ahuachap') || addr.contains('atiquizaya') || name.contains('cara sucia')) return 'Ahuachapán';
    if (addr.contains('cabañas') || addr.contains('ilobasco') || name.contains('sensuntepeque')) return 'Cabañas';
    if (addr.contains('chalatenango') || name.contains('nueva concepción')) return 'Chalatenango';
    if (addr.contains('cojutepeque') || (addr.contains('cuscatlán') && !addr.contains('antiguo cuscatlán'))) return 'Cuscatlán';
    if (addr.contains('morazán') || name.contains('gotera')) return 'Morazán';
    if (addr.contains('la paz') || name.contains('zacatecoluca') || name.contains('olocuilta')) return 'La Paz';
    if (addr.contains('la unión') || addr.contains('la union') || name.contains('santa rosa de lima')) return 'La Unión';
    if (addr.contains('san vicente')) return 'San Vicente';
    if (addr.contains('usulután') || addr.contains('usulutan') || name.contains('jiquilisco') || name.contains('santiago de maría')) return 'Usulután';
    if (addr.contains('san miguel') || name.contains('san miguel') || name.contains('el tránsito')) return 'San Miguel';
    if (addr.contains('santa ana') || name.contains('chalchuapa') || name.contains('metapán')) return 'Santa Ana';
    if (addr.contains('la libertad') || addr.contains('santa tecla') || addr.contains('antiguo cuscatlán') || addr.contains('merliot') || addr.contains('lourdes') || addr.contains('colón') || addr.contains('quezaltepeque') || addr.contains('zaragoza')) return 'La Libertad';
    return 'San Salvador';
  }

  String _getMunicipality(SelectosBranch branch) {
    if (branch.municipality.trim().isNotEmpty) return branch.municipality.trim();
    return branch.name;
  }

  List<String> get _departments {
    final set = <String>{};
    for (final b in widget.branches) {
      final d = _getDepartment(b);
      if (d.isNotEmpty) set.add(d);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<String> get _municipalities {
    if (_selectedDepartment == null) return const [];
    final set = <String>{};
    for (final b in widget.branches) {
      if (_getDepartment(b) == _selectedDepartment) {
        final m = _getMunicipality(b);
        if (m.isNotEmpty) set.add(m);
      }
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<SelectosBranch> get _availableBranches {
    if (_selectedDepartment == null || _selectedMunicipality == null) return const [];
    return widget.branches
        .where((b) =>
            _getDepartment(b) == _selectedDepartment &&
            _getMunicipality(b) == _selectedMunicipality)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _pickDepartment() async {
    final depts = _departments;
    final chosen = await _showOptionsSheet<String>(
      title: 'Departamento',
      subtitle: 'Selecciona el departamento de retiro',
      items: depts,
      selectedItem: _selectedDepartment,
      labelOf: (d) => d,
      icon: Icons.map_outlined,
    );

    if (chosen != null && chosen != _selectedDepartment) {
      setState(() {
        _selectedDepartment = chosen;
        _selectedMunicipality = null;
        _selectedBranch = null;
      });
    }
  }

  Future<void> _pickMunicipality() async {
    final muns = _municipalities;
    final chosen = await _showOptionsSheet<String>(
      title: 'Municipio',
      subtitle: 'Selecciona el municipio en $_selectedDepartment',
      items: muns,
      selectedItem: _selectedMunicipality,
      labelOf: (m) => m,
      icon: Icons.location_city_outlined,
    );

    if (chosen != null && chosen != _selectedMunicipality) {
      setState(() {
        _selectedMunicipality = chosen;
        _selectedBranch = null;
      });
    }
  }

  Future<void> _pickBranch() async {
    final branches = _availableBranches;
    final chosen = await _showOptionsSheet<SelectosBranch>(
      title: 'Sala de venta',
      subtitle: 'Salas en $_selectedMunicipality, $_selectedDepartment',
      items: branches,
      selectedItem: _selectedBranch,
      labelOf: (b) => b.name,
      subtitleOf: (b) => b.address.isNotEmpty ? b.address : null,
      icon: Icons.storefront_rounded,
    );

    if (chosen != null) {
      setState(() {
        _selectedBranch = chosen;
      });
    }
  }

  Future<T?> _showOptionsSheet<T>({
    required String title,
    required String subtitle,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelOf,
    String? Function(T)? subtitleOf,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      builder: (sheetContext) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = filter.isEmpty
                ? items
                : items.where((item) {
                    final normalizedItem = _normalize(labelOf(item));
                    final normalizedFilter = _normalize(filter);
                    final sub = subtitleOf != null ? _normalize(subtitleOf(item) ?? '') : '';
                    return normalizedItem.contains(normalizedFilter) || sub.contains(normalizedFilter);
                  }).toList(growable: false);

            return SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: colorScheme.primary, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.length > 4)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SearchBar(
                          hintText: 'Buscar $title...',
                          leading: const Icon(Icons.search_rounded),
                          trailing: filter.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setModalState(() => filter = ''),
                                  ),
                                ]
                              : null,
                          onChanged: (val) => setModalState(() => filter = val),
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron resultados',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isSelected = selectedItem != null &&
                                    labelOf(item) == labelOf(selectedItem);
                                final subText = subtitleOf?.call(item);

                                return ListTile(
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                  title: Text(
                                    labelOf(item),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: subText != null
                                      ? Text(
                                          subText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(sheetContext, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String? value,
    required String placeholder,
    required bool enabled,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null && value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? colorScheme.surfaceContainerLowest
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: enabled
                      ? (hasValue
                          ? colorScheme.outline.withValues(alpha: 0.4)
                          : colorScheme.outlineVariant)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value : placeholder,
                      style: hasValue
                          ? theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasValue && enabled && onClear != null) ...[
                    const SizedBox(width: 4),
                    InkResponse(
                      radius: 16,
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selecciona una sala',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _isDirectSearchMode ? 'Filtro por departamento' : 'Buscar por nombre',
                        icon: Icon(
                          _isDirectSearchMode ? Icons.filter_alt_outlined : Icons.search_rounded,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isDirectSearchMode = !_isDirectSearchMode;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La app mostrará únicamente productos disponibles en la sala seleccionada.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isDirectSearchMode
                  ? _buildDirectSearchList(context)
                  : _buildWebCascadingSelector(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebCascadingSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownCard(
                  label: 'Departamento de la sala de venta dónde desea retirar los productos',
                  value: _selectedDepartment,
                  placeholder: 'Seleccione el departamento',
                  enabled: true,
                  onTap: _pickDepartment,
                  onClear: () {
                    setState(() {
                      _selectedDepartment = null;
                      _selectedMunicipality = null;
                      _selectedBranch = null;
                    });
                  },
                ),
                _buildDropdownCard(
                  label: 'Municipio de la sala de venta dónde desea retirar los productos',
                  value: _selectedMunicipality,
                  placeholder: _selectedDepartment == null
                      ? 'Primero seleccione un departamento'
                      : 'Seleccione el municipio',
                  enabled: _selectedDepartment != null,
                  onTap: _pickMunicipality,
                  onClear: () {
                    setState(() {
                      _selectedMunicipality = null;
                      _selectedBranch = null;
                    });
                  },
                ),
                _buildDropdownCard(
                  label: 'Seleccione la sala de venta dónde retirará los productos',
                  value: _selectedBranch?.name,
                  placeholder: _selectedMunicipality == null
                      ? 'Primero seleccione un municipio'
                      : 'Seleccione la sala de venta',
                  enabled: _selectedMunicipality != null,
                  onTap: _pickBranch,
                  onClear: () {
                    setState(() {
                      _selectedBranch = null;
                    });
                  },
                ),
                if (_selectedBranch != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBranch!.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedBranch!.address.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedBranch!.address,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_selectedMunicipality, $_selectedDepartment',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _selectedBranch != null
                  ? () => Navigator.pop(context, _selectedBranch)
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Confirmar sala',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectSearchList(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedQuery = _normalize(_searchQuery);
    final filtered = normalizedQuery.isEmpty
        ? widget.branches
        : widget.branches
            .where((branch) {
              return _normalize(branch.name).contains(normalizedQuery) ||
                  _normalize(branch.address).contains(normalizedQuery) ||
                  _normalize(_getDepartment(branch)).contains(normalizedQuery) ||
                  _normalize(_getMunicipality(branch)).contains(normalizedQuery);
            })
            .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Buscar sala por nombre o dirección',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: (value) => setState(() => _searchQuery = value),
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
                    final selected = branch.id == (_selectedBranch?.id ?? widget.selectedBranchId);
                    return ListTile(
                      selected: selected,
                      leading: Icon(
                        selected ? Icons.storefront_rounded : Icons.storefront_outlined,
                      ),
                      title: Text(
                        branch.name,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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
