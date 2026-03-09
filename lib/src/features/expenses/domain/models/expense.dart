import 'package:flutter/material.dart';

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.note,
    required this.paymentMethod,
    required this.date,
    required this.icon,
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String note;
  final String paymentMethod;
  final DateTime date;
  final IconData icon;

  Expense copyWith({
    String? id,
    double? amount,
    String? currencyCode,
    String? category,
    String? note,
    String? paymentMethod,
    DateTime? date,
    IconData? icon,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      icon: icon ?? this.icon,
    );
  }

  Map<String, Object> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'category': category,
      'note': note,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      category: map['category'] as String,
      note: map['note'] as String,
      paymentMethod: map['paymentMethod'] as String,
      date: DateTime.parse(map['date'] as String),
      icon: _iconForCategory(map['category'] as String),
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Travel':
        return Icons.directions_car_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Health':
        return Icons.medical_services_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Entertainment':
        return Icons.movie_creation_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
