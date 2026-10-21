import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  static Future<String> sendMessage(String message) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        systemInstruction: Content.system('''
أنت المساعد الصحي الذكي في تطبيق Rivo.
أجب باللغة العربية بطريقة واضحة ومختصرة.
قدم معلومات صحية عامة فقط.
لا تقدم تشخيصًا طبيًا مؤكدًا أو تصف أدوية بجرعات محددة.
عند وجود أعراض خطيرة، وجّه المستخدم لطلب الرعاية الطبية العاجلة.
شجّع المستخدم على استشارة الطبيب عند الحاجة.
'''),
      );

      final response = await model.generateContent([
        Content.text(message),
      ]);

      return response.text ?? 'لم أتمكن من إنشاء إجابة.';
    } catch (e) {
  debugPrint('Gemini Error: $e');
  return 'تعذر الاتصال بالمساعد الصحي. حاولي مرة أخرى.';
}
  }
}