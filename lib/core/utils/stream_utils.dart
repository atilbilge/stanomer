import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps a stream factory in a [RetryWhenStream] to automatically reconnect and
/// retry the subscription if a network or subscription timeout error occurs.
Stream<T> resilientStream<T>(
  Stream<T> Function() streamFactory, {
  String? debugName,
}) {
  return RetryWhenStream<T>(
    streamFactory,
    (Object error, StackTrace stackTrace) {
      final isRealtimeError = error is RealtimeSubscribeException ||
          error.toString().contains('RealtimeSubscribeException') ||
          error.toString().contains('timedOut') ||
          error.toString().contains('TimeoutException') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('WebSocketChannelException') ||
          error.toString().contains('HandshakeException');

      debugPrint(
        'DEBUG: [resilientStream${debugName != null ? ' - $debugName' : ''}] '
        'Stream encountered error: $error. '
        '${isRealtimeError ? 'Attempting reconnection and retry in 2 seconds...' : 'Not a retryable error, propagating.'}',
      );

      if (isRealtimeError) {
        try {
          // Force reconnection of the realtime socket when a timeout/network error happens
          // ignore: invalid_use_of_internal_member
          Supabase.instance.client.realtime.connect();
        } catch (e) {
          debugPrint('DEBUG: Error forcing realtime connect: $e');
        }
        // Wait 2 seconds before retrying the stream subscription
        return Rx.timer<void>(null, const Duration(seconds: 2));
      }

      // Propagate non-realtime/non-network errors
      return Stream.error(error, stackTrace);
    },
  );
}
