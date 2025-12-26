import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'home/ui/home_page.dart';
import 'package:animal_restaurant_tracker/features/timers/data/timer_service.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
final ValueNotifier<int> _navTick = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimerService.instance.init();
  runApp(const AnimalRestaurantApp());
}

class AnimalRestaurantApp extends StatelessWidget {
  const AnimalRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      navigatorObservers: [_OverlayNavObserver(_navTick)],
      title: 'Animal Restaurant Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return _GlobalHomeOverlay(child: child);
      },
    );
  }
}

class _OverlayNavObserver extends NavigatorObserver {
  final ValueNotifier<int> tick;
  _OverlayNavObserver(this.tick);

  void _bump() {
    // Delay to avoid "markNeedsBuild called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tick.value++;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _bump();
}

class _GlobalHomeOverlay extends StatelessWidget {
  final Widget child;
  const _GlobalHomeOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _navTick,
      builder: (context, _, __) {
        final canPop = _navKey.currentState?.canPop() ?? false;

        return Stack(
          children: [
            child,
            if (canPop)
              Positioned(
                right: 16,
                bottom: 16,
                child: _HomeOverlayButton(
                  onPressed: () => _navKey.currentState?.popUntil((r) => r.isFirst),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeOverlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _HomeOverlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // No FloatingActionButton => no Hero/Overlay requirement.
    return Material(
      elevation: 6,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.home),
        ),
      ),
    );
  }
}
