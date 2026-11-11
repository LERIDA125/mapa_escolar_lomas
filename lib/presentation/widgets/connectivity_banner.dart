import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connectivity_providers.dart';
import '../theme/app_theme.dart';

/// Slim strip that announces a lost connection.
///
/// Deliberately passive. It occupies its own row in the [Scaffold] above the
/// navigation bar, so it never overlaps the map, the search bar, the filter
/// chips, the school sheet or the distances, and it has no tap target: there
/// is nothing to dismiss because the condition clears itself.
///
/// The message leads with what still works. Losing the network degrades map
/// imagery, not the catalog, and telling the applicant that the search and the
/// school sheets keep working is more useful than a bare "no connection".
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: isOffline
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: AppColors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sin conexión · escuelas y fichas siguen disponibles',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
