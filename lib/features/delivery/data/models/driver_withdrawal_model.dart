import 'package:equatable/equatable.dart';

enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
}

enum WithdrawalMethod {
  bankTransfer,
  paypal,
  stripe,
}

class DriverWithdrawalModel extends Equatable {
  final String id;
  final String driverId;
  final double amount;
  final WithdrawalStatus status;
  final WithdrawalMethod? method;
  final String? bankAccountNumber;
  final String? transactionReference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const DriverWithdrawalModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    this.method,
    this.bankAccountNumber,
    this.transactionReference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory DriverWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return DriverWithdrawalModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      method: json['withdrawal_method'] != null
          ? WithdrawalMethod.values.firstWhere(
              (e) => e.name == json['withdrawal_method'],
              orElse: () => WithdrawalMethod.bankTransfer,
            )
          : null,
      bankAccountNumber: json['bank_account_number'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'amount': amount,
      'status': status.name,
      'withdrawal_method': method?.name,
      'bank_account_number': bankAccountNumber,
      'transaction_reference': transactionReference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  DriverWithdrawalModel copyWith({
    String? id,
    String? driverId,
    double? amount,
    WithdrawalStatus? status,
    WithdrawalMethod? method,
    String? bankAccountNumber,
    String? transactionReference,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return DriverWithdrawalModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      transactionReference: transactionReference ?? this.transactionReference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        amount,
        status,
        method,
        bankAccountNumber,
        transactionReference,
        notes,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
