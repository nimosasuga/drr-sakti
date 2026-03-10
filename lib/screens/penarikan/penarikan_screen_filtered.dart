import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../models/penarikan.dart';
import 'penarikan_screen.dart';

class PenarikanScreenFiltered extends StatefulWidget {
  final User user;

  const PenarikanScreenFiltered({super.key, required this.user});

  @override
  State<PenarikanScreenFiltered> createState() =>
      _PenarikanScreenFilteredState();
}

class _PenarikanScreenFilteredState extends State<PenarikanScreenFiltered> {
  final ApiService api = ApiService();
  late Future<List<Penarikan>> _filteredDataFuture;

  @override
  void initState() {
    super.initState();
    _filteredDataFuture = _getFilteredData();
  }

  Future<List<Penarikan>> _getFilteredData() async {
    final allData = await api.fetchPenarikanByBranch(widget.user.branch);
    // Filter hanya data yang PIC = user login
    return allData
        .where(
          (item) => item.pic?.toLowerCase() == widget.user.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Penarikan>>(
      future: _filteredDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Penarikan - My Data')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Penarikan - My Data')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return PenarikanScreen(
          user: widget.user,
          picFilterName: widget.user.name,
        );
      },
    );
  }
}
