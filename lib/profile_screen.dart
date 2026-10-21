import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'reminder_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final healthController = TextEditingController();
  String? selectedAllergy;
  final otherAllergyController = TextEditingController();
  @override
void initState() {
  super.initState();
  loadProfile();
}

Future<void> loadProfile() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;

    setState(() {
      nameController.text = data['name'] ?? '';
      ageController.text = data['age'] ?? '';
      heightController.text = data['height'] ?? '';
      weightController.text = data['weight'] ?? '';
      healthController.text = data['healthCondition'] ?? '';

      final savedAllergy = data['allergy'] ?? '';

      const allergyOptions = [
        'لا توجد حساسية',
        'حساسية الأدوية',
        'حساسية الطعام',
        'حساسية الغبار',
        'حساسية حبوب اللقاح',
        'حساسية الحيوانات',
        'حساسية أخرى',
      ];

      if (allergyOptions.contains(savedAllergy)) {
        selectedAllergy = savedAllergy;
      } else if (savedAllergy.isNotEmpty) {
        selectedAllergy = 'حساسية أخرى';
        otherAllergyController.text = savedAllergy;
      }
    });
  } catch (e) {
    debugPrint('خطأ في تحميل الملف الشخصي: $e');
  }
}
  Future<void> saveProfile() async {
  try {
    await FirebaseFirestore.instance
        .collection('profiles')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'name': nameController.text.trim(),
      'age': ageController.text.trim(),
      'height': heightController.text.trim(),
      'weight': weightController.text.trim(),
      'healthCondition': healthController.text.trim(),
      'allergy': selectedAllergy == 'حساسية أخرى'
    ? otherAllergyController.text.trim()
    : (selectedAllergy ?? 'لا توجد حساسية'),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ البيانات بنجاح ✅'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فشل حفظ البيانات: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
  title: const Text('الملف الشخصي'),
  centerTitle: true,
  backgroundColor: const Color(0xFF4CAF50),
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'تسجيل الخروج',
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

if (!context.mounted) return;

Navigator.of(context).pushNamedAndRemoveUntil(
  '/',
  (route) => false,
);
      },
    ),
  ],
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF4CAF50),
                child: Icon(
                  Icons.person,
                  size: 55,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              buildField(
                controller: nameController,
                label: 'الاسم',
                icon: Icons.person_outline,
              ),

              buildField(
                controller: ageController,
                label: 'العمر',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),

              buildField(
                controller: heightController,
                label: 'الطول (سم)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),

              buildField(
                controller: weightController,
                label: 'الوزن (كجم)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),

              buildField(
                controller: healthController,
                label: 'الحالة الصحية',
                icon: Icons.health_and_safety_outlined,
              ),

              Padding(
  padding: const EdgeInsets.only(bottom: 15),
  child: DropdownButtonFormField<String>(
    initialValue: selectedAllergy,
    decoration: InputDecoration(
      labelText: 'الحساسية',
      prefixIcon: const Icon(Icons.warning_amber_outlined),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
    items: [
      'لا توجد حساسية',
      'حساسية الأدوية',
      'حساسية الطعام',
      'حساسية الغبار',
      'حساسية حبوب اللقاح',
      'حساسية الحيوانات',
      'حساسية أخرى',
    ].map((allergy) {
      return DropdownMenuItem<String>(
        value: allergy,
        child: Text(allergy),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        selectedAllergy = value;
      });
    },
  ),
),
if (selectedAllergy == 'حساسية أخرى')
  buildField(
    controller: otherAllergyController,
    label: 'اكتبي نوع الحساسية',
    icon: Icons.edit_outlined,
  ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'حفظ البيانات',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text(
                    'المساعد الصحي الذكي',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReminderScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text(
                    'إعدادات التذكيرات',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}