import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

http.Client createPlatformClient({bool withCredentials = false}) {
  final client = BrowserClient();
  if (withCredentials) {
    try {
      client.withCredentials = true;
    } catch (_) {}
  }
  return client;
}
