import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReclamationStatus {
  enAttente('En attente', Color(0xFFF59E0B)),
  enCours('En cours', Color(0xFF3B82F6)),
  resolue('Résolue', Color(0xFF10B981)),
  rejetee('Rejetée', Color(0xFFEF4444));

  final String label;
  final Color color;
  const ReclamationStatus(this.label, this.color);

  static ReclamationStatus fromString(String? val) {
    if (val == null) return ReclamationStatus.enAttente;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'en_cours':
      case 'encours':
      case 'en cours':
        return ReclamationStatus.enCours;
      case 'resolue':
      case 'résolue':
        return ReclamationStatus.resolue;
      case 'rejetee':
      case 'rejetée':
        return ReclamationStatus.rejetee;
      case 'en_attente':
      case 'enattente':
      case 'en attente':
      default:
        return ReclamationStatus.enAttente;
    }
  }
}

class ReclamationModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String? orderId;
  final String? vendorId;
  final String vendorName;
  final String subject;
  final String category;
  final String description;
  final ReclamationStatus status;
  final String priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? response;
  final DateTime? respondedAt;
  final String? respondedBy;
  final DateTime? resolvedAt;

  const ReclamationModel({
    this.id = '',
    required this.clientId,
    required this.clientName,
    this.clientPhone = '',
    this.clientEmail = '',
    this.orderId,
    this.vendorId,
    this.vendorName = '',
    required this.subject,
    required this.category,
    required this.description,
    this.status = ReclamationStatus.enAttente,
    this.priority = 'Moyenne',
    required this.createdAt,
    this.updatedAt,
    this.response,
    this.respondedAt,
    this.respondedBy,
    this.resolvedAt,
  });

  factory ReclamationModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return ReclamationModel(
      id: id,
      clientId: (data['clientId'] as String?) ?? '',
      clientName: (data['clientName'] as String?) ?? '',
      clientPhone: (data['clientPhone'] as String?) ?? '',
      clientEmail: (data['clientEmail'] as String?) ?? '',
      orderId: (data['orderId'] as String?)?.isNotEmpty == true ? (data['orderId'] as String) : null,
      vendorId: (data['vendorId'] as String?)?.isNotEmpty == true ? (data['vendorId'] as String) : null,
      vendorName: (data['vendorName'] as String?) ?? '',
      subject: (data['subject'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'Autre',
      description: (data['description'] as String?) ?? '',
      status: ReclamationStatus.fromString(data['status'] as String?),
      priority: (data['priority'] as String?) ?? 'Moyenne',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseNullableDate(data['updatedAt']),
      response: data['response'] as String?,
      respondedAt: parseNullableDate(data['respondedAt']),
      respondedBy: data['respondedBy'] as String?,
      resolvedAt: parseNullableDate(data['resolvedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        if (orderId != null && orderId!.isNotEmpty) 'orderId': orderId,
        if (vendorId != null && vendorId!.isNotEmpty) 'vendorId': vendorId,
        'vendorName': vendorName,
        'subject': subject,
        'category': category,
        'description': description,
        'status': status.name,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (response != null) 'response': response,
        if (respondedAt != null) 'respondedAt': respondedAt,
        if (respondedBy != null) 'respondedBy': respondedBy,
        if (resolvedAt != null) 'resolvedAt': resolvedAt,
      };

  ReclamationModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? orderId,
    String? vendorId,
    String? vendorName,
    String? subject,
    String? category,
    String? description,
    ReclamationStatus? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? response,
    DateTime? respondedAt,
    String? respondedBy,
    DateTime? resolvedAt,
  }) {
    return ReclamationModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      orderId: orderId ?? this.orderId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
