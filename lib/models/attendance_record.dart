class AttendanceRecord {
  final String date; // yyyy-MM-dd
  final String status; // 'present', 'absent', 'rest'
  final double overtimeHours;

  AttendanceRecord({
    required this.date,
    required this.status,
    required this.overtimeHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
      'overtimeHours': overtimeHours,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      date: map['date'] as String,
      status: map['status'] as String,
      overtimeHours: (map['overtimeHours'] as num).toDouble(),
    );
  }
}