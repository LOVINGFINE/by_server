import 'dart:async';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:string_scanner/string_scanner.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http_parser/http_parser.dart';

Map<String, String>? _parseFormDataContentDisposition(String header) {
  final scanner = StringScanner(header);
  final _token = RegExp(r'[^()<>@,;:"\\/[\]?={} \t\x00-\x1F\x7F]+');
  final _whitespace = RegExp(r'(?:(?:\r\n)?[ \t]+)*');
  final _quotedString = RegExp(r'"(?:[^"\x00-\x1F\x7F]|\\.)*"');
  final _quotedPair = RegExp(r'\\(.)');
  scanner
    ..scan(_whitespace)
    ..expect(_token);
  if (scanner.lastMatch![0] != 'form-data') return null;

  final params = <String, String>{};

  while (scanner.scan(';')) {
    scanner
      ..scan(_whitespace)
      ..scan(_token);
    final key = scanner.lastMatch![0]!;
    scanner.expect('=');

    String value;
    if (scanner.scan(_token)) {
      value = scanner.lastMatch![0]!;
    } else {
      scanner.expect(_quotedString, name: 'quoted string');
      final string = scanner.lastMatch![0]!;

      value = string
          .substring(1, string.length - 1)
          .replaceAllMapped(_quotedPair, (match) => match[1]!);
    }

    scanner.scan(_whitespace);
    params[key] = value;
  }

  scanner.expectDone();
  return params;
}

extension ReadMultipartRequest on Request {
  bool get isMultipart => _extractMultipartBoundary() != null;
  Stream<Multipart> get parts {
    final boundary = _extractMultipartBoundary();
    if (boundary == null) {
      throw StateError('Not a multipart request.');
    }

    return MimeMultipartTransformer(boundary)
        .bind(read())
        .map((part) => Multipart(this, part));
  }

  String? _extractMultipartBoundary() {
    if (!headers.containsKey('Content-Type')) return null;

    final contentType = MediaType.parse(headers['Content-Type']!);
    if (contentType.type != 'multipart') return null;

    return contentType.parameters['boundary'];
  }

  bool get isMultipartForm {
    final rawContentType = headers['Content-Type'];
    if (rawContentType == null) return false;

    final type = MediaType.parse(rawContentType);
    return type.type == 'multipart' && type.subtype == 'form-data';
  }

  Stream<FormDataFile> get multipartFormData {
    return parts
        .map<FormDataFile?>((part) {
          final rawDisposition = part.headers['content-disposition'];
          if (rawDisposition == null) return null;

          final formDataParams =
              _parseFormDataContentDisposition(rawDisposition);
          if (formDataParams == null) return null;

          final name = formDataParams['name'];
          if (name == null) return null;

          return FormDataFile(name, formDataParams['filename'], part);
        })
        .where((data) => data != null)
        .cast();
  }
}

class Multipart extends MimeMultipart {
  final Request _originalRequest;
  final MimeMultipart _inner;

  @override
  final Map<String, String> headers;

  late final MediaType? _contentType = _parseContentType();

  Encoding? get _encoding {
    var contentType = _contentType;
    if (contentType == null) return null;
    if (!contentType.parameters.containsKey('charset')) return null;
    return Encoding.getByName(contentType.parameters['charset']);
  }

  Multipart(this._originalRequest, this._inner)
      : headers = CaseInsensitiveMap.from(_inner.headers);

  MediaType? _parseContentType() {
    final value = headers['content-type'];
    if (value == null) return null;

    return MediaType.parse(value);
  }

  Future<Uint8List> readBytes() async {
    final builder = BytesBuilder();
    await forEach(builder.add);
    return builder.takeBytes();
  }

  Future<String> readString([Encoding? encoding]) {
    encoding ??= _encoding ?? _originalRequest.encoding ?? utf8;
    return encoding.decodeStream(this);
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> data)? onData,
      {void Function()? onDone, Function? onError, bool? cancelOnError}) {
    return _inner.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }
}

class FormDataFile {
  final String name;

  final String? filename;

  final Multipart part;

  FormDataFile(this.name, this.filename, this.part);
}

class BodyResult {
  /// The parsed json.
  dynamic json = {};

  /// All files uploaded within this request.
  Stream<FormDataFile> files = Stream.empty();

  /// You must set [storeOriginalBuffer] to `true` to see this.
  List<int> originalBuffer = [];
}

class BodyParserHelper {
  Request request;
  BodyParserHelper(this.request);

  Future<BodyResult> getBodyResult() async {
    var body = BodyResult();
    try {
      MediaType contentType = MediaType.parse(
          request.headers['content-type'] ?? 'application/json');
      if (contentType.mimeType == 'application/json') {
        String bodyString = await request.readAsString();
        body.json = jsonDecode(bodyString);
      }
    } catch (e) {
      body.json = {};
    }
    try {
      if (request.isMultipartForm) {
        body.files = request.multipartFormData;
      }
    } catch (e) {
      body.files = Stream.empty();
    }
    return body;
  }
}
