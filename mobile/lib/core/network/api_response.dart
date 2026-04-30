class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }
}
