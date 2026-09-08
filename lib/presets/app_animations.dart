import 'package:flutter/material.dart';

/// Hệ thống Preset Animation chuẩn cho GreenPulse.
///
/// 1. [AppDurations] & [AppCurves]: Hằng số thời gian và gia tốc.
/// 2. [AppFadeSlide]: Hiệu ứng hiện dần kết hợp trượt nhẹ từ dưới lên (Fade-in & Slide-up).
/// 3. [AppStaggeredList]: Hiệu ứng xuất hiện lần lượt từng mục theo dạng sóng (Staggered Cascade).
/// 4. [AppAnimatedExpand]: Hiệu ứng xổ ra và thu gọn mượt mà (Smooth Expand & Collapse).
/// 5. [AppTabTransition]: Hiệu ứng chuyển tab mượt mà (Smooth Tab Switching).
class AppAnimations {
  AppAnimations._();

  // ==========================================
  // 1. HẰNG SỐ THỜI GIAN (DURATIONS)
  // ==========================================
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const Duration tabTransition = Duration(milliseconds: 280);

  // ==========================================
  // 2. HẰNG SỐ ĐƯỜNG CONG GIA TỐC (CURVES)
  // ==========================================
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve bounce = Curves.easeOutBack;
}

// ==========================================
// 3. WIDGET FADE-IN & SLIDE-UP
// ==========================================

/// Widget tạo hiệu ứng hiện dần và trượt nhẹ vào vị trí (Fade & Slide In).
///
/// Hỗ trợ [delay] để kết hợp tạo hoạt ảnh lần lượt cho nhiều phần tử.
class AppFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;

  const AppFadeSlide({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.12),
    this.curve = AppAnimations.decelerate,
  });

  @override
  State<AppFadeSlide> createState() => _AppFadeSlideState();
}

class _AppFadeSlideState extends State<AppFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ==========================================
// 4. WIDGET HIỆN LẦN LƯỢT (STAGGERED LIST)
// ==========================================

/// Widget tự động tạo hiệu ứng xuất hiện lần lượt cho một danh sách các phần tử.
///
/// Mỗi phần tử sẽ xuất hiện sau phần tử trước một khoảng thời gian [staggerDelay].
class AppStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Offset beginOffset;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AppStaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = AppAnimations.staggerDelay,
    this.itemDuration = AppAnimations.normal,
    this.beginOffset = const Offset(0, 0.15),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: List.generate(children.length, (index) {
        return AppFadeSlide(
          delay: staggerDelay * index,
          duration: itemDuration,
          beginOffset: beginOffset,
          child: children[index],
        );
      }),
    );
  }
}

// ==========================================
// 5. WIDGET XỔ RA & THU GỌN MƯỢT MÀ (EXPAND & COLLAPSE)
// ==========================================

/// Widget mở rộng hoặc thu gọn nội dung một cách mượt mà theo chiều dọc.
///
/// Thay thế cho việc ẩn/hiện đột ngột bằng câu lệnh if thông thường.
class AppAnimatedExpand extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AppAnimatedExpand({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.decelerate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: child,
      crossFadeState: isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: duration,
      sizeCurve: curve,
      firstCurve: curve,
      secondCurve: curve,
    );
  }
}

// ==========================================
// 6. WIDGET CHUYỂN ĐỔI TAB MƯỢT MÀ (TAB TRANSITION)
// ==========================================

/// Widget bọc nội dung màn hình chính giúp chuyển đổi giữa các Tab một cách êm ái.
///
/// Kết hợp giữa hiệu ứng mờ dần (Fade) và trượt nhẹ (Micro Slide) để tránh đổi tab giật cụt.
class AppTabTransition extends StatelessWidget {
  final int currentTab;
  final Widget child;
  final Duration duration;

  const AppTabTransition({
    super.key,
    required this.currentTab,
    required this.child,
    this.duration = AppAnimations.tabTransition,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget widgetChild, Animation<double> animation) {
        final fadeAnimation = animation;
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: widgetChild,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentTab),
        child: child,
      ),
    );
  }
}
