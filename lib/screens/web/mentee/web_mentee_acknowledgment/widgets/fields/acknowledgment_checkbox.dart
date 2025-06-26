import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';

class AcknowledgmentCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const AcknowledgmentCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AcknowledgmentSizes.spacingMedium),
        decoration: BoxDecoration(
          color: isChecked 
              ? AcknowledgmentColors.primaryDark.withOpacity(0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isChecked 
                ? AcknowledgmentColors.primaryDark
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isChecked 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: isChecked 
                    ? AcknowledgmentColors.primaryDark
                    : Colors.grey.shade500,
                size: AcknowledgmentSizes.iconSizeMedium,
              ),
            ),
            const SizedBox(width: AcknowledgmentSizes.spacingMedium),
            Expanded(
              child: Text(
                AcknowledgmentStrings.checkboxLabel,
                style: TextStyle(
                  fontSize: AcknowledgmentSizes.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                  color: AcknowledgmentColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}