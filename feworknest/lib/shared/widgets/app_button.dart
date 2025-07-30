import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.style,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (!isLoading)
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    final defaultStyle = isOutlined
        ? OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? defaultStyle,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ?? defaultStyle,
      child: child,
    );
  }
}
