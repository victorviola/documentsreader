import 'package:iproov_flutter/iproov_flutter.dart';
import '../config/config.dart';

class IProovService {

  static Future<IProovEvent> launchWithToken(String token) async {
    try {
      final stream = IProov.launch(
        streamingUrl: '${AppConfig.iproovService}',
        token: token,
      );

      await for (final event in stream) {
        if (event is IProovEventSuccess ||
            event is IProovEventFailure ||
            event is IProovEventError) {
          return event;
        }
      }

      return IProovEventError.create(
        'no_event',
        'No event returned',
        'The iProov stream ended without a final event.',
      );
    } catch (e) {
      return IProovEventError.create(
        'unexpectedError',
        'Unexpected Error',
        e.toString(),
      );
    }
  }
}
