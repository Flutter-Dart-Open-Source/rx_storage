import 'package:meta/meta.dart';

import 'event.dart';
import 'logger.dart';

/// Default Logger's implementation, simply print to the console.
class DefaultLogger<Key extends Object, Options>
    implements Logger<Key, Options> {
  static const _rightArrow = '→';
  static const _leftArrow = '←';
  static const _downArrow = '↓';

  /// Construct a [DefaultLogger].
  const DefaultLogger();

  @nonVirtual
  @override
  void log(LoggerEvent<Key, Options> event) {
    //
    // BEGIN: STREAM
    //

    if (event is KeysChangedEvent<Key, Options>) {
      print(' $_downArrow Key changes');
      print(event.pairs.map((p) => '    $_rightArrow $p').join('\n'));
      return;
    }

    if (event is OnDataStreamEvent<Key, Options>) {
      print(' $_rightArrow Stream emits data: ${event.pair}');
      return;
    }

    if (event is OnErrorStreamEvent<Key, Options>) {
      print(' $_rightArrow Stream emits error: ${event.error}');
      return;
    }

    //
    // END: STREAM
    //

    //
    // BEGIN: READ
    //

    if (event is ReadValueSuccessEvent<Key, Options>) {
      final key = event.pair.key;
      final value = event.pair.value;
      final type = event.type;
      final options = event.options;
      print(
          " $_rightArrow Read: type=$type, key='$key'${_concatOptionsIfNotNull(options)} $_rightArrow $value");
      return;
    }

    if (event is ReadValueFailureEvent<Key, Options>) {
      final key = event.key;
      final type = event.type;
      final options = event.options;
      final error = event.error;
      print(
          " $_rightArrow Read: type=$type, key='$key'${_concatOptionsIfNotNull(options)} $_rightArrow $error");
      return;
    }

    if (event is ReadAllSuccessEvent<Key, Options>) {
      final all = event.all;
      final options = event.options;
      print(' $_downArrow Read all: ${_concatOptionsIfNotNull(options, '')}');
      print(all.map((p) => '    $_rightArrow $p').join('\n'));
      return;
    }

    if (event is ReadAllFailureEvent<Key, Options>) {
      final options = event.options;
      final error = event.error;
      print(
          ' $_rightArrow Read all: ${_concatOptionsIfNotNull(options, ':')} $_rightArrow $error');
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
          ' $_leftArrow Clear: ${_concatOptionsIfNotNull(options, ':')} $_rightArrow success');
      return;
    }

    if (event is ClearFailureEvent<Key, Options>) {
      final options = event.options;
      final error = event.error;
      print(
          ' $_leftArrow Clear: ${_concatOptionsIfNotNull(options, ':')} $_rightArrow $error');
      return;
    }

    if (event is RemoveSuccessEvent<Key, Options>) {
      final key = event.key;
      final options = event.options;
      print(
          " $_leftArrow Remove: key='$key'${_concatOptionsIfNotNull(options)} $_rightArrow success");
      return;
    }

    if (event is RemoveFailureEvent<Key, Options>) {
      final key = event.key;
      final options = event.options;
      final error = event.error;
      print(
          " $_leftArrow Remove: key='$key'${_concatOptionsIfNotNull(options)} $_rightArrow $error");
      return;
    }

    if (event is WriteSuccessEvent<Key, Options>) {
      final key = event.pair.key;
      final value = event.pair.value;
      final type = event.type;
      final options = event.options;
      print(
          " $_leftArrow Write: key='$key', value=$value, type=$type${_concatOptionsIfNotNull(options)} $_rightArrow success");
      return;
    }

    if (event is WriteFailureEvent<Key, Options>) {
      final key = event.pair.key;
      final value = event.pair.value;
      final type = event.type;
      final options = event.options;
      final error = event.error;
      print(
          " $_leftArrow Write: key='$key', value=$value, type=$type${_concatOptionsIfNotNull(options)} $_rightArrow $error");
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

  static String _concatOptionsIfNotNull(Object? options,
          [String separator = ',']) =>
      options == null ? '' : '$separator options=$options';
}
