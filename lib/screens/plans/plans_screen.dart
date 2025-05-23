import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import 'plan_detail_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  final List<Map<String, String>> plans = const [
    {
      'title': 'plan_free_title',
      'subtitle': 'plan_free_subtitle',
      'description': 'plan_free_description',
      'price': 'plan_free_price'
    },
    {
      'title': 'plan_premium_title',
      'subtitle': 'plan_premium_subtitle',
      'description': 'plan_premium_description',
      'price': 'plan_premium_price'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('select_plan')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(TranslationService.t(plan['title']!)),
              subtitle: Text(TranslationService.t(plan['subtitle']!)),
              trailing: Text(
                TranslationService.t(plan['price']!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanDetailScreen(plan: plan),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
