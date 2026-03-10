import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../models/battery.dart';
import 'battery_screen.dart';

class BatteryScreenFiltered extends StatefulWidget {
  final User user;

  const BatteryScreenFiltered({super.key, required this.user});

  @override
  State<BatteryScreenFiltered> createState() => _BatteryScreenFilteredState();
}

class _BatteryScreenFilteredState extends State<BatteryScreenFiltered> {
  final ApiService api = ApiService();
  late Future<List<Battery>> _filteredDataFuture;

  @override
  void initState() {
    super.initState();
    _filteredDataFuture = _getFilteredData();
  }

  Future<List<Battery>> _getFilteredData() async {
    final allData = await api.fetchBatteryByBranch(widget.user.branch);
    // Filter hanya data yang PIC = user login
    return allData
        .where(
          (item) => item.pic?.toLowerCase() == widget.user.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Battery>>(
      future: _filteredDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battery - My Data')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battery - My Data')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return BatteryScreen(
          user: widget.user,
          picFilterName: widget.user.name,
        );
      },
    );
  }
}
