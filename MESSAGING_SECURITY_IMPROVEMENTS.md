# Messaging System Security Improvements

## Critical Security Issues to Address

### 1. **Implement Proper Access Control**

#### Current Issue
The messaging system doesn't verify if users are authorized to access conversations or send messages to specific recipients.

#### Solution
```dart
// Add to messaging_service.dart
Future<bool> canUserAccessConversation(String userId, String conversationId) async {
  try {
    // Parse the conversation ID
    final parts = conversationId.split('__');
    if (parts.length != 2) return false;
    
    final mentorId = parts[0];
    final menteeId = parts[1];
    
    // Check if user is part of this conversation
    if (userId != mentorId && userId != menteeId) return false;
    
    // Verify mentorship exists
    final mentorshipQuery = await _universityDoc
        .collection('data')
        .doc('data')
        .collection('mentorships')
        .where('mentor_id', isEqualTo: mentorId)
        .where('mentee_id', isEqualTo: menteeId)
        .limit(1)
        .get();
    
    return mentorshipQuery.docs.isNotEmpty;
  } catch (e) {
    debugPrint('Error checking conversation access: $e');
    return false;
  }
}

// Update sendMessage to include authorization
Future<bool> sendMessage({
  required String conversationId,
  required String senderId,
  required String message,
}) async {
  // Verify sender is authorized
  if (!await canUserAccessConversation(senderId, conversationId)) {
    debugPrint('Unauthorized: User $senderId cannot access conversation $conversationId');
    return false;
  }
  
  // Verify senderId matches current user
  if (senderId != _authService.currentUser?.uid) {
    debugPrint('Security: Sender ID mismatch');
    return false;
  }
  
  // Continue with existing implementation...
}
```

### 2. **Implement Message Sanitization**

#### Current Issue
Messages are rendered directly without sanitization, creating XSS vulnerability.

#### Solution
Create a message sanitizer utility:

```dart
// Create lib/screens/web/shared/web_messaging/utils/message_sanitizer.dart
class MessageSanitizer {
  // Remove any HTML tags and dangerous characters
  static String sanitizeMessage(String input) {
    if (input.isEmpty) return input;
    
    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Escape special characters
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    // Remove any script-like patterns
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    
    return sanitized.trim();
  }
  
  // Validate message content
  static bool isValidMessageContent(String message) {
    // Check for suspicious patterns
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(message)) {
        return false;
      }
    }
    
    return true;
  }
}
```

Update message sending:
```dart
// In sendMessage()
final sanitizedMessage = MessageSanitizer.sanitizeMessage(message.trim());
if (!MessageSanitizer.isValidMessageContent(sanitizedMessage)) {
  debugPrint('Message contains invalid content');
  return false;
}

final messageDoc = {
  'chat_id': conversationId,
  'sender_id': senderId,
  'message': sanitizedMessage,  // Use sanitized message
  'sent_at': FieldValue.serverTimestamp(),
  'synced': true,
};
```

### 3. **Implement Rate Limiting**

#### Current Issue
No rate limiting on message sending or typing indicators.

#### Solution
```dart
// Add to messaging_service.dart
class RateLimiter {
  final Map<String, List<DateTime>> _actionTimestamps = {};
  final int maxActions;
  final Duration timeWindow;
  
  RateLimiter({
    this.maxActions = 10,
    this.timeWindow = const Duration(minutes: 1),
  });
  
  bool shouldAllowAction(String userId, String action) {
    final key = '${userId}_$action';
    final now = DateTime.now();
    
    // Get or create timestamp list
    _actionTimestamps[key] ??= [];
    final timestamps = _actionTimestamps[key]!;
    
    // Remove old timestamps
    timestamps.removeWhere((timestamp) => 
      now.difference(timestamp) > timeWindow
    );
    
    // Check if limit exceeded
    if (timestamps.length >= maxActions) {
      return false;
    }
    
    // Add new timestamp
    timestamps.add(now);
    return true;
  }
}

// In messaging_service.dart
final _messageLimiter = RateLimiter(maxActions: 30, timeWindow: Duration(minutes: 1));
final _typingLimiter = RateLimiter(maxActions: 20, timeWindow: Duration(minutes: 1));

// Update sendMessage
Future<bool> sendMessage(...) async {
  if (!_messageLimiter.shouldAllowAction(senderId, 'send_message')) {
    _error = 'Rate limit exceeded. Please slow down.';
    notifyListeners();
    return false;
  }
  // ... rest of implementation
}
```

### 4. **Implement Firebase Security Rules**

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Messages rules
    match /universities/{state}/{city}/{campus}/data/data/messages/{messageId} {
      // Read: Only if user is part of the conversation
      allow read: if isAuthenticated() && 
        (resource.data.chat_id.matches('.*' + request.auth.uid + '.*'));
      
      // Create: Only if sender matches auth user and is part of conversation
      allow create: if isAuthenticated() && 
        request.auth.uid == request.resource.data.sender_id &&
        request.resource.data.chat_id.matches('.*' + request.auth.uid + '.*') &&
        request.resource.data.message.size() <= 1000;
      
      // No updates or deletes allowed
      allow update, delete: if false;
    }
    
    // Typing indicators
    match /universities/{state}/{city}/{campus}/data/data/typing_indicators/{conversationId} {
      // Only allow if user is part of the conversation
      allow read, write: if isAuthenticated() && 
        conversationId.matches('.*' + request.auth.uid + '.*');
    }
    
    // Mentorships - read only for participants
    match /universities/{state}/{city}/{campus}/data/data/mentorships/{mentorshipId} {
      allow read: if isAuthenticated() && 
        (resource.data.mentor_id == request.auth.uid || 
         resource.data.mentee_id == request.auth.uid);
    }
  }
}
```

### 5. **Additional Security Measures**

#### A. Content Security Policy (CSP)
Add to `web/index.html`:
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval' https://apis.google.com; 
               style-src 'self' 'unsafe-inline'; 
               img-src 'self' data: https:; 
               connect-src 'self' https://*.firebaseio.com https://*.googleapis.com;">
```

#### B. Input Validation Improvements
```dart
class MessageValidator {
  static const int minLength = 1;
  static const int maxLength = 1000;
  
  static final RegExp _urlPattern = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
  );
  
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  
  static ValidationResult validate(String message) {
    if (message.trim().isEmpty) {
      return ValidationResult(false, 'Message cannot be empty');
    }
    
    if (message.length > maxLength) {
      return ValidationResult(false, 'Message too long (max $maxLength characters)');
    }
    
    // Check for excessive URLs (spam prevention)
    final urlMatches = _urlPattern.allMatches(message);
    if (urlMatches.length > 3) {
      return ValidationResult(false, 'Too many URLs in message');
    }
    
    // Check for repeated characters (spam)
    if (RegExp(r'(.)\1{9,}').hasMatch(message)) {
      return ValidationResult(false, 'Message contains spam patterns');
    }
    
    return ValidationResult(true, null);
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  
  ValidationResult(this.isValid, this.error);
}
```

#### C. Audit Logging
```dart
// Add to messaging_service.dart
Future<void> _logMessageActivity({
  required String action,
  required String userId,
  required String conversationId,
  Map<String, dynamic>? metadata,
}) async {
  try {
    await _universityDoc
        .collection('audit_logs')
        .doc('messaging')
        .collection('activities')
        .add({
          'action': action,
          'userId': userId,
          'conversationId': conversationId,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': metadata,
        });
  } catch (e) {
    debugPrint('Failed to log activity: $e');
  }
}
```

### 6. **Security Testing Checklist**

- [ ] Test unauthorized access to conversations
- [ ] Test XSS injection attempts
- [ ] Test rate limiting
- [ ] Test message size limits
- [ ] Test SQL injection patterns
- [ ] Test CSRF tokens
- [ ] Test session management
- [ ] Test data encryption in transit

### 7. **Best Practices Summary**

1. **Never trust client input** - Always validate and sanitize
2. **Use server-side validation** - Firebase Security Rules as minimum
3. **Implement rate limiting** - Prevent abuse
4. **Log security events** - For audit and monitoring
5. **Regular security audits** - Test for vulnerabilities
6. **Keep dependencies updated** - Security patches
7. **Use HTTPS only** - Encrypt data in transit
8. **Implement proper authentication** - Verify user identity

## Conclusion

While the current implementation provides basic functionality, it requires significant security hardening before production use. The most critical issues are:

1. Lack of access control verification
2. Missing input sanitization (XSS vulnerability)
3. No rate limiting
4. Direct Firestore access without validation

Implementing the suggested improvements will significantly enhance the security posture of the messaging system.