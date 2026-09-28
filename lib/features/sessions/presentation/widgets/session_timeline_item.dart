import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/design_system/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/class_session.dart';

class SessionTimelineItem extends StatelessWidget {
  final ClassSession session;
  final bool isFirst;
  final bool isLast;
  final bool isToday;
  final bool isArchived;
  final VoidCallback onTap;
  final void Function(SessionStatus status)? onStatusSelected;

  const SessionTimelineItem({
    super.key,
    required this.session,
    required this.isFirst,
    required this.isLast,
    required this.isToday,
    required this.isArchived,
    required this.onTap,
    this.onStatusSelected,
  });

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.DA_HOC:
        return AppColors.success;
      case SessionStatus.DU_KIEN:
        return AppColors.primary;
      case SessionStatus.HUY:
        return AppColors.error;
      case SessionStatus.NGHI_LE:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.DA_HOC:
        return Icons.check_circle_rounded;
      case SessionStatus.DU_KIEN:
        return Icons.schedule_rounded;
      case SessionStatus.HUY:
        return Icons.cancel_outlined;
      case SessionStatus.NGHI_LE:
        return Icons.event_busy_outlined;
    }
  }

  String _getStatusLabel(SessionStatus status, AppLocalizations l10n) {
    switch (status) {
      case SessionStatus.DA_HOC:
        return l10n.sessionStatusCompleted;
      case SessionStatus.DU_KIEN:
        return l10n.sessionStatusUpcoming;
      case SessionStatus.HUY:
        return l10n.sessionStatusCanceled;
      case SessionStatus.NGHI_LE:
        return l10n.sessionStatusHoliday;
    }
  }

  IconData _getTypeIcon(SessionType type) {
    switch (type) {
      case SessionType.CHINH:
        return Icons.school_outlined;
      case SessionType.HOC_BU:
        return Icons.event_repeat_rounded;
      case SessionType.PHAT_SINH:
        return Icons.add_circle_outline_rounded;
    }
  }

  String _getTypeLabel(SessionType type, AppLocalizations l10n) {
    switch (type) {
      case SessionType.CHINH:
        return l10n.sessionTypeMain;
      case SessionType.HOC_BU:
        return l10n.sessionTypeMakeup;
      case SessionType.PHAT_SINH:
        return l10n.sessionTypeExtra;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(session.ngay);
    final weekday = DateFormatter.formatVietnameseWeekday(date.weekday);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    final statusColor = _getStatusColor(session.trangThai);
    final isInactive =
        session.trangThai == SessionStatus.HUY ||
        session.trangThai == SessionStatus.NGHI_LE;

    final canChangeStatus =
        session.trangThai != SessionStatus.DA_HOC &&
        !isArchived &&
        onStatusSelected != null;

    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Rail
            SizedBox(
              width: 30,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Vertical connecting line
                  Positioned(
                    top: isFirst ? 14 : 0,
                    bottom: isLast ? 14 : 0,
                    child: Container(width: 2, color: AppColors.border),
                  ),
                  // Node indicator
                  Positioned(
                    top: 14,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: Opacity(
                  opacity: isInactive ? 0.75 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$weekday, $formattedDate',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: isInactive
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.cyanAccent
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.sessionToday,
                                        style: const TextStyle(
                                          color: AppColors.cyanAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Time, Type & Status Wrap
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${session.gioBatDau} – ${session.gioKetThuc}',
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  // Type badge
                                  Tooltip(
                                    message: _getTypeLabel(session.loai, l10n),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getTypeIcon(session.loai),
                                          size: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _getTypeLabel(session.loai, l10n),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(session.trangThai),
                                          size: 11,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _getStatusLabel(
                                            session.trangThai,
                                            l10n,
                                          ),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Ghi chú if non-empty
                              if (session.ghiChu != null &&
                                  session.ghiChu!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  session.ghiChu!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Status Change Popup Menu (only for non-DA_HOC and non-archived)
                        if (canChangeStatus)
                          PopupMenuButton<SessionStatus>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: onStatusSelected,
                            itemBuilder: (context) => [
                              if (session.trangThai != SessionStatus.DU_KIEN)
                                PopupMenuItem(
                                  value: SessionStatus.DU_KIEN,
                                  child: Text(l10n.sessionMarkUpcoming),
                                ),
                              if (session.trangThai != SessionStatus.HUY)
                                PopupMenuItem(
                                  value: SessionStatus.HUY,
                                  child: Text(l10n.sessionMarkCanceled),
                                ),
                              if (session.trangThai != SessionStatus.NGHI_LE)
                                PopupMenuItem(
                                  value: SessionStatus.NGHI_LE,
                                  child: Text(l10n.sessionMarkHoliday),
                                ),
                            ],
                          ),
                      ],
                    ),
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
