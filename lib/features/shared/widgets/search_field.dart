// lib/features/shared/widgets/search_field.dart

import 'package:flutter/material.dart';

/// The app's one search box.
///
/// Pages had grown three slightly different search fields (different borders,
/// some with a clear button and some without) and most list pages had none at
/// all. This is the shared one so every page searches the same way and looks
/// the same doing it.
///
/// Filtering is caller-side: pass [onChanged] and filter your own list. The
/// clear button empties the field and reports an empty query, so callers never
/// need to special-case it.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 8),
  });

  /// What this page searches, e.g. 'Search customers…'.
  final String hintText;

  final ValueChanged<String> onChanged;

  final EdgeInsets padding;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handle(String value) {
    // Rebuild so the clear button appears/disappears with the text.
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _handle('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _handle,
      ),
    );
  }
}

/// Case-insensitive "every word in the query appears somewhere in [haystack]".
///
/// Word-wise rather than substring so "white bun" finds "White Bunny" and
/// "bunny white" finds it too. Callers join whatever fields should be
/// searchable into [haystack].
bool matchesQuery(String query, String haystack) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final h = haystack.toLowerCase();
  for (final word in q.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    if (!h.contains(word)) return false;
  }
  return true;
}
