import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameUpdate {
  final String version;
  final String date;
  final List<String> changes;

  GameUpdate({
    required this.version,
    required this.date,
    required this.changes,
  });

  factory GameUpdate.fromJson(Map<String, dynamic> json) {
    return GameUpdate(
      version: json['version'] as String,
      date: json['date'] as String,
      changes: (json['changes'] as List).map((e) => e.toString()).toList(),
    );
  }
}

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  Future<List<GameUpdate>> _load() async {
    final raw =
        await rootBundle.loadString('assets/data/updates.json');
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => GameUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Updates')),
      body: FutureBuilder<List<GameUpdate>>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final updates = snap.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: updates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final u = updates[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.version,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            u.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...u.changes.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('- ', style: TextStyle(height: 1.4)),
                              Expanded(
                                child: Text(c, style: const TextStyle(height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
