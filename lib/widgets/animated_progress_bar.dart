import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final Color backgroundColor;
  final Color valueColor;
  final Duration animationDuration;
  final String? label;
  final TextStyle? labelStyle;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.valueColor = const Color(0xFF4CAF50),
    this.animationDuration = const Duration(milliseconds: 800),
    this.label,
    this.labelStyle,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: widget.labelStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: widget.height,
                    child: LinearProgressIndicator(
                      value: _animation.value,
                      backgroundColor: widget.backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.valueColor,
                      ),
                      minHeight: widget.height,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_animation.value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
