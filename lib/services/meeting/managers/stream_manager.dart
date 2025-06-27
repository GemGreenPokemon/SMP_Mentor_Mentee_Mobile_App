import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/meeting.dart';
import '../../../models/availability.dart';

/// Manages stream controllers and subscriptions for real-time updates
class MeetingStreamManager {
  // Singleton instance
  static final MeetingStreamManager _instance = MeetingStreamManager._internal();
  factory MeetingStreamManager() => _instance;
  MeetingStreamManager._internal();
  
  // Stream controllers
  StreamController<List<Meeting>>? _meetingsStreamController;
  StreamController<List<Availability>>? _availabilityStreamController;
  
  // Active subscriptions
  final List<StreamSubscription> _activeSubscriptions = [];
  StreamSubscription<QuerySnapshot>? _meetingsSubscription;
  StreamSubscription<QuerySnapshot>? _availabilitySubscription;
  
  // Stream getters
  Stream<List<Meeting>> get meetingsStream {
    _meetingsStreamController ??= StreamController<List<Meeting>>.broadcast();
    return _meetingsStreamController!.stream;
  }
  
  Stream<List<Availability>> get availabilityStream {
    _availabilityStreamController ??= StreamController<List<Availability>>.broadcast();
    print('🎭 StreamManager.availabilityStream getter called - controller exists: ${_availabilityStreamController != null}');
    return _availabilityStreamController!.stream;
  }
  
  // Stream controller getters (for repositories to add data)
  StreamController<List<Meeting>>? get meetingsController => _meetingsStreamController;
  StreamController<List<Availability>>? get availabilityController => _availabilityStreamController;
  
  /// Add a subscription to track
  void addSubscription(StreamSubscription subscription) {
    _activeSubscriptions.add(subscription);
  }
  
  /// Set the main meetings subscription
  void setMeetingsSubscription(StreamSubscription<QuerySnapshot> subscription) {
    _meetingsSubscription?.cancel();
    _meetingsSubscription = subscription;
  }
  
  /// Set the main availability subscription
  void setAvailabilitySubscription(StreamSubscription<QuerySnapshot> subscription) {
    _availabilitySubscription?.cancel();
    _availabilitySubscription = subscription;
  }
  
  /// Update meetings stream with new data
  void updateMeetingsStream(List<Meeting> meetings) {
    if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
      _meetingsStreamController!.add(meetings);
    }
  }
  
  /// Update availability stream with new data
  void updateAvailabilityStream(List<Availability> availability) {
    print('🎭 StreamManager.updateAvailabilityStream called with ${availability.length} items');
    print('🎭 Controller exists: ${_availabilityStreamController != null}');
    print('🎭 Controller closed: ${_availabilityStreamController?.isClosed ?? 'null'}');
    print('🎭 Has listeners: ${_availabilityStreamController?.hasListener ?? 'null'}');
    
    if (_availabilityStreamController != null && !_availabilityStreamController!.isClosed) {
      print('🎭 Adding ${availability.length} items to stream');
      _availabilityStreamController!.add(availability);
    } else {
      print('🎭 ⚠️ Cannot update stream - controller is null or closed');
    }
  }
  
  /// Send error to meetings stream
  void sendMeetingsError(Object error) {
    if (_meetingsStreamController != null && !_meetingsStreamController!.isClosed) {
      _meetingsStreamController!.addError(error);
    }
  }
  
  /// Send error to availability stream
  void sendAvailabilityError(Object error) {
    if (_availabilityStreamController != null && !_availabilityStreamController!.isClosed) {
      _availabilityStreamController!.addError(error);
    }
  }
  
  /// Cancel all subscriptions
  void cancelAllSubscriptions() {
    _meetingsSubscription?.cancel();
    _availabilitySubscription?.cancel();
    
    for (final subscription in _activeSubscriptions) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
  }
  
  /// Close all stream controllers
  void closeAllStreams() {
    _meetingsStreamController?.close();
    _availabilityStreamController?.close();
    _meetingsStreamController = null;
    _availabilityStreamController = null;
  }
  
  /// Dispose all resources
  void dispose() {
    cancelAllSubscriptions();
    closeAllStreams();
  }
  
  /// Get stream statistics (for debugging)
  Map<String, dynamic> getStreamStats() {
    return {
      'meetingsStreamActive': _meetingsStreamController != null && !_meetingsStreamController!.isClosed,
      'availabilityStreamActive': _availabilityStreamController != null && !_availabilityStreamController!.isClosed,
      'activeSubscriptions': _activeSubscriptions.length,
      'hasMeetingsSubscription': _meetingsSubscription != null,
      'hasAvailabilitySubscription': _availabilitySubscription != null,
    };
  }
}