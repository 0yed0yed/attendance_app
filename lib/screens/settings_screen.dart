import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();

  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _overtimeController = TextEditingController();
  final TextEditingController _workDaysController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _overtimeController.dispose();
    _workDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final salary = await _storage.getMonthlySalary();
    final overtime = await _storage.getOvertimeRate();
    final workDays = await _storage.getWorkDays();
    setState(() {
      _salaryController.text = salary.toStringAsFixed(0);
      _overtimeController.text = overtime.toStringAsFixed(0);
      _workDaysController.text = workDays.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final salary = double.tryParse(_salaryController.text);
    final overtime = double.tryParse(_overtimeController.text);
    final workDays = int.tryParse(_workDaysController.text);

    if (salary == null || overtime == null || workDays == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تأكد من إدخال أرقام صحيحة')),
      );
      return;
    }

    if (workDays < 1 || workDays > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أيام العمل يجب أن تكون بين 1 و31')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await _storage.setMonthlySalary(salary);
    await _storage.setOvertimeRate(overtime);
    await _storage.setWorkDays(workDays);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات بنجاح ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات الراتب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _salaryController,
                      label: 'الراتب الشهري',
                      hint: 'مثال: 3000',
                      icon: Icons.attach_money,
                      suffix: 'جنيه',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _overtimeController,
                      label: 'سعر ساعة الإضافي',
                      hint: 'مثال: 25',
                      icon: Icons.access_time,
                      suffix: 'جنيه/ساعة',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _workDaysController,
                      label: 'عدد أيام العمل في الشهر',
                      hint: 'مثال: 26',
                      icon: Icons.calendar_month,
                      suffix: 'يوم',
                      isInteger: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
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
                        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'الإشعارات مجدولة يومياً الساعة 8 صباحاً و9 مساءً تلقائياً',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String suffix,
    bool isInteger = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isInteger
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.indigo),
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }
}