import 'package:flutter/material.dart';
import '../../utils/registration_constants.dart';

class InfoPanel extends StatelessWidget {
  final String message;
  final InfoPanelType type;
  
  const InfoPanel({
    super.key,
    required this.message,
    this.type = InfoPanelType.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case InfoPanelType.info:
        return Colors.blue[50]!;
      case InfoPanelType.warning:
        return Colors.orange.withOpacity(0.2);
      case InfoPanelType.error:
        return Colors.red[50]!;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case InfoPanelType.info:
        return Colors.blue[200]!;
      case InfoPanelType.warning:
        return Colors.orange.withOpacity(0.5);
      case InfoPanelType.error:
        return Colors.red[200]!;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case InfoPanelType.info:
        return Icons.info_outline;
      case InfoPanelType.warning:
        return Icons.warning;
      case InfoPanelType.error:
        return Icons.error_outline;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case InfoPanelType.info:
        return Colors.blue[700]!;
      case InfoPanelType.warning:
        return RegistrationConstants.orangeColor;
      case InfoPanelType.error:
        return Colors.red[700]!;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case InfoPanelType.info:
        return Colors.blue[700]!;
      case InfoPanelType.warning:
        return Colors.white.withOpacity(0.9);
      case InfoPanelType.error:
        return Colors.red[700]!;
    }
  }
}

enum InfoPanelType {
  info,
  warning,
  error,
}