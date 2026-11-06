import 'package:flutter/material.dart';

/// إسناد مصدر الخريطة، ظاهر دائماً ولا يُخفى خلف زر كما تشترط سياسات المصادر.
///
/// يوضع في الزاوية اليمنى السفلية: أزرار الإجراءات في RTL على اليسار،
/// فلا يغطي الإسناد أي زر ولا يغطيه. نرفعه فوق شريط التنقل بالنظام يدوياً
/// بدل `SafeArea` لأن `Positioned` مع `SafeArea` قد يُقصّ عند حافة الشاشة.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // 64 = ارتفاع شريط التنقل/الإيماءات في أسوأ الحالات، مع هامش.
    // بعض الأجهزة تمدّ التطبيق تحت الشريط ولا تُبلّغ عنه في MediaQuery،
    // لذلك نستخدم قيمة ثابتة مضمونة بدل الاعتماد على الإطار فقط.
    return Positioned(
      right: 6,
      bottom: 64,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
