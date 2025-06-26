import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';
import '../../models/acknowledgment_statements.dart';

class AgreementContainer extends StatelessWidget {
  const AgreementContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AcknowledgmentSizes.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AcknowledgmentColors.primaryDark.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AcknowledgmentColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AcknowledgmentStatements.agreementStatements
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key < AcknowledgmentStatements.agreementStatements.length - 1 
                        ? AcknowledgmentSizes.spacingMedium 
                        : 0,
                  ),
                  child: Text(
                    entry.value,
                    style: AcknowledgmentTextStyles.body,
                  ),
                ))
            .toList(),
      ),
    );
  }
}