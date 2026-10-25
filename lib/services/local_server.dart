import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class LocalServer {
  HttpServer? _server;
  bool get isRunning => _server != null;
  String get address =>
      _server != null ? 'http://${_server!.address.address}:${_server!.port}' : '';

  Future<String> _booksDir() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/library_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> start(List<Book> books) async {
    final dir = await _booksDir();
    final staticHandler = createStaticHandler(dir);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler((Request req) {
          if (req.url.path == 'api/books') {
            final list = books.map((b) => b.toJson()).toList();
            return Response.ok(jsonEncode(list),
                headers: {'Content-Type': 'application/json; charset=utf-8'});
          }
          return staticHandler(req);
        });

    _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<String> copyToLibrary(File source, String fileName) async {
    final dir = await _booksDir();
    final dest = File('$dir/$fileName');
    await source.copy(dest.path);
    return dest.path;
  }
}
