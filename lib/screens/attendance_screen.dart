import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/storage_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StorageService _storage = StorageService();

  DateTime _selectedDate = DateTime.now();
  AttendanceRecord? _currentRecord;
  String _selectedStatus = 'present';
  double _overtimeHours = 0.0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadRecord() async {
    setState(() => _isLoading = true);
    final record = await _storage.getRecordForDate(_formattedDate);
    setState(() {
      _currentRecord = record;
      if (record != null) {
        _selectedStatus = record.status;
        _overtimeHours = record.overtimeHours;
      } else {
        _selectedStatus = 'present';
        _overtimeHours = 0.0;
      }
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadRecord();
    }
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    final record = AttendanceRecord(
      date: _formattedDate,
      status: _selectedStatus,
      overtimeHours: _selectedStatus == 'present' ? _overtimeHours : 0.0,
    );
    await _storage.saveRecord(record);
    setState(() {
      _currentRecord = record;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ بنجاح ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اختيار التاريخ
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE، d MMMM yyyy', 'ar')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                color: Colors.indigo),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // حالة الحضور
                    const Text(
                      'حالة اليوم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusButton(
                            label: 'حاضر',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            isSelected: _selectedStatus == 'present',
                            onTap: () =>
                                setState(() => _selectedStatus = 'present'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatusButton(
                            label: 'غايب',
                            icon: Icons.cancel,
                            color: Colors.red,
                            isSelected: _selectedStatus == 'absent',
                            onTap: () =>
                                setState(() => _selectedStatus = 'absent'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatusButton(
                            label: 'راحة',
                            icon: Icons.weekend,
                            color: Colors.orange,
                            isSelected: _selectedStatus == 'rest',
                            onTap: () =>
                                setState(() => _selectedStatus = 'rest'),
                          ),
                        ),
                      ],
                    ),

                    // ساعات الإضافي (فقط لو حاضر)
                    if (_selectedStatus == 'present') ...[
                      const SizedBox(height: 24),
                      const Text(
                        'ساعات الإضافي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_overtimeHours.toStringAsFixed(1)} ساعة',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // زر طرح 0.5
                                _OvertimeButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_overtimeHours >= 0.5) {
                                      setState(
                                          () => _overtimeHours -= 0.5);
                                    }
                                  },
                                ),
                                const SizedBox(width: 10),
                                // زر طرح 0.25
                                TextButton(
                                  onPressed: () {
                                    if (_overtimeHours >= 0.25) {
                                      setState(
                                          () => _overtimeHours -= 0.25);
                                    }
                                  },
                                  child: const Text('-¼'),
                                ),
                                const SizedBox(width: 20),
                                // زر إضافة 0.25
                                TextButton(
                                  onPressed: () {
                                    setState(() => _overtimeHours += 0.25);
                                  },
                                  child: const Text('+¼'),
                                ),
                                const SizedBox(width: 10),
                                // زر إضافة 0.5
                                _OvertimeButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    setState(() => _overtimeHours += 0.5);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // إدخال يدوي
                            SizedBox(
                              width: 120,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  labelText: 'أدخل يدوياً',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed != null && parsed >= 0) {
                                    setState(() => _overtimeHours = parsed);
                                  }
                                },
                                controller: TextEditingController(
                                  text: _overtimeHours > 0
                                      ? _overtimeHours.toStringAsFixed(2)
                                      : '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRecord,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label:
                            Text(_isSaving ? 'جاري الحفظ...' : 'حفظ السجل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // عرض الحالة المحفوظة
                    if (_currentRecord != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                            const SizedBox(width: 10),
                            Text(
                              'محفوظ: ${_statusLabel(_currentRecord!.status)} - ${_currentRecord!.overtimeHours} ساعة إضافي',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غايب';
      case 'rest':
        return 'راحة';
      default:
        return status;
    }
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OvertimeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OvertimeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}