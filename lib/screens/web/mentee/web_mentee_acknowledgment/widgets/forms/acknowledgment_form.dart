import 'package:flutter/material.dart';
import '../../controllers/acknowledgment_controller.dart';
import '../../utils/acknowledgment_constants.dart';
import '../../models/acknowledgment_statements.dart';
import '../fields/acknowledgment_checkbox.dart';
import '../fields/signature_field.dart';
import '../shared/date_display.dart';
import '../shared/submit_button.dart';
import '../shared/agreement_container.dart';

class AcknowledgmentForm extends StatelessWidget {
  final AcknowledgmentController controller;
  final VoidCallback onSubmit;
  final bool showLogo;

  const AcknowledgmentForm({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo) ...[
            Center(
              child: Image.asset(
                'assets/images/My_SMP_Logo.png',
                height: AcknowledgmentSizes.logoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          ],
          
          Text(
            AcknowledgmentStrings.formTitle,
            style: AcknowledgmentTextStyles.h1,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingSmall),
          Text(
            AcknowledgmentStrings.formSubtitle,
            style: AcknowledgmentTextStyles.bodySecondary,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          
          Text(
            AcknowledgmentStrings.readAndAcknowledge,
            style: AcknowledgmentTextStyles.h3,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingLarge),
          
          const AgreementContainer(),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          
          AcknowledgmentCheckbox(
            isChecked: controller.isAcknowledged,
            onChanged: (_) => controller.toggleAcknowledgment(),
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          
          Text(
            AcknowledgmentStrings.nameFieldLabel,
            style: AcknowledgmentTextStyles.h3,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingLarge),
          
          SignatureField(
            controller: controller.nameController,
            validator: controller.validateName,
          ),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          
          const DateDisplay(),
          const SizedBox(height: AcknowledgmentSizes.spacingXLarge),
          
          if (controller.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AcknowledgmentSizes.spacingMedium),
              decoration: BoxDecoration(
                color: AcknowledgmentColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
                border: Border.all(color: AcknowledgmentColors.errorRed),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AcknowledgmentColors.errorRed,
                    size: AcknowledgmentSizes.iconSizeMedium,
                  ),
                  const SizedBox(width: AcknowledgmentSizes.spacingSmall),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: TextStyle(
                        color: AcknowledgmentColors.errorRed,
                        fontSize: AcknowledgmentSizes.fontSizeMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AcknowledgmentSizes.spacingLarge),
          ],
          
          SubmitButton(
            onPressed: onSubmit,
            isLoading: controller.isSubmitting,
          ),
        ],
      ),
    );
  }
}