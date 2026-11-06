import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService with WidgetsBindingObserver {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  DatabaseReference? _statusRef;

  bool _isConnected = false;
  String? _userId;

  Future<void> initialize(String userId) async {
    if (userId.trim().isEmpty) return;

    _userId = userId;
    _statusRef = _database.ref('${ChatUtil.NODE_USER_STATUS}/$userId');

    WidgetsBinding.instance.addObserver(this);

    final connectedRef = _database.ref('.info/connected');

    _connectionSubscription?.cancel();

    _connectionSubscription = connectedRef.onValue.listen((event) async {
      _isConnected = event.snapshot.value == true;

      if (!_isConnected) return;

      // Mark online only when the app is in the foreground.
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await _setOnline();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isConnected) {
        _setOnline();
      }
    } else if (state == AppLifecycleState.paused) {
      _setOffline();
    }
  }

  Future<void> _setOnline() async {
    final ref = _statusRef;
    if (ref == null || !_isConnected) return;

    try {
      // Register server-side disconnect handling first.
      await ref.onDisconnect().update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      await ref.update({
        'isOnline': true,
      });
    } catch (e) {
      debugPrint('Unable to set online: $e');
    }
  }

  Future<void> _setOffline() async {
    final ref = _statusRef;
    if (ref == null || !_isConnected) return;

    try {
      await ref.update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Unable to set offline: $e');
    }
  }

 Future<void> logoutPresence(String userId) async {
  final statusRef = _database.ref(
    '${ChatUtil.NODE_USER_STATUS}/$userId',
  );

  try {
    await statusRef.update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });

    await statusRef.onDisconnect().cancel();

    debugPrint('User set offline: $userId');
  } catch (e) {
    debugPrint('Failed to set user offline: $e');
  }
}

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }
}
