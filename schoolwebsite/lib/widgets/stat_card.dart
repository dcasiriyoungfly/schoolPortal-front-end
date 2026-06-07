import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.primaryLight;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.label),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.caption),
          ],
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isPositive;

  const StatusBadge({super.key, required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? AppTheme.successBg : AppTheme.errorBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPositive ? AppTheme.success : AppTheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GradeBadge extends StatelessWidget {
  final String grade;

  const GradeBadge({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.gradeBg(grade),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: AppTheme.gradeColor(grade),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.heading2),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTheme.caption),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Reusable table widget with header + rows.
class AppTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<double?>? columnWidths; // null entry = flex, double = fixed width

  const AppTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Min width: 80px per column so tables scroll horizontally on mobile
        final minWidth = headers.length * 80.0;
        if (constraints.maxWidth < minWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: _buildTable(),
            ),
          );
        }
        return _buildTable();
      },
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: headers.asMap().entries.map((e) {
                final w = columnWidths != null && e.key < columnWidths!.length
                    ? columnWidths![e.key]
                    : null;
                final child = Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                );
                return w != null
                    ? SizedBox(width: w, child: child)
                    : Expanded(child: child);
              }).toList(),
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: entry.key.isEven ? AppTheme.surface : const Color(0xFFFAFAFA),
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(8))
                    : null,
                border: !isLast
                    ? const Border(
                        bottom: BorderSide(color: AppTheme.border))
                    : null,
              ),
              child: Row(
                children: entry.value.asMap().entries.map((e) {
                  final w =
                      columnWidths != null && e.key < columnWidths!.length
                          ? columnWidths![e.key]
                          : null;
                  return w != null
                      ? SizedBox(width: w, child: e.value)
                      : Expanded(child: e.value);
                }).toList(),
              ),
            );
          }),
          if (rows.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Text(
                  'No data available.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
