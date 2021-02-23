import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../model/key_and_value.dart';
import 'event.dart';
import 'logger.dart';

// ignore_for_file: public_member_api_docs

/// Default Logger's implementation, simply print to the console.
class DefaultLogger<Key extends Object, Options>
    implements Logger<Key, Options> {
  //
  // some unicode characters
  // and constants.
  //
  static const leftArrow = '←';
  static const rightArrow = '→';
  static const downArrow = '↓';
  static const defaultTag = '🔥 RxStorage';
  static const maxValueTextLength = 40;

  //
  //
  //

  /// Log tag.
  final String tag;

  /// If [trimValueOutput] is true, value text will be trimmed to max [maxValueTextLength] characters.
  final bool trimValueOutput;

  /// Construct a [DefaultLogger].
  const DefaultLogger({this.tag = defaultTag, this.trimValueOutput = false});

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String _trimValue(Object? value) {
    final s = value.toString();
    return s.length > maxValueTextLength && trimValueOutput
        ? '${s.take(maxValueTextLength ~/ 2)}...${s.takeLast(maxValueTextLength ~/ 2)}'
        : s;
  }

  //
  // protected.
  //
  @protected
  static String concatOptionsIfNotNull(Object? options,
          [String separator = ',']) =>
      options == null ? '' : '$separator options=$options';

  @nonVirtual
  @protected
  String keyAndValueToString(KeyAndValue<Key, Object?> keyAndValue) =>
      '{ key: ${keyAndValue.key}, type: ${keyAndValue.type}, value: ${_trimValue(keyAndValue.value)} }';

  //
  // public.
  //

  @nonVirtual
  @override
  void log(LoggerEvent<Key, Options> event) {
    //
    // BEGIN: STREAM
    //

    if (event is KeysChangedEvent<Key, Options>) {
      print('$tag $downArrow Key changes');
      print(event.keyAndValues
          .map((p) => '    $rightArrow ${keyAndValueToString(p)}')
          .join('\n'));
      return;
    }

    if (event is OnDataStreamEvent<Key, Options>) {
      print(
          '$tag $rightArrow Stream emits data: ${keyAndValueToString(event.keyAndValue)}');
      return;
    }

    if (event is OnErrorStreamEvent<Key, Options>) {
      print('$tag $rightArrow Stream emits error: ${event.error}');
      return;
    }

    //
    // END: STREAM
    //

    //
    // BEGIN: READ
    //

    if (event is ReadValueSuccessEvent<Key, Options>) {
      final key = event.keyAndValue.key;
      final value = event.keyAndValue.value;
      final type = event.keyAndValue.type;
      final options = event.options;
      print(
          '$tag $rightArrow Read: key=$key, type=$type${concatOptionsIfNotNull(options)} $rightArrow ${_trimValue(value)}');
      return;
    }

    if (event is ReadValueFailureEvent<Key, Options>) {
      final key = event.key;
      final type = event.type;
      final options = event.options;
      final error = event.error;
      print(
          '$tag $rightArrow Read: key=$key, type=$type${concatOptionsIfNotNull(options)} $rightArrow $error');
      return;
    }

    if (event is ReadAllSuccessEvent<Key, Options>) {
      final all = event.all;
      final options = event.options;
      print('$tag $downArrow Read all${concatOptionsIfNotNull(options, ':')}');
      print(all
          .map((p) => '    $rightArrow ${keyAndValueToString(p)}')
          .join('\n'));
      return;
    }

    if (event is ReadAllFailureEvent<Key, Options>) {
      final options = event.options;
      final error = event.error;
      print(
          '$tag $rightArrow Read all${concatOptionsIfNotNull(options, ':')} $rightArrow $error');
      return;
    }

    //
    // END: READ
    //

    //
    // BEGIN: WRITE
    //

    if (event is ClearSuccessEvent<Key, Options>) {
      final options = event.options;
      print(
          '$tag $leftArrow Clear${concatOptionsIfNotNull(options, ':')} $rightArrow success');
      return;
    }

    if (event is ClearFailureEvent<Key, Options>) {
      final options = event.options;
      final error = event.error;
      print(
          '$tag $leftArrow Clear${concatOptionsIfNotNull(options, ':')} $rightArrow $error');
      return;
    }

    if (event is RemoveSuccessEvent<Key, Options>) {
      final key = event.key;
      final options = event.options;
      print(
          '$tag $leftArrow Remove: key=$key${concatOptionsIfNotNull(options)} $rightArrow success');
      return;
    }

    if (event is RemoveFailureEvent<Key, Options>) {
      final key = event.key;
      final options = event.options;
      final error = event.error;
      print(
          '$tag $leftArrow Remove: key=$key${concatOptionsIfNotNull(options)} $rightArrow $error');
      return;
    }

    if (event is WriteSuccessEvent<Key, Options>) {
      final key = event.keyAndValue.key;
      final value = event.keyAndValue.value;
      final type = event.keyAndValue.type;
      final options = event.options;
      print(
          '$tag $leftArrow Write: key=$key, type=$type${concatOptionsIfNotNull(options)}, value=${_trimValue(value)} $rightArrow success');
      return;
    }

    if (event is WriteFailureEvent<Key, Options>) {
      final key = event.keyAndValue.key;
      final value = event.keyAndValue.value;
      final type = event.keyAndValue.type;
      final options = event.options;
      final error = event.error;
      print(
          '$tag $leftArrow Write: key=$key, type=$type${concatOptionsIfNotNull(options)}, value=${_trimValue(value)} $rightArrow $error');
      return;
    }

    //
    // END: WRITE
    //

    logOther(event);
  }

  /// Logs other events.
  void logOther(LoggerEvent<Key, Options> event) =>
      throw Exception('Unhandled event: $event');
}

extension on String {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String take(int n) {
    if (n < 0) {
      throw ArgumentError.value(
        n,
        'n',
        'Requested character count is less than zero.',
      );
    }
    return substring(0, math.min(n, length));
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String takeLast(int n) {
    if (n < 0) {
      throw ArgumentError.value(
        n,
        'n',
        'Requested character count is less than zero.',
      );
    }
    return substring(length - math.min(n, length));
  }
}
