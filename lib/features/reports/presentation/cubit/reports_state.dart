part of 'reports_cubit.dart';

enum ReportsStatus { initial, loading, loaded, error }
enum ReportMode { personal, household }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final ReportData? data;
  final int month;
  final int year;
  final String? errorMessage;
  final ReportMode mode;
  final String? householdId;

  const ReportsState._({
    required this.status,
    required this.month,
    required this.year,
    this.data,
    this.errorMessage,
    this.mode = ReportMode.personal,
    this.householdId,
  });

  const ReportsState.initial()
      : this._(
          status: ReportsStatus.initial,
          month: 0,
          year: 0,
        );

  const ReportsState.loading(int month, int year,
      {ReportMode mode = ReportMode.personal, String? householdId})
      : this._(
            status: ReportsStatus.loading,
            month: month,
            year: year,
            mode: mode,
            householdId: householdId);

  ReportsState.loaded(ReportData data,
      {ReportMode mode = ReportMode.personal, String? householdId})
      : this._(
          status: ReportsStatus.loaded,
          month: data.month,
          year: data.year,
          data: data,
          mode: mode,
          householdId: householdId,
        );

  const ReportsState.error(int month, int year, String msg,
      {ReportMode mode = ReportMode.personal, String? householdId})
      : this._(
          status: ReportsStatus.error,
          month: month,
          year: year,
          errorMessage: msg,
          mode: mode,
          householdId: householdId,
        );

  bool get isLoading => status == ReportsStatus.loading;

  @override
  List<Object?> get props =>
      [status, month, year, data, errorMessage, mode, householdId];
}
