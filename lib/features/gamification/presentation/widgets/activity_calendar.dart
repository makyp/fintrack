import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../cubit/gamification_cubit.dart';

class ActivityCalendar extends StatefulWidget {
  final String userId;
  const ActivityCalendar({super.key, required this.userId});

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  late DateTime _month;

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    context.read<GamificationCubit>().changeMonth(
        widget.userId, _month.year, _month.month);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationCubit, GamificationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('Actividad del mes', style: AppTextStyles.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => _changeMonth(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: DateTime(_month.year, _month.month + 1)
                          .isAfter(DateTime.now())
                      ? null
                      : () => _changeMonth(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            _buildCalendarGrid(state.activityDays),
          ],
        );
      },
    );
  }

  Widget _buildCalendarGrid(Set<DateTime> activeDays) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    // Monday=1, so offset: Monday=0, ..., Sunday=6
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        // Weekday headers
        Row(
          children: _weekdays.map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey400, fontWeight: FontWeight.w600),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),
        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date = DateTime(_month.year, _month.month, day);
            final isActive = activeDays.contains(date);
            final isToday = date == todayNorm;
            final isFuture = date.isAfter(todayNorm);

            return _DayCell(
              day: day,
              isActive: isActive,
              isToday: isToday,
              isFuture: isFuture,
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isActive;
  final bool isToday;
  final bool isFuture;

  const _DayCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.grey700;

    if (isFuture) {
      textColor = AppColors.grey300;
    } else if (isActive) {
      bgColor = AppColors.primary;
      textColor = AppColors.white;
    } else if (isToday) {
      bgColor = AppColors.grey100;
      textColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && !isActive
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: isToday || isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
