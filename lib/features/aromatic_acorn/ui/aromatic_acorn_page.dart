import 'package:flutter/material.dart';
import '../data/aromatic_acorn_data.dart';
import '../data/aromatic_acorn_progress.dart';
import 'aromatic_acorn_stage_detail_page.dart';

class AromaticAcornPage extends StatefulWidget {
  const AromaticAcornPage({super.key});

  @override
  State<AromaticAcornPage> createState() => _AromaticAcornPageState();
}

class _AromaticAcornPageState extends State<AromaticAcornPage> {
  final progress = AromaticAcornProgress.instance;

  @override
  Widget build(BuildContext context) {
    final stages = AromaticAcornData.stages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aromatic Acorn Judging'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) {
          final s = stages[idx];
          final total = s.requirements.length + s.tasks.length;
          final checked = progress.stageCheckedCount(
            stageId: s.id,
            reqCount: s.requirements.length,
            taskCount: s.tasks.length,
          );
          final complete = progress.stageComplete(
            stageId: s.id,
            reqCount: s.requirements.length,
            taskCount: s.tasks.length,
          );

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AromaticAcornStageDetailPage(stage: s),
                  ),
                );
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      complete ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text('$checked / $total checked'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
