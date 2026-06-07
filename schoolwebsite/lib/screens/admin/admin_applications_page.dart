import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  // 0 = All, 1 = Pending, 2 = Reviewed
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final all = state.applications;

    final filtered = switch (_filterIndex) {
      1 => all.where((a) => !a.isReviewed).toList(),
      2 => all.where((a) => a.isReviewed).toList(),
      _ => all.toList(),
    };

    final isMobile = MediaQuery.of(context).size.width < 600;
    final pending = all.where((a) => !a.isReviewed).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admissions Applications', style: AppTheme.heading1),
                    const SizedBox(height: 4),
                    Text(
                      '${all.length} total · $pending pending review',
                      style: AppTheme.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Filter tabs ─────────────────────────────────────────────────────
          Row(
            children: [
              _FilterTab('All', 0, all.length, _filterIndex,
                  (i) => setState(() => _filterIndex = i)),
              const SizedBox(width: 8),
              _FilterTab('Pending', 1,
                  all.where((a) => !a.isReviewed).length,
                  _filterIndex,
                  (i) => setState(() => _filterIndex = i)),
              const SizedBox(width: 8),
              _FilterTab('Reviewed', 2,
                  all.where((a) => a.isReviewed).length,
                  _filterIndex,
                  (i) => setState(() => _filterIndex = i)),
            ],
          ),
          const SizedBox(height: 20),

          // ── List ───────────────────────────────────────────────────────────
          if (filtered.isEmpty)
            _EmptyState(_filterIndex)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _ApplicationCard(
                application: filtered[i],
                onReview: () =>
                    state.markApplicationReviewed(filtered[i].id),
                onDelete: () => _confirmDelete(ctx, state, filtered[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, dynamic state, StudentApplication app) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Application'),
        content: Text(
            'Remove the application from ${app.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.deleteApplication(app.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
  }
}

// ── Filter Tab ──────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final int index;
  final int count;
  final int selected;
  final ValueChanged<int> onTap;

  const _FilterTab(
      this.label, this.index, this.count, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          border: Border.all(
              color: active
                  ? AppTheme.primary
                  : AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Application Card ─────────────────────────────────────────────────────────

class _ApplicationCard extends StatefulWidget {
  final StudentApplication application;
  final VoidCallback onReview;
  final VoidCallback onDelete;

  const _ApplicationCard({
    required this.application,
    required this.onReview,
    required this.onDelete,
  });

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  bool _expanded = false;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final reviewed = app.isReviewed;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: reviewed ? AppTheme.border : const Color(0xFF2563EB).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row (always visible) ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      app.fullName.isNotEmpty
                          ? app.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${app.formApplyingFor}  ·  ${_formatDate(app.submittedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: reviewed
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reviewed ? 'Reviewed' : 'Pending',
                    style: TextStyle(
                        color: reviewed ? AppTheme.success : AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded details ────────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact row
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      _DetailItem(Icons.email_outlined, 'Email', app.email),
                      _DetailItem(Icons.phone_outlined, 'Phone', app.phone),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailItem(Icons.school_outlined, 'Previous School', app.previousSchool),
                  const SizedBox(height: 14),
                  // Reason
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reason for Leaving',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(app.reasonForLeaving, style: AppTheme.body),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Results file
                  Row(
                    children: [
                      Icon(
                        app.resultsFileName != null
                            ? Icons.attach_file_rounded
                            : Icons.file_present_outlined,
                        size: 16,
                        color: app.resultsFileName != null
                            ? AppTheme.primaryLight
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        app.resultsFileName != null
                            ? app.resultsFileName!
                            : 'No results file attached',
                        style: TextStyle(
                            fontSize: 13,
                            color: app.resultsFileName != null
                                ? AppTheme.primaryLight
                                : AppTheme.textSecondary,
                            fontStyle: app.resultsFileName == null
                                ? FontStyle.italic
                                : FontStyle.normal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      if (!reviewed)
                        _ActionButton(
                          label: 'Mark as Reviewed',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.success,
                          onTap: widget.onReview,
                        ),
                      if (!reviewed) const SizedBox(width: 10),
                      _ActionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            Text(value, style: AppTheme.body),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int filterIndex;
  const _EmptyState(this.filterIndex);

  @override
  Widget build(BuildContext context) {
    final messages = [
      ('No applications yet', 'Applications submitted on the school website will appear here.'),
      ('No pending applications', 'All applications have been reviewed.'),
      ('No reviewed applications', 'Mark an application as reviewed and it will appear here.'),
    ];
    final (title, subtitle) = messages[filterIndex.clamp(0, 2)];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
