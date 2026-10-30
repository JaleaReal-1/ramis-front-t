import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> writeDownloadedFile(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<void> openDownloadedFile(String name, List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final file = File(
      '${directory.path}/${name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) throw StateError(result.message);
}
