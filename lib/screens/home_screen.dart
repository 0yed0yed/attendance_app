import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../widgets/summary_card.dart';
import 'attendance_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();

  Map<String, dynamic> _salaryData = {};
  bool _isLoading = true;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data =
        await _storage.calculateSalary(_currentYear, _currentMonth);
    setState(() {
      _salaryData = data;
      _isLoading = false;
    });
  }

  String _monthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentYear < now.year ||
        (_currentYear == now.year && _currentMonth < now.month)) {
      setState(() {
        if (_currentMonth == 12) {
          _currentMonth = 1;
          _currentYear++;
        } else {
          _currentMonth++;
        }
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'تطبيق الحضور والراتب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // شريط اختيار الشهر
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.indigo),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        '${_monthName(_currentMonth)} $_currentYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            size: 18, color: Colors.indigo),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ))
                else ...[
                  // بطاقة الراتب المتوقع - الكبيرة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Color(0xFF5C6BC0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'الراتب المتوقع',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_salaryData['expectedSalary'] as double? ?? 0.0).toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MiniStat(
                              label: 'الراتب الأساسي',
                              value:
                                  '${(_salaryData['monthlySalary'] as double? ?? 0.0).toStringAsFixed(0)}',
                              color: Colors.white,
                            ),
                            _MiniStat(
                              label: 'إضافي',
                              value:
                                  '+${(_salaryData['overtimePay'] as double? ?? 0.0).toStringAsFixed(2)}',
                              color: Colors.greenAccent,
                            ),
                            _MiniStat(
                              label: 'خصم',
                              value:
                                  '-${(_salaryData['deduction'] as double? ?? 0.0).toStringAsFixed(2)}',
                              color: Colors.redAccent.shade100,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // بطاقات الملخص
                  SummaryCard(
                    title: 'أيام الحضور',
                    value: '${_salaryData['presentDays'] ?? 0} يوم',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'أيام الغياب',
                    value: '${_salaryData['absentDays'] ?? 0} يوم',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'أيام الراحة',
                    value: '${_salaryData['restDays'] ?? 0} يوم',
                    icon: Icons.weekend_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'إجمالي ساعات الإضافي',
                    value:
                        '${(_salaryData['totalOvertimeHours'] as double? ?? 0.0).toStringAsFixed(1)} ساعة',
                    icon: Icons.access_time,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'مكافأة الإضافي',
                    value:
                        '${(_salaryData['overtimePay'] as double? ?? 0.0).toStringAsFixed(2)} جنيه',
                    icon: Icons.attach_money,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AttendanceScreen()),
          );
          _loadData();
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_calendar),
        label: const Text('تسجيل اليوم'),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}