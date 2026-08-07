import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connectivity_state.dart';
import '../../services/connectivity_service.dart';
import '../../core/constants/app_colors.dart';

/// Persistent banner shown at the top of every screen indicating
/// ONLINE / OFFLINE-CACHED / OFFLINE-STALE state.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: context.read<ConnectivityService>().statusStream,
      initialData: context.read<ConnectivityService>().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectivityStatus.offlineCached;

        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink(); // hidden when online
        }

        final color = status == ConnectivityStatus.offlineCached
            ? AppColors.offlineCachedIndicator
            : AppColors.offlineStaleIndicator;

        return Container(
          width: double.infinity,
          color: color,
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 12, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                status.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
