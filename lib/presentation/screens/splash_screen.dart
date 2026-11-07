import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/institutional_logo_card.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 2200);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _openLogin);
  }

  void _openLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.splashTop,
                AppColors.splashMid,
                AppColors.splashBottom,
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: _SplashBackdrop()),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            child: Column(
                              children: [
                                const _SplashHeader(),
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const InstitutionalLogoCard(
                                          onDark: true,
                                        ),
                                        const SizedBox(height: 24),
                                        const _SplashHeadline(),
                                        const SizedBox(height: 24),
                                        const _FeaturePill(),
                                      ],
                                    ),
                                  ),
                                ),
                                const _SplashFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashHeader extends StatelessWidget {
  const _SplashHeader();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LOMAS DE ZAMORA',
              style: TextStyle(
                color: AppColors.sky.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 13,
                color: AppColors.sky,
              ),
              const SizedBox(width: 4),
              Text(
                'MODO OFFLINE',
                style: TextStyle(
                  color: AppColors.sky.withValues(alpha: 0.95),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplashHeadline extends StatelessWidget {
  const _SplashHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Consejo Escolar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sector Auxiliares',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.sky.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _DividerLine(alignment: Alignment.centerLeft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ACTOS PÚBLICOS • GUÍA DE ESCUELAS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.sky.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _DividerLine(alignment: Alignment.centerRight),
          ],
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment,
          end: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [Colors.transparent, AppColors.sky.withValues(alpha: 0.5)],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 16, color: AppColors.sky),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Geolocalización y Ruteo Inmediato',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.sky.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  const _SplashFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.sky.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sky),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Preparando datos offline...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Cargando mapa de establecimientos y recorridos',
          style: TextStyle(
            color: AppColors.sky.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Distrito Lomas de Zamora (062)',
                style: TextStyle(
                  color: AppColors.sky.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              Text(
                'v2.4.0 • Base Local',
                style: TextStyle(
                  color: AppColors.sky.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -96,
          left: -96,
          child: _Glow(
            size: 320,
            color: AppColors.cyan.withValues(alpha: 0.20),
          ),
        ),
        Positioned(
          top: 260,
          right: -120,
          child: _Glow(
            size: 360,
            color: AppColors.primaryContainer.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: _Glow(
            size: 320,
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned(
          top: -160,
          right: -160,
          child: _Ring(size: 384, color: AppColors.sky.withValues(alpha: 0.10)),
        ),
        Positioned(
          top: -80,
          right: -80,
          child: _Ring(size: 288, color: AppColors.sky.withValues(alpha: 0.10)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
