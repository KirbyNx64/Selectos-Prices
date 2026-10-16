import 'package:flutter/material.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void success(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_rounded,
  }) {
    _show(context, message: message, icon: icon, isError: false);
  }

  static void error(BuildContext context, {required String message}) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      isError: true,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconBackground = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final iconColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.inverseSurface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
