import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Persistent tab bar for the four main screens of the app.
///
/// This is a true tab controller — it swaps the body under an [IndexedStack]
/// in [MainShell] rather than pushing new screens, so every tab keeps its
/// state (camera position, search text, in-flight forms) while hidden.
///
/// A raised circular button sits in the middle of the bar and opens the
/// drawer — it is not one of the four tabs, so it takes its own callback
/// rather than a fifth index.
class SurakshaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onMenuTap;

  const SurakshaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        clipBehavior: Clip.none,
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NavAction(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavAction(
                  icon: Icons.alt_route_rounded,
                  label: 'Safe Routing',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _CentreMenuButton(onTap: onMenuTap),
                _NavAction(
                  icon: Icons.place_rounded,
                  label: 'Safe Spot',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavAction(
                  icon: Icons.shield_rounded,
                  label: 'Guardian',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised circular button lifted out of the bar's top edge — opens the
/// drawer. Fixed width; wrapped in a negative [Transform.translate] so it
/// visibly sits above the bar line rather than inside it.
class _CentreMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CentreMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, -18),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inactiveNav;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
