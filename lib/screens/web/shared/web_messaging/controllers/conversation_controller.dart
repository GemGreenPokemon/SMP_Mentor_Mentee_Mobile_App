import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';

class ConversationController extends ChangeNotifier {
  final MessagingService messagingService;
  final String userId;
  final String userType;
  
  // State
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  
  // Search
  String _searchQuery = '';
  List<Conversation> _filteredConversations = [];
  
  ConversationController({
    required this.messagingService,
    required this.userId,
    required this.userType,
  });
  
  // Getters
  List<Conversation> get conversations => _searchQuery.isEmpty 
      ? _conversations 
      : _filteredConversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasConversations => _conversations.isNotEmpty;
  
  /// Load conversations for the current user
  void loadConversations() {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    _conversationsSubscription?.cancel();
    _conversationsSubscription = messagingService
        .getConversationsStream(userId)
        .listen(
      (conversations) {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  
  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _filterConversations();
    notifyListeners();
  }
  
  /// Filter conversations based on search query
  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = _conversations;
      return;
    }
    
    _filteredConversations = _conversations.where((conversation) {
      return conversation.userName.toLowerCase().contains(_searchQuery) ||
             conversation.lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  /// Get conversation by ID
  Conversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere(
        (conv) => conv.id == conversationId,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Refresh conversations
  Future<void> refresh() async {
    loadConversations();
  }
  
  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}