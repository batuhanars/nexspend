// ignore_for_file: constant_identifier_names

enum ReceiptStatus { PROCESSING, PARSED, CONFIRMED, FAILED }

class ReceiptItemModel {
  const ReceiptItemModel({
    required this.name,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
    required this.sortOrder,
  });

  final String name;
  final double? quantity;
  final double? unitPrice;
  final double totalPrice;
  final int sortOrder;

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      ReceiptItemModel(
        name: json['name'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class ReceiptParseResult {
  const ReceiptParseResult({
    this.receiptId,
    this.amount,
    this.date,
    this.merchantName,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.items = const [],
    this.confidence = 0.0,
    this.isDuplicate = false,
    this.paymentMethod,
    this.taxAmount,
  });

  final String? receiptId;
  final double? amount;
  final DateTime? date;
  final String? merchantName;
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final List<ReceiptItemModel> items;
  final double confidence;
  final bool isDuplicate;
  final String? paymentMethod;
  final double? taxAmount;

  factory ReceiptParseResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ReceiptParseResult(
      receiptId: data['id'] as String? ?? data['receiptId'] as String?,
      amount: (data['amount'] as num?)?.toDouble() ??
          (data['totalAmount'] as num?)?.toDouble(),
      date: data['date'] != null
          ? DateTime.tryParse(data['date'] as String)
          : null,
      merchantName: data['merchantName'] as String?,
      suggestedCategoryId: data['suggestedCategoryId'] as String?,
      suggestedCategoryName: data['suggestedCategoryName'] as String?,
      items: (data['items'] as List? ?? [])
          .map((i) => ReceiptItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      confidence: (data['confidence'] as num? ?? 0).toDouble(),
      isDuplicate: data['isDuplicate'] as bool? ?? false,
      paymentMethod: data['paymentMethod'] as String?,
      taxAmount: (data['parsedTax'] as num?)?.toDouble(),
    );
  }

  ReceiptParseResult copyWith({
    String? receiptId,
    double? amount,
    DateTime? date,
    String? merchantName,
    String? suggestedCategoryId,
    String? suggestedCategoryName,
  }) =>
      ReceiptParseResult(
        receiptId: receiptId ?? this.receiptId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        merchantName: merchantName ?? this.merchantName,
        suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
        suggestedCategoryName:
            suggestedCategoryName ?? this.suggestedCategoryName,
        items: items,
        confidence: confidence,
        isDuplicate: isDuplicate,
        paymentMethod: paymentMethod,
        taxAmount: taxAmount,
      );
}

class ReceiptHistoryModel {
  const ReceiptHistoryModel({
    required this.id,
    required this.status,
    this.amount,
    this.merchantName,
    this.date,
    this.confidence,
    this.imagePath,
  });

  final String id;
  final ReceiptStatus status;
  final double? amount;
  final String? merchantName;
  final DateTime? date;
  final double? confidence;
  final String? imagePath;

  factory ReceiptHistoryModel.fromJson(Map<String, dynamic> json) =>
      ReceiptHistoryModel(
        id: json['id'] as String,
        status: ReceiptStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReceiptStatus.PARSED,
        ),
        amount: (json['totalAmount'] as num?)?.toDouble(),
        merchantName: json['merchantName'] as String?,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
        confidence: (json['confidence'] as num?)?.toDouble(),
        imagePath: json['imagePath'] as String?,
      );
}
