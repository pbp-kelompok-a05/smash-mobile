import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createPlatformClient({bool withCredentials = false}) {
  return IOClient();
}
