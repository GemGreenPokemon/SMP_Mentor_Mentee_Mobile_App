import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';
import '../../models/acknowledgment_statements.dart';

class BrandingPanel extends StatelessWidget {
  const BrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 48,
      decoration: BoxDecoration(
        color: AcknowledgmentColors.primaryDark,
        borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AcknowledgmentColors.shadowDark,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.all(AcknowledgmentSizes.panelMargin),
      padding: const EdgeInsets.all(AcknowledgmentSizes.panelPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/My_SMP_Logo.png',
            height: AcknowledgmentSizes.logoHeight,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          const Text(
            AcknowledgmentStrings.appTitle,
            style: AcknowledgmentTextStyles.panelTitle,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingLarge),
          const Text(
            AcknowledgmentStrings.panelDescription,
            style: AcknowledgmentTextStyles.panelSubtitle,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          _buildChecklistContainer(),
        ],
      ),
    );
  }

  Widget _buildChecklistContainer() {
    return Container(
      padding: const EdgeInsets.all(AcknowledgmentSizes.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AcknowledgmentStatements.checklistItems
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AcknowledgmentSizes.spacingMedium),
                  child: Text(
                    '${item.icon} ${item.text}',
                    style: AcknowledgmentTextStyles.panelListItem,
                  ),
                ))
            .toList(),
      ),
    );
  }
}