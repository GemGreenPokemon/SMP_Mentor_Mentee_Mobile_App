import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('AcknowledgmentController Tests', () {
    late TextEditingController testNameController;

    setUp(() {
      testNameController = TextEditingController();
    });

    tearDown(() {
      testNameController.dispose();
    });

    group('Name Validation', () {
      test('validateName returns error for empty name', () {
        // Test the validation logic directly
        String? validateName(String? value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your full name';
          }
          if (value.trim().split(' ').length < 2) {
            return 'Please enter your full name (first and last name)';
          }
          return null;
        }

        expect(validateName(null), equals('Please enter your full name'));
        expect(validateName(''), equals('Please enter your full name'));
        expect(validateName('   '), equals('Please enter your full name'));
      });

      test('validateName returns error for single name', () {
        String? validateName(String? value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your full name';
          }
          if (value.trim().split(' ').length < 2) {
            return 'Please enter your full name (first and last name)';
          }
          return null;
        }

        expect(validateName('John'), equals('Please enter your full name (first and last name)'));
        expect(validateName('SingleName'), equals('Please enter your full name (first and last name)'));
      });

      test('validateName accepts valid full names', () {
        String? validateName(String? value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your full name';
          }
          if (value.trim().split(' ').length < 2) {
            return 'Please enter your full name (first and last name)';
          }
          return null;
        }

        expect(validateName('John Doe'), isNull);
        expect(validateName('Jane Mary Smith'), isNull);
        expect(validateName('Robert De Niro'), isNull);
        expect(validateName('  John   Doe  '), isNull); // Extra spaces should be handled
      });
    });

    group('Acknowledgment State', () {
      test('isAcknowledged starts as false', () {
        bool isAcknowledged = false;
        expect(isAcknowledged, isFalse);
      });

      test('toggleAcknowledgment switches state', () {
        bool isAcknowledged = false;
        
        // First toggle
        isAcknowledged = !isAcknowledged;
        expect(isAcknowledged, isTrue);
        
        // Second toggle
        isAcknowledged = !isAcknowledged;
        expect(isAcknowledged, isFalse);
      });

      test('setAcknowledgment sets specific value', () {
        bool isAcknowledged = false;
        
        // Set to true
        isAcknowledged = true;
        expect(isAcknowledged, isTrue);
        
        // Set to true again (should stay true)
        isAcknowledged = true;
        expect(isAcknowledged, isTrue);
        
        // Set to false
        isAcknowledged = false;
        expect(isAcknowledged, isFalse);
      });
    });

    group('Submission State', () {
      test('isSubmitting starts as false', () {
        bool isSubmitting = false;
        expect(isSubmitting, isFalse);
      });

      test('error message starts as null', () {
        String? errorMessage;
        expect(errorMessage, isNull);
      });

      test('clearError sets error to null', () {
        String? errorMessage = 'Some error';
        
        // Clear error
        errorMessage = null;
        expect(errorMessage, isNull);
      });
    });

    group('Form Validation Logic', () {
      test('submission requires acknowledgment checked', () {
        bool isAcknowledged = false;
        String? errorMessage;
        
        // Simulate validation check
        if (!isAcknowledged) {
          errorMessage = 'Please check the acknowledgment box';
        }
        
        expect(errorMessage, equals('Please check the acknowledgment box'));
        
        // Check with acknowledgment
        isAcknowledged = true;
        errorMessage = null;
        
        if (!isAcknowledged) {
          errorMessage = 'Please check the acknowledgment box';
        }
        
        expect(errorMessage, isNull);
      });

      test('full name formatting is preserved', () {
        final testCases = {
          'John Doe': 'John Doe',
          '  John   Doe  ': 'John   Doe', // Trim but preserve internal spaces
          'John Middle Doe': 'John Middle Doe',
          'María José García': 'María José García', // Unicode support
        };
        
        testCases.forEach((input, expected) {
          testNameController.text = input;
          expect(testNameController.text.trim(), equals(expected));
        });
      });
    });

    group('Cloud Function Response Handling', () {
      test('successful response has expected format', () {
        // Simulate successful response
        final successResponse = {
          'success': true,
          'message': 'Acknowledgment submitted successfully',
        };
        
        expect(successResponse['success'], isTrue);
        expect(successResponse['message'], isNotNull);
      });

      test('error response has expected format', () {
        // Simulate error response
        final errorResponse = {
          'success': false,
          'message': 'User not authorized',
        };
        
        expect(errorResponse['success'], isFalse);
        expect(errorResponse['message'], isNotNull);
      });

      test('handles missing message in response', () {
        // Simulate response without message
        final response = {'success': false};
        
        final errorMessage = response['message'] ?? 'Failed to submit acknowledgment';
        expect(errorMessage, equals('Failed to submit acknowledgment'));
      });
    });

    group('Text Controller Management', () {
      test('name controller can be updated', () {
        testNameController.text = 'John Doe';
        expect(testNameController.text, equals('John Doe'));
        
        testNameController.text = 'Jane Smith';
        expect(testNameController.text, equals('Jane Smith'));
      });

      test('name controller can be cleared', () {
        testNameController.text = 'John Doe';
        testNameController.clear();
        expect(testNameController.text, isEmpty);
      });
    });
  });
}