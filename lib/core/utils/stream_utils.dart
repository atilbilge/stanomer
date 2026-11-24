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
  int retryAttempt = 0;
  DateTime lastRetryTime = DateTime.now();

  return RetryWhenStream<T>(
    streamFactory,
    (Object error, StackTrace stackTrace) {
      final errStr = error.toString();
      final isRateLimit = errStr.contains('RateLimit') ||
          errStr.contains('SocketJoinRateLimitReached') ||
          errStr.contains('ChannelRateLimitReached');

      final isRealtimeError = error is RealtimeSubscribeException ||
          errStr.contains('RealtimeSubscribeException') ||
          errStr.contains('timedOut') ||
          errStr.contains('TimeoutException') ||
          errStr.contains('SocketException') ||
          errStr.contains('WebSocketChannelException') ||
          errStr.contains('HandshakeException') ||
          isRateLimit;

      // Reset retry counter if more than 60 seconds passed since last error
      final now = DateTime.now();
      if (now.difference(lastRetryTime).inSeconds > 60) {
        retryAttempt = 0;
      }
      lastRetryTime = now;
      retryAttempt++;

      // Exponential backoff: 2s -> 4s -> 8s -> 16s capped at 30s. If rate-limited, min 15s.
      int delaySeconds = 2 * (1 << (retryAttempt > 4 ? 4 : retryAttempt - 1));
      if (delaySeconds > 30) delaySeconds = 30;
      if (isRateLimit && delaySeconds < 15) {
        delaySeconds = 15;
      }

      debugPrint(
        'DEBUG: [resilientStream${debugName != null ? ' - $debugName' : ''}] '
        'Stream encountered error: $error (Attempt: $retryAttempt, Delay: ${delaySeconds}s). '
        '${isRealtimeError ? 'Attempting retry in $delaySeconds seconds...' : 'Not a retryable error, propagating.'}',
      );

      if (isRealtimeError) {
        // DO NOT spam socket connect if error is rate limit or too many joins!
        if (!isRateLimit) {
          try {
            // Force reconnection of the realtime socket when a timeout/network error happens
            // ignore: invalid_use_of_internal_member
            Supabase.instance.client.realtime.connect();
          } catch (e) {
            debugPrint('DEBUG: Error forcing realtime connect: $e');
          }
        }
        // Wait backoff duration before retrying the stream subscription
        return Rx.timer<void>(null, Duration(seconds: delaySeconds));
      }

      // Propagate non-realtime/non-network errors
      return Stream.error(error, stackTrace);
    },
  );
}
