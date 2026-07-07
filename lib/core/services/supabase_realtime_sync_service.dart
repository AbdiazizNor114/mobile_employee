import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'local_notification_service.dart';

class SupabaseRealtimeSyncService {
  SupabaseRealtimeSyncService({
    required AppConfig config,
    required AuthService authService,
    required LocalNotificationService notifications,
  })  : _config = config,
        _authService = authService,
        _notifications = notifications;

  final AppConfig _config;
  final AuthService _authService;
  final LocalNotificationService _notifications;

  SupabaseClient? _client;
  final List<RealtimeChannel> _channels = [];
  Timer? _debounce;
  bool _started = false;

  Future<void> start({required Future<void> Function() onChange}) async {
    if (_started) return;
    final companyId = _authService.companyId;
    final accessToken = _authService.accessToken;
    if (!_config.hasSupabaseConfig) {
      debugPrint('ShaqoNet Supabase realtime disabled: missing config.');
      return;
    }
    if (companyId == null || accessToken == null) {
      debugPrint('ShaqoNet Supabase realtime disabled: missing session.');
      return;
    }

    _started = true;
    try {
      final client = SupabaseClient(
        _config.supabaseUrl,
        _config.supabaseAnonKey,
        accessToken: () async => _authService.accessToken,
      );
      await client.realtime.setAuth(accessToken);
      _client = client;

      for (final table in const [
        'messages',
        'shifts',
        'absences',
        'time_entries',
        'notifications',
      ]) {
        final channel = client.channel('mobile-$companyId-$table')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'company_id',
              value: companyId,
            ),
            callback: (_) => _scheduleSync(onChange),
          );
        channel.subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('ShaqoNet Supabase realtime subscribed: $table');
            return;
          }
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint(
              'ShaqoNet Supabase realtime $status for $table: $error',
            );
          }
        });
        _channels.add(channel);
      }
    } catch (error) {
      debugPrint('ShaqoNet Supabase realtime disabled: $error');
      await stop();
    }
  }

  Future<void> stop() async {
    _started = false;
    _debounce?.cancel();
    _debounce = null;

    final client = _client;
    if (client != null) {
      for (final channel in _channels) {
        try {
          await client.removeChannel(channel);
        } catch (_) {}
      }
    }
    _channels.clear();
    _client = null;
  }

  void _scheduleSync(Future<void> Function() onChange) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _notifications.showWorkUpdate();
      onChange();
    });
  }
}
