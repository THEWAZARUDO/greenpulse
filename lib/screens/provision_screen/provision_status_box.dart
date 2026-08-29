import 'package:flutter/material.dart';

enum ProvisionStatus { idle, sending, success, error }

class ProvisionStatusBox extends StatelessWidget {
  final ProvisionStatus status;
  final String statusMessage;

  const ProvisionStatusBox({
    super.key,
    required this.status,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ProvisionStatus.idle) return const SizedBox.shrink();

    final isSuccess = status == ProvisionStatus.success;
    final isError = status == ProvisionStatus.error;
    final color = isSuccess
        ? Colors.green
        : isError
            ? Colors.red
            : Colors.blue;
    final icon = isSuccess
        ? Icons.check_circle_outline
        : isError
            ? Icons.error_outline
            : Icons.sync;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage,
              style: TextStyle(color: color.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
