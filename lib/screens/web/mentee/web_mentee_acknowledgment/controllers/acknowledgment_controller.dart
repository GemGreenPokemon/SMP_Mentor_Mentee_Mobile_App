import 'package:flutter/material.dart';
import '../models/acknowledgment_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';

class AcknowledgmentController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  
  bool _isAcknowledged = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  bool get isAcknowledged => _isAcknowledged;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  
  void toggleAcknowledgment() {
    _isAcknowledged = !_isAcknowledged;
    notifyListeners();
  }
  
  void setAcknowledgment(bool value) {
    _isAcknowledged = value;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Please enter your full name (first and last name)';
    }
    return null;
  }
  
  Future<bool> submitAcknowledgment(BuildContext context) async {
    clearError();
    
    if (!_isAcknowledged) {
      _errorMessage = 'Please check the acknowledgment box';
      notifyListeners();
      return false;
    }
    
    if (formKey.currentState?.validate() != true) {
      return false;
    }
    
    _isSubmitting = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Use secure cloud function to submit acknowledgment
      final result = await _cloudFunctions.submitMenteeAcknowledgment(
        fullName: nameController.text.trim(),
      );
      
      if (result['success'] == true) {
        // If custom claims were set, refresh the token to get them immediately
        if (result['claimsSet'] == true) {
          print('🔐 Refreshing token to apply new custom claims...');
          try {
            await user.getIdToken(true);
            print('🔐 Token refreshed successfully');
          } catch (e) {
            print('🔐 Warning: Could not refresh token: $e');
            // Don't fail the whole process if token refresh fails
          }
        }
        
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['message'] ?? 'Failed to submit acknowledgment');
      }
    } catch (e) {
      _errorMessage = 'Failed to submit acknowledgment: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}