import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/reports_datasource.dart';
import '../../domain/models/report_data.dart';

part 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsDataSource _ds;

  ReportsCubit(this._ds) : super(const ReportsState.initial());

  Future<void> load(String userId, {int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    emit(ReportsState.loading(m, y));
    try {
      final data = await _ds.loadReport(userId, y, m);
      emit(ReportsState.loaded(data));
    } catch (e) {
      emit(ReportsState.error(m, y, e.toString()));
    }
  }
}
