import 'package:fintrack/core/di/injection.dart';
import 'package:fintrack/features/budgets/data/datasources/budget_datasource.dart';
import 'package:fintrack/features/budgets/data/models/budget_model.dart';
import 'package:fintrack/features/insights/presentation/widgets/tips_section.dart';
import 'package:fintrack/features/reports/data/datasources/reports_datasource.dart';
import 'package:fintrack/features/reports/domain/models/report_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the grey-screen crash: with EXACTLY ONE tip (e.g. a
/// fresh user only gets "Empieza a recibir consejos"), _TipCard used to be
/// laid out with unbounded height, its internal Expanded blew up the layout,
/// and a release build painted the whole dashboard grey.
class _FakeReports implements ReportsDataSource {
  final ReportData data;
  _FakeReports(this.data);

  @override
  Future<ReportData> loadReport(String userId, int year, int month) async =>
      data;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeBudgets implements BudgetDataSource {
  @override
  Future<List<BudgetModel>> getBudgets(String userId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  testWidgets('a single tip renders inside slivers without a layout crash',
      (tester) async {
    // Empty month → InsightsEngine produces exactly one tip (no_data).
    getIt.registerSingleton<ReportsDataSource>(
        _FakeReports(ReportData.empty(8, 2026)));
    getIt.registerSingleton<BudgetDataSource>(_FakeBudgets());
    addTearDown(getIt.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: TipsSection(userId: 'u1')),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Empieza a recibir consejos'), findsOneWidget);
  });
}
