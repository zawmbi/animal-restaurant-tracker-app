import 'package:flutter/material.dart';
import '../data/aromatic_acorn_progress.dart';
import '../model/aromatic_acorn_stage.dart';

class AromaticAcornStageDetailPage extends StatefulWidget {
  final AromaticAcornStage stage;
  const AromaticAcornStageDetailPage({super.key, required this.stage});

  @override
  State<AromaticAcornStageDetailPage> createState() =>
      _AromaticAcornStageDetailPageState();
}

class _AromaticAcornStageDetailPageState extends State<AromaticAcornStageDetailPage> {
  final progress = AromaticAcornProgress.instance;

  AromaticAcornStage get s => widget.stage;

  bool get _complete => progress.stageComplete(
        stageId: s.id,
        reqCount: s.requirements.length,
        taskCount: s.tasks.length,
      );

  Future<void> _toggleAll(bool value) async {
    await progress.setAllForStage(
      stageId: s.id,
      reqCount: s.requirements.length,
      taskCount: s.tasks.length,
      value: value,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = s.requirements.length + s.tasks.length;
    final checked = progress.stageCheckedCount(
      stageId: s.id,
      reqCount: s.requirements.length,
      taskCount: s.tasks.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          IconButton(
            tooltip: _complete ? 'Uncheck all' : 'Check all',
            icon: Icon(_complete ? Icons.indeterminate_check_box : Icons.check_box),
            onPressed: () => _toggleAll(!_complete),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggleAll(!_complete),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(_complete ? Icons.check_circle : Icons.circle_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _complete ? 'Stage complete' : 'Stage in progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('$checked / $total checked'),
                          const SizedBox(height: 4),
                          Text(
                            'Tap here (or the top-right button) to ${_complete ? "uncheck" : "check"} everything.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          _SectionCard(
            title: 'Requirements',
            icon: Icons.rule,
            child: Column(
              children: [
                for (int i = 0; i < s.requirements.length; i++)
                  _ChecklistTile(
                    text: s.requirements[i],
                    value: progress.isReqChecked(s.id, i),
                    onChanged: (v) async {
                      await progress.setReqChecked(s.id, i, v);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _SectionCard(
            title: 'Tasks',
            icon: Icons.checklist,
            child: Column(
              children: [
                for (int i = 0; i < s.tasks.length; i++)
                  _ChecklistTile(
                    text: s.tasks[i],
                    value: progress.isTaskChecked(s.id, i),
                    onChanged: (v) async {
                      await progress.setTaskChecked(s.id, i, v);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _SectionCard(
            title: 'Rewards',
            icon: Icons.card_giftcard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in s.rewards)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(text),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
