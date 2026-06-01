import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String memberId;
  final String name;
  final String email;
  final String phone;
  final String gymId;
  final String planType;
  final double planFee;
  final DateTime joinDate;
  final DateTime paymentCycleDate;
  final bool isActive;
  final int totalAttendance;
  final int currentStreak;
  final int totalPoints;
  final DateTime? lastVisit;
  final String photoUrl;

  MemberModel({
    required this.id,
    required this.memberId,
    required this.name,
    required this.email,
    this.phone = '',
    required this.gymId,
    required this.planType,
    this.planFee = 0.0,
    required this.joinDate,
    required this.paymentCycleDate,
    this.isActive = true,
    this.totalAttendance = 0,
    this.currentStreak = 0,
    this.totalPoints = 0,
    this.lastVisit,
    this.photoUrl = '',
  });

  factory MemberModel.fromMap(Map<String, dynamic> map, String docId) {
    return MemberModel(
      id: docId,
      memberId: map['memberId'] ?? docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gymId: map['gymId'] ?? '',
      planType: map['planType'] ?? 'Monthly',
      planFee: (map['planFee'] as num?)?.toDouble() ?? 0.0,
      joinDate: (map['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentCycleDate: (map['paymentCycleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      totalAttendance: map['totalAttendance'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      lastVisit: (map['lastVisit'] as Timestamp?)?.toDate(),
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'name': name,
      'email': email,
      'phone': phone,
      'gymId': gymId,
      'planType': planType,
      'planFee': planFee,
      'joinDate': Timestamp.fromDate(joinDate),
      'paymentCycleDate': Timestamp.fromDate(paymentCycleDate),
      'isActive': isActive,
      'totalAttendance': totalAttendance,
      'currentStreak': currentStreak,
      'totalPoints': totalPoints,
      'photoUrl': photoUrl,
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  MemberModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? planType,
    double? planFee,
    DateTime? paymentCycleDate,
    bool? isActive,
    int? totalAttendance,
    int? currentStreak,
    int? totalPoints,
    DateTime? lastVisit,
  }) {
    return MemberModel(
      id: id,
      memberId: memberId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gymId: gymId,
      planType: planType ?? this.planType,
      planFee: planFee ?? this.planFee,
      joinDate: joinDate,
      paymentCycleDate: paymentCycleDate ?? this.paymentCycleDate,
      isActive: isActive ?? this.isActive,
      totalAttendance: totalAttendance ?? this.totalAttendance,
      currentStreak: currentStreak ?? this.currentStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }

  int get daysUntilRenewal =>
      paymentCycleDate.difference(DateTime.now()).inDays;

  bool get isRenewalSoon =>
      daysUntilRenewal <= 7 && daysUntilRenewal >= 0;

  bool get isInactive {
    if (lastVisit == null) return totalAttendance > 0;
    return DateTime.now().difference(lastVisit!).inDays >= 10;
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get feeLabel {
    if (planFee <= 0) return 'Not set';
    final f = planFee % 1 == 0
        ? '₹${planFee.toInt()}'
        : '₹${planFee.toStringAsFixed(0)}';
    switch (planType) {
      case 'Quarterly':
        return '$f / quarter';
      case 'Annual':
        return '$f / year';
      default:
        return '$f / month';
    }
  }
}