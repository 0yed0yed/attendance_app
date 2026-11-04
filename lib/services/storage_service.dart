import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class StorageService {
  static const String _recordsKey = 'attendance_records';
  static const String _monthlySalaryKey = 'monthly_salary';
  static const String _overtimeRateKey = 'overtime_rate';
  static const String _workDaysKey = 'work_days';

  // =====================
  // إعدادات الراتب
  // =====================

  Future<double> getMonthlySalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlySalaryKey) ?? 3000.0;
  }

  Future<void> setMonthlySalary(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlySalaryKey, value);
  }

  Future<double> getOvertimeRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_overtimeRateKey) ?? 25.0;
  }

  Future<void> setOvertimeRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_overtimeRateKey, value);
  }

  Future<int> getWorkDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workDaysKey) ?? 26;
  }

  Future<void> setWorkDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workDaysKey, value);
  }

  // =====================
  // سجلات الحضور
  // =====================

  Future<List<AttendanceRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recordsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AttendanceRecord?> getRecordForDate(String date) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    final index = records.indexWhere((r) => r.date == record.date);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    final encoded = jsonEncode(records.map((r) => r.toMap()).toList());
    await prefs.setString(_recordsKey, encoded);
  }

  Future<List<AttendanceRecord>> getRecordsForMonth(
      int year, int month) async {
    final records = await getAllRecords();
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return records.where((r) => r.date.startsWith(prefix)).toList();
  }

  // =====================
  // حساب الراتب
  // =====================

  Future<Map<String, dynamic>> calculateSalary(int year, int month) async {
    final double monthlySalary = await getMonthlySalary();
    final double overtimeRate = await getOvertimeRate();
    final int workDays = await getWorkDays();

    final records = await getRecordsForMonth(year, month);

    int presentDays = records.where((r) => r.status == 'present').length;
    int absentDays = records.where((r) => r.status == 'absent').length;
    int restDays = records.where((r) => r.status == 'rest').length;
    double totalOvertimeHours =
        records.fold(0.0, (sum, r) => sum + r.overtimeHours);

    double dailyRate = workDays > 0 ? monthlySalary / workDays : 0.0;
    double deduction = absentDays * dailyRate;
    double overtimePay = totalOvertimeHours * overtimeRate;
    double expectedSalary = monthlySalary - deduction + overtimePay;

    return {
      'monthlySalary': monthlySalary,
      'overtimeRate': overtimeRate,
      'workDays': workDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'restDays': restDays,
      'totalOvertimeHours': totalOvertimeHours,
      'overtimePay': overtimePay,
      'deduction': deduction,
      'expectedSalary': expectedSalary,
    };
  }
}