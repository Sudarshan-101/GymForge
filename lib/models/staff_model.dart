import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String staffId; // Owner-assigned staff ID
  final String name;
  final String email;
  final String phone;
  final String gymId;
  final String role; // Trainer / Receptionist / Manager / Cleaner
  final String shift; // Morning / Evening / Full-Day
  final DateTime joinDate;
  final bool isActive;
  final String? specialization; // e.g., "Strength Training", "Cardio"

  StaffModel({
    required this.id,
    required this.staffId,
    required this.name,
    required this.email,
    this.phone = '',
    required this.gymId,
    required this.role,
    this.shift = 'Full-Day',
    required this.joinDate,
    this.isActive = true,
    this.specialization,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map, String docId) {
    return StaffModel(
      id: docId,
      staffId: map['staffId'] ?? docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gymId: map['gymId'] ?? '',
      role: map['role'] ?? 'Trainer',
      shift: map['shift'] ?? 'Full-Day',
      joinDate: (map['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      specialization: map['specialization'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'name': name,
      'email': email,
      'phone': phone,
      'gymId': gymId,
      'role': role,
      'shift': shift,
      'joinDate': Timestamp.fromDate(joinDate),
      'isActive': isActive,
      'specialization': specialization,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
