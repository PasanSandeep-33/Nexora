
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppErrorMessage {
  static String fromException(
    Object error, {
    String resource = 'information',
  }) {
    if (error is TimeoutException) {
      return 'The server is taking longer than expected to respond. '
          'Please check your internet connection and try again in a moment.';
    }

    if (error is http.ClientException ||
        (!kIsWeb && error is SocketException)) {
      return 'Unable to connect to the server. '
          'Please check your internet connection and try again.';
    }

    final message = error.toString().toLowerCase();

    if (message.contains('401') ||
        message.contains('session expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('403') ||
        message.contains('permission denied')) {
      return "You don't have permission to access this information.";
    }

    if (RegExp(r'\b5\d\d\b').hasMatch(message)) {
      return 'The server is temporarily unavailable. '
          'Please try again shortly.';
    }

    return "We couldn't load $resource right now. "
        'Please try again.';
  }
}
