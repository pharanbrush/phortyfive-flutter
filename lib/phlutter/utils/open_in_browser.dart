import 'package:url_launcher/url_launcher.dart';

Future<bool> openInBrowser(Uri uri) {
  return launchUrl(uri);
}
