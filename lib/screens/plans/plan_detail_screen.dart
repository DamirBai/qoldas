import 'package:flutter/material.dart';
import '../../services/translation_service.dart';

class PlanDetailScreen extends StatelessWidget {
  final Map<String, String> plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t(plan['title']!)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.t(plan['subtitle']!),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if ((plan['description'] ?? '').isNotEmpty)
              Text(
                TranslationService.t(plan['description']!),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const Spacer(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: переход на экран оплаты или подтверждения документов (Асет)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(TranslationService.t('payment_not_implemented')),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '${TranslationService.t('proceed_to_payment')}: ${TranslationService.t(plan['price']!)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
