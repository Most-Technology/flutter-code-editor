import 'dart:math';

import '../../single_line_comments/single_line_comment.dart';
import '../named_section.dart';
import 'abstract.dart';

/// Parses named sections from tags like [START name]...[END name].
///
/// Section name may only contain english letters, numbers, and underscores.
/// Section name must not be empty.
/// Whitespaces are allowed before START/END, before name, and after name.
///
/// Sections can overlap and can be nested.
///
/// A section can start and end on the same line in a single comment or in two
/// different comments.
///
/// If a section is never started, it starts at the line 0.
/// If a section is never ended, it ends at the last line (count - 1).
///
/// If a section is started multiple times, the min line number takes effect.
/// If a section is ended multiple times, the max line number takes effect.
///
/// The order of comments in the list does not matter.
class BracketsStartEndNamedSectionParser extends AbstractNamedSectionParser {
  static final _startRe = RegExp(r'\[(\s*)START(\s+)([_0-9a-zA-Z]+)(\s*)\]');
  static final _endRe = RegExp(r'\[(\s*)END(\s+)([_0-9a-zA-Z]+)(\s*)\]');

  @override
  List<NamedSection> parseUnsorted({
    required List<SingleLineComment> singleLineComments,
    required int lineCount,
  }) {
    final starts = <String, int>{};
    final ends = <String, int>{};

    for (final comment in singleLineComments) {
      for (final match in _startRe.allMatches(comment.innerContent)) {
        final name = match.group(3) ?? '';
        starts[name] = min(comment.lineIndex, starts[name] ?? lineCount - 1);
      }

      for (final match in _endRe.allMatches(comment.innerContent)) {
        final name = match.group(3) ?? '';
        ends[name] = max(comment.lineIndex, ends[name] ?? 0);
      }
    }

    return _combineStartsAndEnds(starts, ends, lineCount);
  }

  List<NamedSection> _combineStartsAndEnds(
    Map<String, int> starts,
    Map<String, int> ends,
    int lineCount,
  ) {
    final sections = <NamedSection>[];

    for (final entry in ends.entries) {
      final name = entry.key;
      final end = entry.value;

      sections.add(
        NamedSection(
          startLine: starts[name] ?? 0,
          endLine: end,
          name: name,
        ),
      );

      starts.remove(name);
    }

    for (final entry in starts.entries) {
      final name = entry.key;
      final start = entry.value;

      sections.add(
        NamedSection(
          startLine: start,
          endLine: ends[name] ?? lineCount - 1,
          name: name,
        ),
      );
    }

    return sections;
  }
}
