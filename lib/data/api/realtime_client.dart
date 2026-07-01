import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Realtime signalling over the backend WebSocket (`/realtime`).
///
/// The server sends tiny "something changed" notifications; this client turns
/// them into broadcast streams the repository listens to and re-fetches from.
/// It mirrors the old Supabase pattern (stream event -> refetch) while keeping
/// authorization on the server and payloads free of data.
///
/// Subscriptions are intent-based: callers declare what they care about
/// (lists / a list's tasks) and the client re-asserts those intents after every
/// (re)connect, so a dropped socket recovers transparently.
class RealtimeClient {
  RealtimeClient(this._api);

  final ApiClient _api;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnect;
  int _attempt = 0;
  bool _disposed = false;

  bool _wantLists = false;
  final Set<String> _wantTasks = <String>{};

  final _lists = StreamController<void>.broadcast();
  final _tasks = StreamController<String>.broadcast();
  final _friends = StreamController<void>.broadcast();

  /// Fires when the user's set of lists may have changed.
  Stream<void> get onListsChanged => _lists.stream;

  /// Fires with the affected listId when a list's tasks may have changed.
  Stream<String> get onTasksChanged => _tasks.stream;

  /// Fires when the user's friends may have changed.
  Stream<void> get onFriendsChanged => _friends.stream;

  // --- intents -------------------------------------------------------------

  void subscribeLists() {
    _wantLists = true;
    _ensureConnected();
    _send({'type': 'sub_lists'});
  }

  void subscribeTasks(String listId) {
    _wantTasks.add(listId);
    _ensureConnected();
    _send({'type': 'sub_tasks', 'listId': listId});
  }

  void unsubscribeTasks(String listId) {
    _wantTasks.remove(listId);
    _send({'type': 'unsub_tasks', 'listId': listId});
  }

  // --- connection ----------------------------------------------------------

  void _ensureConnected() {
    if (_disposed || _channel != null) return;
    final token = _api.accessToken;
    if (token == null || !ApiConfig.isConfigured) return;

    final uri = Uri.parse(
      '${ApiConfig.wsBaseUrl}/realtime?access_token=${Uri.encodeQueryComponent(token)}',
    );
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (_) => _onClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    _attempt = 0; // a healthy message resets backoff
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'ready':
        _resubscribe();
        break;
      case 'lists_changed':
        _lists.add(null);
        break;
      case 'tasks_changed':
        final id = msg['listId'];
        if (id is String) _tasks.add(id);
        break;
      case 'friends_changed':
        _friends.add(null);
        break;
      case 'pong':
      case 'error':
      default:
        break;
    }
  }

  void _resubscribe() {
    if (_wantLists) _send({'type': 'sub_lists'});
    for (final id in _wantTasks) {
      _send({'type': 'sub_tasks', 'listId': id});
    }
  }

  void _onClosed() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (!_wantLists && _wantTasks.isEmpty) return; // nothing to keep alive
    _reconnect?.cancel();
    final seconds = (1 << _attempt.clamp(0, 5)).clamp(1, 32);
    _attempt++;
    _reconnect = Timer(Duration(seconds: seconds), _ensureConnected);
  }

  void _send(Map<String, dynamic> msg) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(msg));
    } catch (_) {
      // Sink not ready / closed: the reconnect path will re-assert intents.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnect?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _lists.close();
    await _tasks.close();
    await _friends.close();
  }
}
