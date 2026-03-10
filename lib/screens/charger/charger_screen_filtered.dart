import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../models/charger.dart';
import 'charger_screen.dart';

class ChargerScreenFiltered extends StatefulWidget {
  final User user;

  const ChargerScreenFiltered({super.key, required this.user});

  @override
  State<ChargerScreenFiltered> createState() => _ChargerScreenFilteredState();
}

class _ChargerScreenFilteredState extends State<ChargerScreenFiltered> {
  final ApiService api = ApiService();
  late Future<List<Charger>> _filteredDataFuture;

  @override
  void initState() {
    super.initState();
    _filteredDataFuture = _getFilteredData();
  }

  Future<List<Charger>> _getFilteredData() async {
    final allData = await api.fetchChargerByBranch(widget.user.branch);
    // Filter hanya data yang PIC = user login
    return allData
        .where(
          (item) => item.pic?.toLowerCase() == widget.user.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Charger>>(
      future: _filteredDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Charger - My Data')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Charger - My Data')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return ChargerScreen(
          user: widget.user,
          picFilterName: widget.user.name,
        );
      },
    );
  }
}
