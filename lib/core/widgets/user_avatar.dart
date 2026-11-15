import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// Profile picture from [url], or the name's initial while it loads, when
/// there is none, or when the link is broken.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.radius = 28});

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.teal600,
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.8,
        ),
      ),
    );
    final link = url?.trim() ?? '';
    if (link.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        link,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        semanticLabel: name,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
