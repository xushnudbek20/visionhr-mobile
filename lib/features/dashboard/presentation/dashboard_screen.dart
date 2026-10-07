import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hr_mobile/features/dashboard/presentation/dashboard_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hr_mobile/features/auth/presentation/login_provider.dart';
import 'package:hr_mobile/features/dashboard/presentation/widgets/user_card.dart';
import 'package:hr_mobile/features/dashboard/presentation/widgets/action_card.dart';
import 'package:hr_mobile/features/dashboard/presentation/widgets/stats_row.dart';
import 'package:hr_mobile/features/dashboard/presentation/widgets/inout_list.dart';
import 'package:hr_mobile/features/dashboard/presentation/liveness/liveness_screen.dart';
import 'package:hr_mobile/core/utils/haversine_util.dart';
import 'package:hr_mobile/core/utils/permission_helper.dart';
import 'package:hr_mobile/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).refresh());
  }

  void _handleWorkAction() async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    final state = ref.read(dashboardProvider);
    final user = ref.read(authProvider).user;
    if (user == null || state.userDetails == null) {
      setState(() => _isActionLoading = false);
      return;
    }

    // Google Play review account — skip geolocation check
    if (user.login == 'google-test@visionhr.uz') {
      final currentStatus = state.userDetails?['on_work_status'] ?? user.onWorkStatus ?? 0;
      final locations = state.userDetails!['locations'] as List? ?? [];
      final locationId = locations.isNotEmpty ? locations.first['id'] : 1;

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LivenessScreen(
              type: currentStatus == 1 ? 'out' : 'in',
              locationId: locationId,
            ),
          ),
        );
        if (mounted) {
          await ref.read(dashboardProvider.notifier).refresh();
          setState(() => _isActionLoading = false);
        }
      }
      return;
    }

    // 1. Request Permissions
    await PermissionHelper.requestLocationPermission();

    // 2. Get Location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("GPS xatoli: $e")));
        setState(() => _isActionLoading = false);
      }
      return;
    }

    // 3. Find Nearby Location
    final locations = state.userDetails!['locations'] as List? ?? [];
    double minDistance = double.infinity;
    Map<String, dynamic>? activeLoc;

    for (var loc in locations) {
      final String? coordsStr = loc['location'];
      double? lat, lon;
      if (coordsStr != null && coordsStr.contains(',')) {
        final parts = coordsStr.split(',');
        lat = double.tryParse(parts[0].trim());
        lon = double.tryParse(parts[1].trim());
      }
      
      if (lat == null) {
        lat = double.tryParse(loc['latitude'].toString());
        lon = double.tryParse(loc['longitude'].toString());
      }

      if (lat != null && lon != null) {
        final distance = HaversineUtil.calculateDistance(position.latitude, position.longitude, lat, lon);
        if (distance < minDistance) minDistance = distance;

        final radius = double.tryParse(loc['radius']?.toString() ?? "250");
        if (distance <= (radius ?? 250)) {
          activeLoc = loc;
          break;
        }
      }
    }

    if (activeLoc != null) {
      if (mounted) {
        // Use the freshest on_work_status from userDetails
        final currentStatus = state.userDetails?['on_work_status'] ?? user.onWorkStatus ?? 0;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LivenessScreen(
              type: currentStatus == 1 ? 'out' : 'in',
              locationId: activeLoc!['id'],
            ),
          ),
        );
        // Refresh dashboard data after returning from liveness screen
        if (mounted) {
          await ref.read(dashboardProvider.notifier).refresh();
          setState(() => _isActionLoading = false);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Siz eng yaqin filialdan ${minDistance.round()} metr uzoqlikdasiz"),
            backgroundColor: AppColors.warning,
          ),
        );
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);

    if (authState.user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.business)),
            const SizedBox(width: 8),
            Text("VISION HR", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: dashState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    UserCard(user: authState.user!, details: dashState.userDetails),
                    const SizedBox(height: 16),
                    ActionCard(
                      onWorkStatus: authState.user!.onWorkStatus ?? 0,
                      details: dashState.userDetails,
                      onAction: _handleWorkAction,
                      isLoading: _isActionLoading,
                    ),
                    const SizedBox(height: 16),
                    StatsRow(
                      firstIn: dashState.firstIn?.createdAt != null ? _formatTime(dashState.firstIn!.createdAt) : null,
                      lastOut: dashState.lastOut?.createdAt != null ? _formatTime(dashState.lastOut!.createdAt) : null,
                    ),
                    const SizedBox(height: 16),
                    InOutList(logs: dashState.logs),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatTime(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
