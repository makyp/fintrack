part of 'reports_cubit.dart';

enum ReportsStatus { initial, loading, loaded, error }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final ReportData? data;
  final int month;
  final int year;
  final String? errorMessage;

  const ReportsState._({
    required this.status,
    required this.month,
    required this.year,
    this.data,
    this.errorMessage,
  });

  const ReportsState.initial()
      : this._(
          status: ReportsStatus.initial,
          month: 0,
          year: 0,
        );

  const ReportsState.loading(int month, int year)
      : this._(status: ReportsStatus.loading, month: month, year: year);

  ReportsState.loaded(ReportData data)
      : this._(
          status: ReportsStatus.loaded,
          month: data.month,
          year: data.year,
          data: data,
        );

  const ReportsState.error(int month, int year, String msg)
      : this._(
          status: ReportsStatus.error,
          month: month,
          year: year,
          errorMessage: msg,
        );

  bool get isLoading => status == ReportsStatus.loading;

  @override
  List<Object?> get props => [status, month, year, data, errorMessage];
}
