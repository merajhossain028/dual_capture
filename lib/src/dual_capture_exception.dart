/// Thrown when any step of the dual-capture pipeline fails.
class DualCaptureException implements Exception {
  /// Creates a [DualCaptureException] with a [message] and an optional [cause].
  const DualCaptureException(this.message, [this.cause]);

  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying error or exception, if any.
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'DualCaptureException: $message (cause: $cause)';
    }
    return 'DualCaptureException: $message';
  }
}
