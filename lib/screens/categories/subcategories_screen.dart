import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/models/category.dart';
import 'package:super_selectos/screens/searchResults/search_results_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final MainCategory category;

  const SubcategoriesScreen({super.key, required this.category});

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  static const brandGreen = Color(0xFF2E6C37);

  final TextEditingController _filterController = TextEditingController();
  final FocusNode _filterFocusNode = FocusNode();
  String _filterQuery = '';

  @override
  void dispose() {
    _filterFocusNode.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _abrirProductos(BuildContext context, String nombre, String codigo) {
    _filterFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchResultsScreen(initialQuery: nombre, categoryCode: codigo),
      ),
    );
  }

  int get _totalSubcategorias {
    var count = 0;
    for (final g in widget.category.grupos) {
      count += g.subcategorias.isNotEmpty ? g.subcategorias.length : 1;
    }
    return count;
  }

  List<CategoryGroup> get _filteredGroups {
    final query = _filterQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.category.grupos;
    }

    final result = <CategoryGroup>[];
    for (final grupo in widget.category.grupos) {
      final groupMatches = grupo.nombre.toLowerCase().contains(query);
      final matchingSubs = grupo.subcategorias
          .where((sub) => sub.nombre.toLowerCase().contains(query))
          .toList();

      if (groupMatches) {
        result.add(grupo);
      } else if (matchingSubs.isNotEmpty) {
        result.add(
          CategoryGroup(
            id: grupo.id,
            nombre: grupo.nombre,
            subcategorias: matchingSubs,
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredGroups = _filteredGroups;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bannerForeground = isDarkMode
        ? colorScheme.onPrimaryContainer
        : Colors.white;
    final bannerButtonBackground = isDarkMode
        ? colorScheme.primary
        : Colors.white;
    final bannerButtonForeground = isDarkMode
        ? colorScheme.onPrimary
        : brandGreen;

    final scaffold = Scaffold(
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
            onPressed: () {
              if (_filterFocusNode.hasFocus) {
                _filterFocusNode.unfocus();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: Text(
          widget.category.tituloCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Banner Header M3E estilo Súper Selectos ────────────
              M3ECard(
                variant: M3ECardVariant.filled,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [
                              colorScheme.primaryContainer,
                              Color.alphaBlend(
                                colorScheme.primary.withValues(alpha: 0.12),
                                colorScheme.primaryContainer,
                              ),
                            ]
                          : const [Color(0xFF1B4E24), Color(0xFF2E6C37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: bannerForeground.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.category.icon,
                              color: bannerForeground,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.tituloCompleto,
                                  style: TextStyle(
                                    color: bannerForeground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.category.grupos.length} grupos · $_totalSubcategorias subcategorías',
                                  style: TextStyle(
                                    color: bannerForeground.withValues(
                                      alpha: 0.82,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Botón de acción destacado "Ver todo"
                      M3EButton.filled(
                        onPressed: () => _abrirProductos(
                          context,
                          'Todos en ${widget.category.tituloCompleto}',
                          widget.category.id,
                        ),
                        shape: M3EButtonShape.round,
                        decoration: M3EButtonDecoration(
                          backgroundColor: WidgetStatePropertyAll(
                            bannerButtonBackground,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            bannerButtonForeground,
                          ),
                        ),
                        icon: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: bannerButtonForeground,
                        ),
                        label: Text(
                          'Ver todo en ${widget.category.tituloCompleto}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: bannerButtonForeground,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Barra de búsqueda rápida de subcategorías ───────────────
              if (widget.category.grupos.length > 1 ||
                  _totalSubcategorias > 3) ...[
                M3ESearchBar(
                  controller: _filterController,
                  focusNode: _filterFocusNode,
                  onTapOutside: (_) => _filterFocusNode.unfocus(),
                  hintText: 'Filtrar en ${widget.category.tituloCompleto}...',
                  leading: const Icon(Icons.search_rounded),
                  showClearButton: true,
                  margin: 12,
                  focusedMargin: 0,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                  onChanged: (val) {
                    setState(() {
                      _filterQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Lista o Cuadrícula Adaptable de Grupos M3E ──────────────
              if (filteredGroups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No se encontraron subcategorías para "$_filterQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // En móvil (<650px) se utiliza 1 sola columna para maximizar el área táctil ergonómica
                    final isMobile = constraints.maxWidth < 650;
                    final crossAxisCount = isMobile
                        ? 1
                        : (constraints.maxWidth > 1000 ? 3 : 2);

                    if (crossAxisCount == 1) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final grupo in filteredGroups) ...[
                            _buildGrupoCard(context, grupo, colorScheme),
                            const SizedBox(height: 14),
                          ],
                        ],
                      );
                    }

                    // Layout multi-columna balanceado para tablets y pantallas amplias
                    final columnWidth =
                        (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                        crossAxisCount;
                    final columns = List.generate(
                      crossAxisCount,
                      (_) => <CategoryGroup>[],
                    );
                    for (var i = 0; i < filteredGroups.length; i++) {
                      columns[i % crossAxisCount].add(filteredGroups[i]);
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          int colIndex = 0;
                          colIndex < crossAxisCount;
                          colIndex++
                        ) ...[
                          if (colIndex > 0) const SizedBox(width: 16),
                          SizedBox(
                            width: columnWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final grupo in columns[colIndex]) ...[
                                  _buildGrupoCard(context, grupo, colorScheme),
                                  const SizedBox(height: 14),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );

    return ListenableBuilder(
      listenable: _filterFocusNode,
      child: scaffold,
      builder: (context, child) {
        return PopScope(
          canPop: !_filterFocusNode.hasFocus,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _filterFocusNode.unfocus();
            FocusScope.of(context).unfocus();
          },
          child: child!,
        );
      },
    );
  }

  Widget _buildGrupoCard(
    BuildContext context,
    CategoryGroup grupo,
    ColorScheme colorScheme,
  ) {
    return M3ECard(
      variant: M3ECardVariant.filled,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Encabezado del grupo con botón 'Ver grupo' ───────────────
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: InkWell(
              onTap: () => _abrirProductos(context, grupo.nombre, grupo.id),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        grupo.nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (grupo.subcategorias.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${grupo.subcategorias.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Lista de subcategorías con generoso target táctil móvil ──
          if (grupo.subcategorias.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grupo.subcategorias.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              itemBuilder: (context, index) {
                final sub = grupo.subcategorias[index];
                final isLast = index == grupo.subcategorias.length - 1;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _abrirProductos(context, sub.nombre, sub.id),
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          )
                        : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 17,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sub.nombre,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.9,
                                ),
                                height: 1.3,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            // Ítem directo cuando el grupo no tiene sub-niveles
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _abrirProductos(context, grupo.nombre, grupo.id),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ver todos los productos de este grupo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
