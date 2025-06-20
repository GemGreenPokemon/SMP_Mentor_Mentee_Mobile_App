enum VerificationStatus {
  pending,
  verified,
  error,
}

class VerificationState {
  final VerificationStatus status;
  final bool isResending;
  final String? userEmail;
  final String? errorMessage;
  
  const VerificationState({
    this.status = VerificationStatus.pending,
    this.isResending = false,
    this.userEmail,
    this.errorMessage,
  });
  
  VerificationState copyWith({
    VerificationStatus? status,
    bool? isResending,
    String? userEmail,
    String? errorMessage,
  }) {
    return VerificationState(
      status: status ?? this.status,
      isResending: isResending ?? this.isResending,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}