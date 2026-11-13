import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/institutional_logo_card.dart';
import 'main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _dniController = TextEditingController();
  bool _rememberDni = false;
  bool _rememberedDniLoaded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<String?>>(rememberedDniProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (dni) {
          if (_rememberedDniLoaded || !mounted) return;
          setState(() {
            _rememberedDniLoaded = true;
            if (dni != null) {
              _rememberDni = true;
              _dniController.text = dni;
            }
          });
        },
        loading: () {},
        error: (error, stackTrace) {
          if (!mounted) return;
          setState(() => _rememberedDniLoaded = true);
          _showPending(context, 'No se pudo cargar el DNI guardado.');
        },
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_rememberedDniLoaded) {
      _showPending(context, 'Cargando las preferencias del dispositivo.');
      return;
    }

    final dni = _dniController.text.trim();
    if (!isValidDni(dni)) {
      _showPending(context, 'Ingresa un DNI o legajo de 7 u 8 números.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final signedIn = await ref
          .read(sessionProvider.notifier)
          .signIn(dni, rememberDni: _rememberDni);
      if (!signedIn) {
        if (!mounted) return;
        _showPending(context, 'Ingresa un DNI o legajo de 7 u 8 números.');
        return;
      }
      ref.invalidate(rememberedDniProvider);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
      }
    } on PlatformException {
      if (!mounted) return;
      _showPending(context, 'No se pudo guardar la sesión en este dispositivo.');
    } on MissingPluginException {
      if (!mounted) return;
      _showPending(context, 'El almacenamiento local no está disponible.');
    } on StateError {
      if (!mounted) return;
      _showPending(context, 'No se pudo guardar la sesión en este dispositivo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: [AutofillHints.username],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ej: 35123456',
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
              onPressed: _isSubmitting || !_rememberedDniLoaded
                  ? null
                  : _submit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    !_rememberedDniLoaded
                        ? 'Preparando…'
                        : _isSubmitting
                        ? 'Ingresando…'
                        : 'Ingresar',
                  ),
                  if (_isSubmitting) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 19),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _showPending(
                    context,
                    'La mesa de ayuda estará disponible próximamente.',
                  ),
                  child: const Text('Mesa de Ayuda'),
                ),
                TextButton(
                  onPressed: () => _showPending(
                    context,
                    'El listado oficial estará disponible próximamente.',
                  ),
                  child: const Text('Listado Oficial'),
                ),
              ],
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
