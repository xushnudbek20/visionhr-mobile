import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hr_mobile/features/dashboard/models/inout_model.dart';
import 'package:hr_mobile/features/dashboard/repository/dashboard_repository.dart';
import 'package:hr_mobile/features/auth/presentation/login_provider.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});

class DashboardState {
  final bool isLoading;
  final Map<String, dynamic>? userDetails;
  final List<InOutModel> logs;
  final String? error;

  DashboardState({
    this.isLoading = false,
    this.userDetails,
    this.logs = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? userDetails,
    List<InOutModel>? logs,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      userDetails: userDetails ?? this.userDetails,
      logs: logs ?? this.logs,
      error: error,
    );
  }

  // Helper getters
  InOutModel? get firstIn => logs.isEmpty ? null : logs.where((l) => l.type == 'in').firstOrNull;
  InOutModel? get lastOut => logs.isEmpty ? null : logs.where((l) => l.type == 'out').lastOrNull;
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final Ref _ref;

  DashboardNotifier(this._repository, this._ref) : super(DashboardState());

  Future<void> refresh() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, dynamic>? userDetails;
    List<InOutModel> logs = [];
    String? errorMsg;

    try {
      userDetails = await _repository.getUserDetails(user.id);
    } catch (e) {
      print("getUserDetails Error: $e");
      errorMsg = e.toString();
    }

    try {
      logs = await _repository.getAttendanceLogs(userId: user.id, fromDate: today, toDate: today);
    } catch (e) {
      print("getAttendanceLogs Error: $e");
      errorMsg ??= e.toString();
    }

    state = state.copyWith(
      isLoading: false,
      userDetails: userDetails,
      logs: logs,
      error: errorMsg,
    );

    // Sync on_work_status back to auth provider so UI updates immediately
    if (userDetails != null) {
      final newStatus = userDetails['on_work_status'];
      if (newStatus != null && newStatus != user.onWorkStatus) {
        _ref.read(authProvider.notifier).updateUser(
          user.copyWith(onWorkStatus: newStatus is int ? newStatus : int.tryParse(newStatus.toString())),
        );
      }
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repository, ref);
});
