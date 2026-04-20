import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  factory AppException.fromSupabase(dynamic error) {
    // Network / connectivity errors
    if (error is SocketException || error is HttpException) {
      return AppException(
        'No internet connection. Please check your network and try again.',
        code: 'network_error',
        originalError: error,
      );
    }

    // Handle the error message string containing connection-related keywords
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection timed out')) {
      return AppException(
        'No internet connection. Please check your network and try again.',
        code: 'network_error',
        originalError: error,
      );
    }

    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    } else if (error is AuthException) {
      return _handleAuthException(error);
    } else if (error is StorageException) {
      return _handleStorageException(error);
    }

    return AppException(
      'An unexpected error occurred. Please try again.',
      originalError: error,
    );
  }

  static AppException _handlePostgrestException(PostgrestException error) {
    String message;
    switch (error.code) {
      case 'PGRST205':
        message =
            'Database configuration error: Table not found. Please contact support.';
        break;
      case '23505':
        message = 'This record already exists.';
        break;
      case '42P01':
        message = 'Table does not exist. Please check your database setup.';
        break;
      default:
        message = error.message;
    }
    return AppException(message, code: error.code, originalError: error);
  }

  static AppException _handleAuthException(AuthException error) {
    String message;
    switch (error.code) {
      case 'invalid_credentials':
        message = 'Invalid email or password.';
        break;
      case 'email_not_confirmed':
        message = 'Please confirm your email address.';
        break;
      case 'user_not_found':
        message = 'No user found with this email.';
        break;
      default:
        message = error.message;
    }
    return AppException(message, code: error.code, originalError: error);
  }

  // Inside lib/core/error/app_exception.dart

  static AppException _handleStorageException(StorageException error) {
    String message = error.message;
    if (error.message.toLowerCase().contains('bucket not found')) {
      message =
          'Storage error: The "avatars" bucket does not exist. Please create it in your Supabase dashboard.';
    }
    return AppException(message, code: error.statusCode, originalError: error);
  }

  @override
  String toString() => message;
}
