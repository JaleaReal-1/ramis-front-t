/// Represents a transport domain failure, wrapping HTTP errors from the API.
class TransportFailure implements Exception {
  const TransportFailure({
    required this.message,
    this.statusCode,
    this.validationErrors = const <String>[],
  });

  final String message;
  final int? statusCode;
  final List<String> validationErrors;

  bool get isForbidden => statusCode == 403;
  bool get isBadRequest => statusCode == 400;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
