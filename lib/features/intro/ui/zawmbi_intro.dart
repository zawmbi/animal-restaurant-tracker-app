import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zawmbi Productions studio bumper — a studio credit and nothing else.
///
/// Ported from the React Native component in `zawmbi-intro/`; the beats and
/// the reasoning behind them are carried over unchanged.
///
/// iOS cannot animate the native launch screen (it's a static storyboard), so
/// this renders on top of the app once Flutter is ready and fades out. The
/// launch screen is on the same ground as [background] so the hand-off doesn't
/// flash. The host app's own branding is deliberately absent: the first thing
/// after this should be its real UI.
///
/// Mount it *over* the app, not instead of it — it fades out to reveal whatever
/// is already rendered underneath, and it ignores pointers so it never eats a
/// touch.
class ZawmbiIntro extends StatefulWidget {
  const ZawmbiIntro({
    super.key,
    required this.onDone,
    this.holdMs = _holdMs,
    this.fadeMs = _fadeMs,
    this.background = bone,
    this.ink = ink_,
  });

  /// Fired once the fade-out has finished. Stop rendering the intro here.
  final VoidCallback onDone;

  /// When the fade *starts*, ms from mount. Total run is [holdMs] + [fadeMs].
  final int holdMs;

  /// Fade-out duration, ms.
  final int fadeMs;

  /// Card ground. Match the native launch screen so the hand-off is seamless.
  final Color background;

  /// Credit colour.
  final Color ink;

  /// Flat ground, one colour, no washes. A gradient reads as production value
  /// the bumper hasn't earned; a single field reads as a studio card.
  static const Color bone = Color(0xFFEFE9D5);

  /// Brand spruce. The credit has to invert to this to sit on the bone.
  static const Color ink_ = Color(0xFF0F2820);

  /// Total run, for callers that need to schedule around it.
  static const Duration totalRun = Duration(
    milliseconds: _holdMs + _fadeMs,
  ); // 5.9s

  static const int _holdMs = 5000;
  static const int _fadeMs = 900;

  @override
  State<ZawmbiIntro> createState() => _ZawmbiIntroState();
}

class _ZawmbiIntroState extends State<ZawmbiIntro>
    with TickerProviderStateMixin {
  // Source frames are 240x288; this keeps that 5:6 aspect so the mascot doesn't
  // squash. Rendered under native resolution at 3x, which pixel art tolerates.
  static const double _mascotW = 140;
  static const double _mascotH = 168;

  // 4-step walk cycle over 3 unique frames, per assets/intro/frames.json:
  // contact-left -> passing -> contact-right -> passing.
  static const List<String> _walkFrames = [
    'assets/intro/frame1.png',
    'assets/intro/frame2.png',
    'assets/intro/frame3.png',
  ];
  static const List<int> _walkSequence = [0, 1, 2, 1];

  // Constant pace: a walk has no acceleration, and easing the travel made him
  // lunge in and brake. Sized so he clears the left edge early and is centred
  // well before the fade.
  static const int _walkStartMs = 150;
  static const int _walkTravelMs = 2800;
  static const int _walkFrameMs = 300;

  // Both words on one driver, so they cannot drift apart — the credit resolves
  // as a single object rather than two words arriving in sequence. Long and
  // eased: it should be hard to name the frame it became visible.
  static const int _creditDelayMs = 1300;
  static const int _creditMs = 1800;

  static const List<String> _studio = ['Zawmbi', 'Productions'];

  late final AnimationController _walk;
  late final AnimationController _credit;
  late final AnimationController _fade;

  Timer? _walkStart;
  Timer? _legs;
  Timer? _handoff;
  int _step = 0;
  int _frame = _walkSequence[0];

  @override
  void initState() {
    super.initState();

    _walk = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _walkTravelMs),
    );
    _credit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _creditMs),
    );
    _fade = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.fadeMs),
      value: 1,
    );

    // He walks on at a constant pace and is still walking at the fade. The leg
    // cycle is driven separately below — this is only travel.
    _walkStart = Timer(const Duration(milliseconds: _walkStartMs), () {
      if (!mounted) return;
      _walk.forward();
      // Frame swapping, not interpolation. Nothing stops it: he is still
      // walking as the card fades.
      _legs = Timer.periodic(const Duration(milliseconds: _walkFrameMs), (_) {
        if (!mounted) return;
        setState(() {
          _step = (_step + 1) % _walkSequence.length;
          _frame = _walkSequence[_step];
        });
      });
    });

    // The credit fades up beneath him, both words together. Opacity only: no
    // scale, no rise, no stagger — the words appear, they don't arrive.
    Timer(const Duration(milliseconds: _creditDelayMs), () {
      if (mounted) _credit.forward();
    });

    _handoff = Timer(Duration(milliseconds: widget.holdMs), () {
      if (!mounted) return;
      _fade.reverse().whenComplete(() {
        if (mounted) widget.onDone();
      });
    });
  }

  @override
  void dispose() {
    _walkStart?.cancel();
    _legs?.cancel();
    _handoff?.cancel();
    _walk.dispose();
    _credit.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // Starts off the left edge and travels to centre.
    final travel = Tween<double>(
      begin: -(width / 2 + _mascotW),
      end: 0,
    ).animate(CurvedAnimation(parent: _walk, curve: Curves.linear));

    final credit = CurvedAnimation(parent: _credit, curve: Curves.easeOutCubic);
    final fade = CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);

    // The card is light whatever the host app's theme is, so a themed status
    // bar would render light-on-bone for the whole intro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: IgnorePointer(
        child: FadeTransition(
          opacity: fade,
          // Material, not a bare Container: the bumper is mounted above the
          // navigator, so without one the credit inherits no text style and
          // Flutter paints it with the yellow "no Material ancestor" underline.
          child: Material(
            color: widget.background,
            child: Center(
              // Mascot centred, credit directly beneath him.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: travel,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(travel.value, 0),
                      child: child,
                    ),
                    child: Image.asset(
                      _walkFrames[_frame],
                      width: _mascotW,
                      height: _mascotH,
                      fit: BoxFit.contain,
                      // Pixel art — keep the hard edges instead of smoothing.
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: credit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final word in _studio) ...[
                          Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'ZawmbiCreditGamja',
                              fontSize: 34,
                              height: 40 / 34,
                              color: widget.ink,
                            ),
                          ),
                          // The two words are separate nodes with an explicit
                          // gap, so the spacing is the same 12px whatever the
                          // face's own space metric happens to be.
                          if (word != _studio.last) const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
