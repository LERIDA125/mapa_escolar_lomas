import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Institutional logo card used by the splash and login screens.
///
/// The prototype points to a remote logo image. To keep the app offline-first,
/// this widget renders an equivalent institutional lockup with native widgets.
class InstitutionalLogoCard extends StatelessWidget {
  const InstitutionalLogoCard({
    super.key,
    this.onDark = false,
    this.maxWidth = 320,
  });

  final bool onDark;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sky.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.5),
                    AppColors.primaryContainer.withValues(alpha: 0.4),
                  ],
                )
              : null,
          color: onDark ? null : AppColors.surface,
          border: onDark
              ? null
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
          boxShadow: onDark
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0F3C4043),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: onDark
                ? Colors.white.withValues(alpha: 0.95)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONSEJO ESCOLAR',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'LOMAS DE ZAMORA',
                      style: TextStyle(
                        color: AppColors.neutral,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        height: 1.2,
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
}
