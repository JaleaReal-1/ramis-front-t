import 'dart:io';

Future<void> writeDownloadedFile(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
