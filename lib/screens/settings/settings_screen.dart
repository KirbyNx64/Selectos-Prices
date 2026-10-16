import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/services/app_theme_controller.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/widgets/app_snackbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.instance;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
        );
      },
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
