import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../models/update_job.dart';
import 'update_job_screen.dart';

class UpdateJobScreenFiltered extends StatefulWidget {
  final User user;

  const UpdateJobScreenFiltered({super.key, required this.user});

  @override
  State<UpdateJobScreenFiltered> createState() =>
      _UpdateJobScreenFilteredState();
}

class _UpdateJobScreenFilteredState extends State<UpdateJobScreenFiltered> {
  final ApiService api = ApiService();
  late Future<List<UpdateJob>> _filteredJobsFuture;

  @override
  void initState() {
    super.initState();
    _filteredJobsFuture = _getFilteredJobs();
  }

  Future<List<UpdateJob>> _getFilteredJobs() async {
    final allJobs = await api.fetchUpdateJobsByBranch(widget.user.branch);
    // Filter hanya data yang PIC = user login
    return allJobs
        .where(
          (job) => job.pic?.toLowerCase() == widget.user.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UpdateJob>>(
      future: _filteredJobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Update Job - My Data')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Update Job - My Data')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // Pass filtered data dengan picFilterName
        return UpdateJobScreen(
          user: widget.user,
          picFilterName: widget.user.name, // Trigger filter di original screen
        );
      },
    );
  }
}
