class ErrorCode {
  String? message;
  Map<String, dynamic>? extraData;

  ErrorCode.fromString({this.message, this.extraData});

  @override
  String toString() {
    if (message != null) return message!;
    return 'Unknown error';
  }

  String toLocalString() {
    if (message != null) return message!;
    return 'Unknown error';
  }
}