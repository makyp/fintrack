import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../data/datasources/reports_datasource.dart';
import '../../domain/models/report_data.dart';

part 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsDataSource _ds;

  ReportsCubit(this._ds) : super(const ReportsState.initial());

  Future<void> load(String userId,
      {int? month,
      int? year,
      ReportMode? mode,
      String? householdId}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final resolvedMode = mode ?? state.mode;
    final resolvedHouseholdId = householdId ?? state.householdId;

    emit(ReportsState.loading(m, y,
        mode: resolvedMode, householdId: resolvedHouseholdId));
    try {
      final ReportData data;
      if (resolvedMode == ReportMode.household &&
          resolvedHouseholdId != null) {
        data = await _ds.loadHouseholdReport(resolvedHouseholdId, y, m);
      } else {
        data = await _ds.loadReport(userId, y, m);
      }
      emit(ReportsState.loaded(data,
          mode: resolvedMode, householdId: resolvedHouseholdId));
      AnalyticsService.logReportViewed(resolvedMode.name);
    } catch (e) {
      emit(ReportsState.error(m, y, e.toString(),
          mode: resolvedMode, householdId: resolvedHouseholdId));
    }
  }

  Future<void> switchMode(
      String userId, ReportMode newMode, String? householdId) async {
    await load(userId,
        month: state.month == 0 ? null : state.month,
        year: state.year == 0 ? null : state.year,
        mode: newMode,
        householdId: householdId);
  }
}
