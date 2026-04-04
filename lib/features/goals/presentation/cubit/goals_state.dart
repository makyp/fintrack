part of 'goals_cubit.dart';

enum GoalsStatus { initial, loading, loaded, error }

class GoalsState extends Equatable {
  final GoalsStatus status;
  final List<SavingsGoal> goals;
  final String? errorMessage;

  const GoalsState._({
    required this.status,
    this.goals = const [],
    this.errorMessage,
  });

  const GoalsState.initial() : this._(status: GoalsStatus.initial);
  const GoalsState.loading() : this._(status: GoalsStatus.loading);
  const GoalsState.loaded(List<SavingsGoal> goals)
      : this._(status: GoalsStatus.loaded, goals: goals);
  const GoalsState.error(String msg)
      : this._(status: GoalsStatus.error, errorMessage: msg);

  bool get isLoading => status == GoalsStatus.loading;

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
