import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class ModelSpec {
  const ModelSpec({
    required this.id,
    required this.repository,
    required this.fileName,
    required this.sizeLabel,
  });

  final String id;
  final String repository;
  final String fileName;
  final String sizeLabel;

  Uri get downloadUri => Uri.https(
    'huggingface.co',
    '/$repository/resolve/main/$fileName',
    {'download': 'true'},
  );

  Uri get metadataUri => Uri.https(
    'huggingface.co',
    '/api/models/$repository/tree/main',
    {'recursive': 'false', 'expand': 'true'},
  );
}

class ModelCatalog {
  static const standard = ModelSpec(
    id: 'qwen2.5-coder-1.5b-q4',
    repository: 'Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF',
    fileName: 'qwen2.5-coder-1.5b-instruct-q4_k_m.gguf',
    sizeLabel: 'about 1.1 GB',
  );
  static const lowMemory = ModelSpec(
    id: 'qwen3-0.6b-q4',
    repository: 'second-state/Qwen3-0.6B-GGUF',
    fileName: 'Qwen3-0.6B-Q4_K_M.gguf',
    sizeLabel: 'about 450 MB',
  );
}

/// Resumable model download with SHA-256 taken from the repository's LFS record.
class ModelManager {
  ModelManager({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;

  Future<File> modelFile(ModelSpec spec) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}models');
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}${spec.fileName}');
  }

  Future<File> download(
    ModelSpec spec, {
    required void Function(double progress) onProgress,
  }) async {
    final file = await modelFile(spec);
    final digestFile = File('${file.path}.sha256');
    if (await file.exists()) {
      final cachedDigest = await digestFile.exists()
          ? (await digestFile.readAsString()).trim()
          : '';
      final expected = cachedDigest.isEmpty
          ? await _remoteSha256(spec)
          : cachedDigest;
      if (await _sha256(file) == expected) {
        if (cachedDigest.isEmpty) await digestFile.writeAsString(expected);
        onProgress(1);
        return file;
      }
      await file.delete();
    }

    final partial = File('${file.path}.part');
    final expectedHash = await _remoteSha256(spec);
    final offset = await partial.exists() ? await partial.length() : 0;
    final request = await _client.getUrl(spec.downloadUri);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    if (offset > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
    }
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.partialContent) {
      throw HttpException(
        'Model download returned HTTP ${response.statusCode}.',
      );
    }
    final append =
        offset > 0 && response.statusCode == HttpStatus.partialContent;
    final sink = partial.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    final fullLength = append && response.contentLength >= 0
        ? offset + response.contentLength
        : response.contentLength;
    var received = append ? offset : 0;
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (fullLength > 0) {
          onProgress((received / fullLength).clamp(0, 1).toDouble());
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    final actualHash = await _sha256(partial);
    if (actualHash != expectedHash) {
      await partial.delete();
      throw const FormatException(
        'Downloaded model failed SHA-256 verification.',
      );
    }
    if (await file.exists()) await file.delete();
    final verified = await partial.rename(file.path);
    await digestFile.writeAsString(expectedHash);
    return verified;
  }

  Future<String> _remoteSha256(ModelSpec spec) async {
    final request = await _client.getUrl(spec.metadataUri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Model checksum lookup returned HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(await response.transform(utf8.decoder).join());
    if (decoded is! List) {
      throw const FormatException('Invalid model metadata response.');
    }
    for (final row in decoded) {
      if (row is Map &&
          (row['path'] == spec.fileName || row['name'] == spec.fileName)) {
        final lfs = row['lfs'];
        if (lfs is Map && lfs['sha256'] is String) {
          return (lfs['sha256'] as String).toLowerCase();
        }
      }
    }
    throw const FormatException(
      'The model repository did not provide a SHA-256 digest.',
    );
  }

  Future<String> _sha256(File file) async =>
      (await sha256.bind(file.openRead()).first).toString().toLowerCase();

  void close() => _client.close(force: true);
}
