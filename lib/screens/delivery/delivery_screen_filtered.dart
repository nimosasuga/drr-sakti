import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../models/delivery.dart';
import 'delivery_screen.dart';

class DeliveryScreenFiltered extends StatefulWidget {
  final User user;

  const DeliveryScreenFiltered({super.key, required this.user});

  @override
  State<DeliveryScreenFiltered> createState() => _DeliveryScreenFilteredState();
}

class _DeliveryScreenFilteredState extends State<DeliveryScreenFiltered> {
  final ApiService api = ApiService();
  late Future<List<Delivery>> _filteredDataFuture;

  @override
  void initState() {
    super.initState();
    _filteredDataFuture = _getFilteredData();
  }

  Future<List<Delivery>> _getFilteredData() async {
    final allData = await api.fetchDelivery();
    // Filter hanya data yang PIC = user login
    return allData
        .where(
          (item) => item.pic?.toLowerCase() == widget.user.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Delivery>>(
      future: _filteredDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery - My Data')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery - My Data')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return DeliveryScreen(
          user: widget.user,
          picFilterName: widget.user.name,
        );
      },
    );
  }
}
