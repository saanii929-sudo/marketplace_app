/// The caller's own seller application, from `GET /sellers/apply/status/`.
class SellerApplicationStatus {
  const SellerApplicationStatus({
    required this.id,
    required this.businessName,
    required this.categoryName,
    required this.phone,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewerNote,
  });

  final int id;
  final String businessName;
  final String categoryName;
  final String phone;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String reviewerNote;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory SellerApplicationStatus.fromJson(Map<String, dynamic> json) => SellerApplicationStatus(
    id: json['id'] as int? ?? 0,
    businessName: json['business_name'] as String? ?? '',
    categoryName: json['category_name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? ''),
    reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    reviewerNote: json['reviewer_note'] as String? ?? '',
  );
}
