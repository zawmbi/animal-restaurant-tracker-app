import 'package:flutter/material.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/widgets/check_all_button.dart';
import '../data/aromatic_acorn_data.dart';
import '../data/aromatic_acorn_progress.dart';
import '../model/aromatic_acorn_stage.dart';
import 'aromatic_acorn_stage_detail_page.dart';

class AromaticAcornPage extends StatefulWidget {
  const AromaticAcornPage({super.key});

  @override
  State<AromaticAcornPage> createState() => _AromaticAcornPageState();
}

class _AromaticAcornPageState extends State<AromaticAcornPage> {
  final progress = AromaticAcornProgress.instance;

  @override
  void initState() {
    super.initState();
    // Make sure previously saved checks are loaded before the first read.
    progress.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<String> _idsForStage(AromaticAcornStage stage) => progress.idsForStage(
        stageId: stage.id,
        reqCount: stage.requirements.length,
        taskCount: stage.tasks.length,
      );

  @override
  Widget build(BuildContext context) {
    final stages = AromaticAcornData.stages;

    final allIds = <String>[];
    for (final s in stages) {
      allIds.addAll(progress.idsForStage(
        stageId: s.id,
        reqCount: s.requirements.length,
        taskCount: s.tasks.length,
      ));
    }

    var checkedOverall = 0;
    for (final s in stages) {
      checkedOverall += progress.stageCheckedCount(
        stageId: s.id,
        reqCount: s.requirements.length,
        taskCount: s.tasks.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aromatic Acorn Judging'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Checked: $checkedOverall/${allIds.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                CheckAllButton(
                  bucket: ProgressTypes.acorn,
                  ids: allIds,
                  groupLabel: 'Aromatic Acorn Judging',
                  onApplied: (_) {
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
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
                      if (!mounted) return;
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
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
                          CheckAllButton(
                            bucket: ProgressTypes.acorn,
                            ids: _idsForStage(s),
                            groupLabel: s.title,
                            onApplied: (_) {
                              if (mounted) setState(() {});
                            },
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
