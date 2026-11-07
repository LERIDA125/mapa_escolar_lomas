import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/institutional_logo_card.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberDni = true;

  void _openHome() {
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  void _showPending(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _StatusHeader(),
                            const SizedBox(height: 16),
                            const Center(
                              child: InstitutionalLogoCard(maxWidth: 280),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Ingreso de Aspirantes',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineLarge?.copyWith(
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accede con tu documento para consultar las '
                              'vacantes.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildLoginCard(context),
                            const SizedBox(height: 16),
                            _buildHelpCard(context),
                            const SizedBox(height: 24),
                            _buildFooter(textTheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: const Color(0x1A3C4043),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel(text: 'Documento Nacional de Identidad (DNI)'),
            const SizedBox(height: 6),
            const TextField(
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: [AutofillHints.username],
              decoration: InputDecoration(
                hintText: 'Ej: 35.123.456',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: AppColors.outline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Sin puntos ni espacios',
                style: textTheme.labelSmall?.copyWith(color: AppColors.outline),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(text: 'Contraseña'),
            const SizedBox(height: 6),
            TextField(
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _openHome(),
              decoration: InputDecoration(
                hintText: '••••••••••••',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.outline,
                ),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberDni,
                    onChanged: (value) {
                      setState(() => _rememberDni = value ?? false);
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _rememberDni = !_rememberDni);
                    },
                    child: Text(
                      'Recordar mi DNI en este dispositivo',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _openHome,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ingresar'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showPending(
                context,
                'La recuperación de contraseña estará disponible próximamente.',
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Primer ingreso o dudas con tu puntaje?',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Verifica tu número de legajo en el listado oficial de '
                    'aspirantes o consulta en la mesa de ayuda de la sede '
                    'distrital.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _HelpLink(
                        label: 'Mesa de Ayuda',
                        icon: Icons.open_in_new_rounded,
                        onTap: () => _showPending(
                          context,
                          'La mesa de ayuda estará disponible próximamente.',
                        ),
                      ),
                      _HelpLink(
                        label: 'Listado 1047 / ABC',
                        muted: true,
                        onTap: () => _showPending(
                          context,
                          'El listado oficial estará disponible próximamente.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Column(
      children: [
        Text(
          'Consejo Escolar de Lomas de Zamora • Sector Auxiliares de Educación',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 4),
        Text(
          'Dirección General de Cultura y Educación • Pcia. de Buenos Aires',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.outline.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Acto Público Activo',
                style: labelStyle?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F3C4043),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_sync_outlined,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Modo Offline listo',
                style: labelStyle?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpLink extends StatelessWidget {
  const _HelpLink({
    required this.label,
    required this.onTap,
    this.icon,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.onSurfaceVariant : AppColors.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon!, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
