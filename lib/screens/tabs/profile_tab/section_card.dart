import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? titleTrailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black.withValues(alpha: 0.2),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                ?titleTrailing,
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
