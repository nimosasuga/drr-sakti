// lib/services/api_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/unit.dart';
import '../models/update_job.dart';
import '../models/penarikan.dart';
import '../models/dashboard_stats.dart';
import '../models/battery.dart';
import '../models/charger.dart';
import '../models/delivery.dart';
import '../constants/constants.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    return headers;
  }

  // ===== UNIT ASSETS METHODS =====
  Future<List<Unit>> fetchUnits() async {
    final uri = Uri.parse('$baseUrl/read.php');
    developer.log('DEBUG: GET $uri');

    final client = http.Client();
    final req = http.Request('GET', uri)..followRedirects = false;
    final streamed = await client.send(req);
    final resp = await http.Response.fromStream(streamed);

    developer.log('DEBUG: status=${resp.statusCode}');
    developer.log('DEBUG: headers=${resp.headers}');
    developer.log(
      'DEBUG: bodyPreview=${resp.body.length > 400 ? resp.body.substring(0, 400) : resp.body}',
    );

    if (resp.statusCode >= 300 && resp.statusCode < 400) {
      final loc = resp.headers['location'];
      throw Exception(
        'Redirect detected: status=${resp.statusCode}, location=$loc',
      );
    }

    if (resp.statusCode == 200) {
      try {
        final parsed = json.decode(resp.body);
        if (parsed is List) {
          return parsed
              .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (parsed is Map && parsed['data'] is List) {
          return (parsed['data'] as List)
              .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          throw Exception('Unexpected JSON format for fetchUnits');
        }
      } catch (e) {
        throw Exception('Parse error: $e\nRespBody: ${resp.body}');
      }
    }

    throw Exception(
      'Failed request: status=${resp.statusCode}, body=${resp.body}',
    );
  }

  // --- FETCH ONE
  Future<Unit?> fetchUnit(int id) async {
    final uri = Uri.parse('$baseUrl/read_one.php?id=$id');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      try {
        final parsed = json.decode(resp.body);
        if (parsed is Map) {
          return Unit.fromJson(Map<String, dynamic>.from(parsed));
        } else if (parsed is List && parsed.isNotEmpty) {
          return Unit.fromJson(Map<String, dynamic>.from(parsed.first));
        } else {
          return null;
        }
      } catch (e) {
        throw Exception('Parse error fetchUnit: $e\nBody: ${resp.body}');
      }
    } else if (resp.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch unit: ${resp.statusCode}');
    }
  }

  // --- CREATE
  Future<Map<String, dynamic>> createUnit(Unit u) async {
    final uri = Uri.parse('$baseUrl/create.php');
    final body = json.encode(u.toJson());
    developer.log('>>> createUnit POST $uri');
    developer.log('>>> request body: $body');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    developer.log(
      '<<< createUnit -> status=${resp.statusCode}, body=${resp.body}',
    );

    final int status = resp.statusCode;
    String message = resp.body;
    int? existingId;

    try {
      final dynamic parsedRaw = json.decode(resp.body);
      if (parsedRaw is Map) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          parsedRaw,
        );
        message = parsed['message']?.toString() ?? message;
        if (parsed.containsKey('existing_id')) {
          final dynamic ex = parsed['existing_id'];
          if (ex is int) {
            existingId = ex;
          } else if (ex is String) {
            existingId = int.tryParse(ex);
          }
        }
      }
    } catch (_) {
      // ignore parse errors, keep message = resp.body
    }

    final result = {
      'ok': status >= 200 && status < 300,
      'statusCode': status,
      'message': message,
      'body': resp.body,
    };
    if (existingId != null) result['existing_id'] = existingId;
    return result;
  }

  // --- UPDATE
  Future<Map<String, dynamic>> updateUnit(Unit u) async {
    final uri = Uri.parse('$baseUrl/update.php');
    final body = json.encode(u.toJson());
    developer.log('>>> updateUnit PUT $uri');
    developer.log('>>> request body: $body');

    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    developer.log(
      '<<< updateUnit -> status=${resp.statusCode}, body=${resp.body}',
    );
    final int status = resp.statusCode;
    String message = resp.body;

    try {
      final dynamic parsedRaw = json.decode(resp.body);
      if (parsedRaw is Map) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          parsedRaw,
        );
        message = parsed['message']?.toString() ?? message;
      }
    } catch (_) {}

    return {
      'ok': status >= 200 && status < 300,
      'statusCode': status,
      'message': message,
      'body': resp.body,
    };
  }

  // --- DELETE
  Future<Map<String, dynamic>> deleteUnit(int id) async {
    final uri = Uri.parse('$baseUrl/delete.php');
    final resp = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id}),
    );

    final int status = resp.statusCode;
    String message = resp.body;
    try {
      final dynamic parsedRaw = json.decode(resp.body);
      if (parsedRaw is Map) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          parsedRaw,
        );
        message = parsed['message']?.toString() ?? message;
      }
    } catch (_) {}

    return {
      'ok': status >= 200 && status < 300,
      'statusCode': status,
      'message': message,
      'body': resp.body,
    };
  }

  // --- CHECK SERIAL (helper) : always returns Map<String,dynamic>
  Future<Map<String, dynamic>> checkSerial(String serial) async {
    final uri = Uri.parse(
      '$baseUrl/check_serial.php?serial=${Uri.encodeQueryComponent(serial)}',
    );
    final resp = await http.get(uri);

    try {
      final dynamic parsedRaw = json.decode(resp.body);
      if (parsedRaw is Map) {
        return Map<String, dynamic>.from(parsedRaw);
      }
    } catch (_) {
      // fallthrough
    }
    // fallback: return a typed map
    return {'exists': false};
  }

  // ===== UPDATE JOBS METHODS =====

  // --- FETCH ALL UPDATE JOBS (Revised)
  // Mengambil data global untuk Super Admin (all=true)
  Future<List<UpdateJob>> fetchUpdateJobs() async {
    try {
      // PENTING: Menggunakan read_update_jobs.php dan tambahkan ?all=true
      final uri = Uri.parse('$baseUrl/read_update_jobs.php?all=true');

      developer.log('=== FETCHING ALL GLOBAL JOBS (NO LIMIT) ===');
      developer.log('URL: $uri');

      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final jsonResponse = json.decode(resp.body);

        // Cek format yang diharapkan: { "success": true, "data": [...] }
        if (jsonResponse is Map && jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];

          final jobs = data
              .map((e) => UpdateJob.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          developer.log('✅ Loaded ${jobs.length} global jobs');
          return jobs;
        } else {
          developer.log('⚠️ API returned success=false or invalid format');
          return [];
        }
      } else {
        throw Exception('Failed to fetch global jobs: ${resp.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error fetchUpdateJobs: $e');
      rethrow;
    }
  }

  // --- FETCH SINGLE UPDATE JOB - FIXED VERSION
  Future<UpdateJob?> fetchUpdateJob(int id) async {
    try {
      developer.log('=== FETCHING UPDATE JOB ID: $id ===');

      // Use the unified endpoint with id parameter
      final uri = Uri.parse('$baseUrl/read_update_jobs.php?id=$id');
      developer.log('Trying endpoint: $uri');

      final response = await http.get(uri);
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final dynamic parsed = json.decode(response.body);

          // Check if it's a single job object (has id field)
          if (parsed is Map && parsed.containsKey('id')) {
            final job = UpdateJob.fromJson(Map<String, dynamic>.from(parsed));
            developer.log('=== SUCCESSFULLY PARSED SINGLE JOB ===');
            developer.log('Job ID: ${job.id}');
            developer.log('Serial: ${job.serialNumber}');
            return job;
          }
          // Check if it's an error response
          else if (parsed is Map && parsed['success'] == false) {
            developer.log('=== API ERROR: ${parsed['message']} ===');
            return null;
          }
          // If it's a pagination response (shouldn't happen with id parameter)
          else if (parsed is Map && parsed['data'] is List) {
            developer.log('=== UNEXPECTED PAGINATION RESPONSE ===');
            return null;
          }
        } catch (e) {
          developer.log('=== PARSE ERROR: $e ===');
          developer.log('Raw response: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        developer.log('=== JOB NOT FOUND (404) ===');
        return null;
      }

      developer.log('=== JOB NOT FOUND OR INVALID RESPONSE ===');
      return null;
    } catch (e) {
      developer.log('=== FETCH UPDATE JOB ERROR: $e ===');
      return null;
    }
  }

  // --- CREATE UPDATE JOB
  Future<Map<String, dynamic>> createUpdateJob(UpdateJob job) async {
    try {
      final uri = Uri.parse('$baseUrl/create_update_job.php');
      final body = json.encode(job.toJson());

      developer.log('>>> CREATE UPDATE JOB POST $uri');
      developer.log('>>> Request body: $body');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      developer.log(
        '<<< CREATE UPDATE JOB -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;
      Map<String, dynamic>? parsed;

      try {
        final dynamic pr = json.decode(resp.body);
        if (pr is Map) parsed = Map<String, dynamic>.from(pr);
        if (parsed != null && parsed['message'] != null) {
          message = parsed['message'].toString();
        }
      } catch (_) {}

      final result = {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };

      if (parsed != null && parsed['id'] != null) result['id'] = parsed['id'];
      return result;
    } catch (e) {
      developer.log('=== CREATE UPDATE JOB EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  // --- UPDATE UPDATE JOB
  Future<Map<String, dynamic>> updateUpdateJob(UpdateJob job) async {
    try {
      final uri = Uri.parse('$baseUrl/update_update_job.php');
      final body = json.encode(job.toJson());

      developer.log('>>> UPDATE UPDATE JOB PUT $uri');
      developer.log('>>> Request body: $body');

      final resp = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      developer.log(
        '<<< UPDATE UPDATE JOB -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;

      try {
        final dynamic pr = json.decode(resp.body);
        if (pr is Map && pr['message'] != null) {
          message = pr['message'].toString();
        }
      } catch (_) {}

      return {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };
    } catch (e) {
      developer.log('=== UPDATE UPDATE JOB EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  // --- DELETE UPDATE JOB
  Future<Map<String, dynamic>> deleteUpdateJob(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/delete_update_job.php');

      developer.log('>>> DELETE UPDATE JOB ID: $id');
      developer.log('>>> URL: $uri');

      final resp = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );

      developer.log(
        '<<< DELETE UPDATE JOB -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;

      try {
        final dynamic pr = json.decode(resp.body);
        if (pr is Map && pr['message'] != null) {
          message = pr['message'].toString();
        }
      } catch (_) {}

      return {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };
    } catch (e) {
      developer.log('=== DELETE UPDATE JOB EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  // --- FETCH PARTNERS BY BRANCH (from data_user table)
  Future<List<String>> fetchPartnersByBranch(
    String branch, {
    String? currentUserName,
  }) async {
    try {
      developer.log('🎯 === START FETCHING PARTNERS FOR BRANCH: $branch ===');
      developer.log('👤 Current User to exclude: $currentUserName');

      // Encode parameters
      final params = <String, String>{'branch': branch};

      // Add exclude parameter if currentUserName is provided
      if (currentUserName != null && currentUserName.isNotEmpty) {
        params['exclude'] = currentUserName;
      }

      final uri = Uri.parse(
        '$baseUrl/read_partners_by_branch.php',
      ).replace(queryParameters: params);
      developer.log('🔗 URL: $uri');

      final startTime = DateTime.now();
      final resp = await http.get(uri);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      developer.log('📡 Response time: ${duration.inMilliseconds}ms');
      developer.log('📊 Response status: ${resp.statusCode}');
      developer.log('📦 Response body length: ${resp.body.length}');
      developer.log('📄 Response body: ${resp.body}');

      // Check for empty response first
      if (resp.body.isEmpty ||
          resp.body.trim() == '[]' ||
          resp.body.trim() == 'null') {
        developer.log('❌ EMPTY RESPONSE from API');
        // Tidak perlu fallback mock data di sini, langsung return [] jika API empty
      }

      if (resp.statusCode == 200) {
        try {
          final dynamic parsed = json.decode(resp.body);
          developer.log('🔍 Parsed type: ${parsed.runtimeType}');

          List<String> partners = [];

          if (parsed is List) {
            developer.log('✅ Processing as List with ${parsed.length} items');

            for (int i = 0; i < parsed.length; i++) {
              final user = parsed[i];
              developer.log('👤 User $i: $user');

              final name = user['name']?.toString() ?? '';
              final statusUser = user['status_user']?.toString() ?? '';
              final userBranch = user['branch']?.toString() ?? '';

              developer.log('   - Name: "$name"');
              developer.log('   - Role: "$statusUser"');
              developer.log('   - Branch: "$userBranch"');

              // Format: "Name (Role)" untuk lebih informatif
              if (name.isNotEmpty) {
                //                final role = _formatUserRole(statusUser);
                final partner = name;
                developer.log('   ✅ Adding: $partner');
                partners.add(partner);
              } else {
                developer.log('   ❌ Skipping - Empty name');
              }
            }
          }

          // Remove duplicates and sort
          final uniquePartners = partners.toSet().toList()..sort();

          developer.log(
            '🎉 SUCCESS: Found ${uniquePartners.length} unique partners',
          );
          developer.log('📋 Partners list: $uniquePartners');

          // Mengembalikan hasil yang sukses
          return uniquePartners;
        } catch (e) {
          developer.log('❌ JSON PARSE ERROR: $e');
          developer.log('📄 Raw body that failed to parse: ${resp.body}');
          // Mengembalikan list kosong jika parsing gagal
          return [];
        }
      } else {
        developer.log('❌ HTTP ERROR: ${resp.statusCode}');
        // Mengembalikan list kosong jika status code bukan 200
        return [];
      }
    } catch (e) {
      developer.log('❌ NETWORK ERROR: $e');
      developer.log('💡 Using mock data as fallback');
      // Mengembalikan list kosong jika ada error jaringan
      return [];
    }
  }

  // Helper method untuk format role
  String _formatUserRole(String statusUser) {
    final role = statusUser.toUpperCase();
    if (role.contains('FIELD SERVICE')) {
      return 'Field Service';
    } else if (role.contains('FMC')) {
      return 'FMC';
    } else if (role.contains('KOORDINATOR')) {
      return 'Koordinator';
    } else if (role.contains('ADMIN')) {
      return 'Admin';
    } else {
      return 'User';
    }
  }

  // ===== BRANCH-BASED METHODS =====
  Future<List<Unit>> fetchAllUnitsForFiltering() async {
    try {
      developer.log('📥 Fetching ALL units (no filter)...');
      final uri = Uri.parse('$baseUrl/read.php');

      final resp = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              developer.log('⏱️ TIMEOUT: Fetch all units took too long');
              throw TimeoutException('Fetch all units timeout');
            },
          );

      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body length: ${resp.body.length}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        try {
          final parsed = json.decode(resp.body);
          List<Unit> units = [];

          if (parsed is List) {
            units = parsed
                .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          } else if (parsed is Map && parsed['data'] is List) {
            units = (parsed['data'] as List)
                .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          developer.log('✅ Successfully fetched ${units.length} total units');
          return units;
        } catch (e) {
          developer.log('❌ Parse error: $e');
          return [];
        }
      } else {
        developer.log('❌ HTTP Error: ${resp.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('❌ Fetch all units error: $e');
      return [];
    }
  }

  // --- FETCH UNITS BY BRANCH dengan fallback
  Future<List<Unit>> fetchUnitsByBranch(String branch) async {
    try {
      developer.log('=== FETCHING UNITS BY BRANCH: $branch ===');

      // Strategy: Langsung ke fallback (fetch all + filter)
      // Karena read_by_branch.php sering error
      developer.log(
        '⚡ Using direct fetch-all strategy (bypass branch endpoint)',
      );

      return await _filterUnitsByBranch(branch);
    } catch (e) {
      developer.log('❌ FETCH UNITS BY BRANCH ERROR: $e');
      return [];
    }
  }

  Future<List<Unit>> _filterUnitsByBranch(String branch) async {
    try {
      developer.log('🔍 Filtering units for branch: $branch');

      // Fetch semua units
      final allUnits = await fetchAllUnitsForFiltering();

      if (allUnits.isEmpty) {
        developer.log('⚠️ No units found in database');
        return [];
      }

      developer.log('📊 Total units in database: ${allUnits.length}');

      // Filter by branch (case-insensitive)
      final filteredUnits = allUnits.where((unit) {
        final unitBranch = unit.branch?.toUpperCase() ?? '';
        final targetBranch = branch.toUpperCase();
        return unitBranch == targetBranch;
      }).toList();

      developer.log(
        '✅ Filtered: ${filteredUnits.length} units found for branch $branch',
      );

      return filteredUnits;
    } catch (e) {
      developer.log('❌ Filter error: $e');
      return [];
    }
  }

  Future<List<Unit>> fetchUnitsByBranchWithRetry(String branch) async {
    try {
      developer.log('=== ATTEMPTING FETCH UNITS BY BRANCH: $branch ===');
      final uri = Uri.parse(
        '$baseUrl/read_by_branch.php?branch=${Uri.encodeComponent(branch)}',
      );

      final resp = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              developer.log('⏱️ Branch endpoint timeout');
              throw TimeoutException('read_by_branch timeout');
            },
          );

      developer.log('Response status: ${resp.statusCode}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty && resp.body != '[]') {
        try {
          final parsed = json.decode(resp.body);
          List<Unit> units = [];

          if (parsed is List) {
            units = parsed
                .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          } else if (parsed is Map && parsed['data'] is List) {
            units = (parsed['data'] as List)
                .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (units.isNotEmpty) {
            developer.log('✅ Got ${units.length} units from branch endpoint');
            return units;
          }
        } catch (e) {
          developer.log('⚠️ Parse error from branch endpoint: $e');
        }
      }

      // Fallback jika branch endpoint error atau empty
      developer.log('📥 Branch endpoint failed/empty, using fallback...');
      return await _filterUnitsByBranch(branch);
    } catch (e) {
      developer.log('❌ Branch endpoint error: $e, using fallback...');
      return await _filterUnitsByBranch(branch);
    }
  }
  // Fallback method - fetch all units and filter by branch
  /*Future<List<Unit>> _fetchUnitsByBranchFallback(String branch) async {
    try {
      developer.log('📥 FALLBACK: Fetching ALL units for filtering...');

      // Tambah timeout untuk fetchUnits juga
      final allUnits = await http
          .get(Uri.parse('$baseUrl/read.php'))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              developer.log('⏱️ TIMEOUT: Fetch all units took too long');
              throw TimeoutException('Fetch all units timeout');
            },
          )
          .then((resp) {
            if (resp.statusCode == 200 && resp.body.isNotEmpty) {
              final parsed = json.decode(resp.body);
              if (parsed is List) {
                return parsed
                    .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                    .toList();
              } else if (parsed is Map && parsed['data'] is List) {
                return (parsed['data'] as List)
                    .map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
                    .toList();
              }
            }
            return <Unit>[];
          });

      // Filter by branch (case-insensitive)
      final filteredUnits = allUnits
          .where(
            (unit) =>
                unit.branch != null &&
                unit.branch!.toUpperCase() == branch.toUpperCase(),
          )
          .toList();

      developer.log(
        '✅ FALLBACK: Filtered ${filteredUnits.length} units from ${allUnits.length} total',
      );
      return filteredUnits;
    } catch (e) {
      developer.log('❌ FALLBACK FAILED: $e');
      return [];
    }
  }*/

  // --- FETCH UPDATE JOBS BY BRANCH (Revised)
  // Mengambil semua data branch untuk statistik (all=true)
  Future<List<UpdateJob>> fetchUpdateJobsByBranch(String branch) async {
    try {
      // PENTING: Menggunakan read_update_jobs.php dan tambahkan &all=true
      final uri = Uri.parse(
        '$baseUrl/read_update_jobs.php?branch=${Uri.encodeComponent(branch)}&all=true',
      );

      developer.log('=== FETCHING JOBS FOR BRANCH: $branch (ALL DATA) ===');
      developer.log('URL: $uri');

      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final jsonResponse = json.decode(resp.body);

        // Cek format yang diharapkan: { "success": true, "data": [...] }
        if (jsonResponse is Map && jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];

          final jobs = data
              .map((e) => UpdateJob.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          developer.log('✅ Loaded ${jobs.length} jobs for branch $branch');
          return jobs;
        } else {
          developer.log('⚠️ API returned success=false or invalid format');
          return [];
        }
      } else {
        throw Exception('Failed to fetch jobs: ${resp.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error fetchUpdateJobsByBranch: $e');
      rethrow;
    }
  }

  // Method untuk testing - force menggunakan API
  Future<List<String>> fetchPartnersForceAPI(
    String branch, {
    String? currentUserName,
  }) async {
    developer.log('🚀 FORCE API CALL FOR PARTNERS');

    final params = <String, String>{'branch': branch};

    if (currentUserName != null && currentUserName.isNotEmpty) {
      params['exclude'] = currentUserName;
    }

    final uri = Uri.parse(
      '$baseUrl/read_partners_by_branch.php',
    ).replace(queryParameters: params);
    developer.log('🔗 URL: $uri');

    try {
      final resp = await http.get(uri);
      developer.log('📡 Response status: ${resp.statusCode}');
      developer.log('📄 Response body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty && resp.body != '[]') {
        final parsed = json.decode(resp.body) as List;
        final partners = parsed
            .map((user) {
              final name = user['name']?.toString() ?? '';
              final statusUser = user['status_user']?.toString() ?? '';
              return '$name (${_formatUserRole(statusUser)})';
            })
            .where((name) => name.isNotEmpty)
            .toList();

        return partners.toSet().toList()..sort();
      }

      // Jika sampai sini, return empty list
      return [];
    } catch (e) {
      developer.log('❌ Error: $e');
      return [];
    }
  }

  // Method getMechanicStats yang sudah dikoreksi
  Future<Map<String, dynamic>> getMechanicStats(String pic) async {
    try {
      developer.log('🔍 Fetching stats for PIC: $pic');
      developer.log('🌐 URL: $baseUrl/mechanic_stats.php?pic=$pic');

      final response = await http.get(
        Uri.parse('$baseUrl/mechanic_stats.php?pic=$pic'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      developer.log('📡 Response Status: ${response.statusCode}');
      developer.log('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load mechanic stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('❌ API Error: $e');
      throw Exception('Error fetching mechanic stats: $e');
    }
  }
  // ===== PENARIKAN METHODS =====

  /// Generate UUID untuk penarikan baru
  Future<String> generatePenarikanUUID() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=generate_uuid',
      );
      developer.log('=== GENERATING PENARIKAN UUID ===');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['uuid'] != null) {
          return parsed['uuid'].toString();
        }
      }

      // Fallback: generate locally
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uuid = (timestamp % 10000000).toString().padLeft(7, '0');
      developer.log('Fallback UUID: $uuid');
      return uuid;
    } catch (e) {
      developer.log('=== ERROR GENERATING UUID ===');
      developer.log('Error: $e');
      // Generate local UUID as last resort
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 10000000).toString().padLeft(7, '0');
    }
  }

  /// Fetch all penarikan
  Future<List<Penarikan>> fetchPenarikan() async {
    try {
      final uri = Uri.parse('$baseUrl/penarikan/penarikan_api.php?action=read');
      developer.log('=== FETCHING ALL PENARIKAN ===');
      developer.log('URL: $uri');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);

        if (parsed['ok'] == true && parsed['data'] is List) {
          final list = (parsed['data'] as List)
              .map((e) => Penarikan.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          developer.log('=== SUCCESSFULLY PARSED ${list.length} PENARIKAN ===');
          return list;
        }
      }

      developer.log('=== NO DATA FOUND ===');
      return [];
    } catch (e) {
      developer.log('=== FETCH PENARIKAN ERROR ===');
      developer.log('Error: $e');
      throw Exception('Failed to fetch penarikan: $e');
    }
  }

  /// Fetch single penarikan by ID
  Future<Penarikan?> fetchOnePenarikan(String id) async {
    try {
      // 🔥 KOREKSI: Mengubah action=read_one menjadi action=read 🔥
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=read&id=${Uri.encodeComponent(id)}',
      );
      developer.log('=== FETCHING PENARIKAN ID: $id ===');
      developer.log(
        'API Request URL: $uri',
      ); // Tambahkan log URL untuk debugging

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body length: ${resp.body.length}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);

        // API Read (tanpa filter) mengembalikan List di key 'data'.
        // Jika kita menggunakan filter ID, API mungkin mengembalikan data tunggal di key 'data'
        // atau mengembalikan List dengan satu item.

        if (parsed['ok'] == true) {
          final dynamic data = parsed['data'];

          if (data is Map) {
            // Kasus 1: Mengembalikan objek tunggal di 'data'
            developer.log('Parsed single Penarikan object.');
            return Penarikan.fromJson(Map<String, dynamic>.from(data));
          } else if (data is List && data.isNotEmpty) {
            // Kasus 2: Mengembalikan List dengan satu objek
            developer.log('Parsed Penarikan List with ${data.length} items.');
            return Penarikan.fromJson(Map<String, dynamic>.from(data.first));
          }
        }
      } else if (resp.statusCode == 400) {
        developer.log('❌ ERROR 400 DETAIL: ${resp.body}');
        try {
          final errorData = json.decode(resp.body);
          developer.log(
            'Server Error Message: ${errorData['message'] ?? 'No message'}',
          );
        } catch (_) {
          developer.log('Could not parse error body as JSON.');
        }
        return null; // Return null jika API mengembalikan error 400
      }

      developer.log(
        'Penarikan ID $id not found or unexpected response structure.',
      );
      return null;
    } catch (e) {
      developer.log('=== FETCH ONE PENARIKAN ERROR ===');
      developer.log('Error: $e');
      return null;
    }
  }

  /// Fetch penarikan by branch
  // Di ApiService class
  Future<List<Penarikan>> fetchPenarikanByBranch(String branch) async {
    try {
      // 🔥 KOREKSI: Gunakan path file PHP yang benar dan action yang sesuai.
      final url = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=read&branch=${Uri.encodeComponent(branch)}',
      );

      developer.log('API Request URL: $url');

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Sesuaikan dengan format JSON API Anda: {"ok": true, "data": [...] }
        if (data['ok'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map(
                (item) => Penarikan.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
          developer.log(
            '=== SUCCESSFULLY PARSED ${list.length} PENARIKAN BY BRANCH ===',
          );
          return list;
        } else {
          developer.log(
            'Failed to load penarikan data (ok=false atau data bukan List)',
          );
          return [];
        }
      } else if (response.statusCode == 400) {
        // Log detail error untuk debugging
        final errorData = json.decode(response.body);
        developer.log('Error 400 details: $errorData');
        throw Exception(
          'Bad request: ${errorData['message'] ?? 'Invalid parameters'}',
        );
      } else {
        throw Exception('Failed to load penarikan: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in fetchPenarikanByBranch: $e');
      rethrow;
    }
  }

  /// Create new penarikan
  Future<Map<String, dynamic>> createPenarikan(Penarikan penarikan) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=create',
      );
      final body = json.encode(penarikan.toJson());

      developer.log('>>> CREATE PENARIKAN POST $uri');
      developer.log('>>> Request body: $body');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      developer.log(
        '<<< CREATE PENARIKAN -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;

      try {
        final parsed = json.decode(resp.body);
        if (parsed is Map && parsed['message'] != null) {
          message = parsed['message'].toString();
        }
      } catch (_) {}

      return {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };
    } catch (e) {
      developer.log('=== CREATE PENARIKAN EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  /// Update existing penarikan
  Future<Map<String, dynamic>> updatePenarikan(Penarikan penarikan) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=update',
      );
      final body = json.encode(penarikan.toJson());

      developer.log('>>> UPDATE PENARIKAN PUT $uri');
      developer.log('>>> Request body: $body');

      final resp = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      developer.log(
        '<<< UPDATE PENARIKAN -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;

      try {
        final parsed = json.decode(resp.body);
        if (parsed is Map && parsed['message'] != null) {
          message = parsed['message'].toString();
        }
      } catch (_) {}

      return {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };
    } catch (e) {
      developer.log('=== UPDATE PENARIKAN EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  /// Delete penarikan
  Future<Map<String, dynamic>> deletePenarikan(String id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=delete&id=$id',
      );

      developer.log('>>> DELETE PENARIKAN ID: $id');
      developer.log('>>> URL: $uri');

      final resp = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      developer.log(
        '<<< DELETE PENARIKAN -> status=${resp.statusCode}, body=${resp.body}',
      );

      final int status = resp.statusCode;
      String message = resp.body;

      try {
        final parsed = json.decode(resp.body);
        if (parsed is Map && parsed['message'] != null) {
          message = parsed['message'].toString();
        }
      } catch (_) {}

      return {
        'ok': status >= 200 && status < 300,
        'statusCode': status,
        'message': message,
        'body': resp.body,
      };
    } catch (e) {
      developer.log('=== DELETE PENARIKAN EXCEPTION ===');
      developer.log('Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Exception: $e',
        'body': '',
      };
    }
  }

  // ===== HELPER METHODS FOR CASCADING DROPDOWNS =====

  /// Get unique customers by branch (from unit_assets)
  Future<List<String>> getCustomersByBranch(String branch) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=get_customers&branch=${Uri.encodeComponent(branch)}',
      );
      developer.log('=== FETCHING CUSTOMERS FOR BRANCH: $branch ===');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);
        developer.log('Parsed response: $parsed');

        // Handle different response formats
        if (parsed['success'] == true) {
          if (parsed['data'] != null && parsed['data']['customers'] is List) {
            // Format: {"success":true,"data":{"customers":[...]}}
            final customers = (parsed['data']['customers'] as List)
                .map((e) => e.toString())
                .where((customer) => customer.isNotEmpty)
                .toList();
            developer.log(
              '=== FOUND ${customers.length} CUSTOMERS FROM DATA KEY ===',
            );
            return customers;
          } else if (parsed['customers'] is List) {
            // Format: {"success":true,"customers":[...]}
            final customers = (parsed['customers'] as List)
                .map((e) => e.toString())
                .where((customer) => customer.isNotEmpty)
                .toList();
            developer.log(
              '=== FOUND ${customers.length} CUSTOMERS FROM ROOT KEY ===',
            );
            return customers;
          }
        } else if (parsed['ok'] == true && parsed['customers'] is List) {
          // Format: {"ok":true,"customers":[...]}
          final customers = (parsed['customers'] as List)
              .map((e) => e.toString())
              .where((customer) => customer.isNotEmpty)
              .toList();
          developer.log(
            '=== FOUND ${customers.length} CUSTOMERS FROM OK FORMAT ===',
          );
          return customers;
        }
      } else if (resp.statusCode == 500) {
        developer.log(
          '❌ SERVER ERROR (500) - Falling back to direct database query',
        );
        // Fallback: query langsung dari unit_assets
        return await _getCustomersFallback(branch);
      }

      developer.log('=== NO CUSTOMERS FOUND OR INVALID FORMAT ===');
      return [];
    } catch (e) {
      developer.log('=== GET CUSTOMERS ERROR ===');
      developer.log('Error: $e');
      // Fallback ke query langsung
      return await _getCustomersFallback(branch);
    }
  }

  /// Fallback method untuk mendapatkan customers langsung dari unit_assets
  Future<List<String>> _getCustomersFallback(String branch) async {
    try {
      developer.log('🔄 USING FALLBACK CUSTOMERS QUERY FOR BRANCH: $branch');

      // Fetch semua units dan filter customers
      final units = await fetchUnitsByBranch(branch);
      final customers =
          units
              .where(
                (unit) => unit.customer != null && unit.customer!.isNotEmpty,
              )
              .map((unit) => unit.customer!)
              .toSet()
              .toList()
            ..sort();

      developer.log(
        '✅ FOUND ${customers.length} CUSTOMERS FROM FALLBACK QUERY',
      );
      return customers;
    } catch (e) {
      developer.log('❌ FALLBACK CUSTOMERS QUERY ALSO FAILED: $e');
      return [];
    }
  }

  /// Get unique locations by customer and branch
  Future<List<String>> getLocationsByCustomer(
    String customer,
    String branch,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=get_locations&customer=${Uri.encodeComponent(customer)}&branch=${Uri.encodeComponent(branch)}',
      );
      developer.log('=== FETCHING LOCATIONS FOR CUSTOMER: $customer ===');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);
        developer.log('Parsed locations response: $parsed');

        // Handle different response formats
        if (parsed['success'] == true) {
          if (parsed['data'] != null && parsed['data']['locations'] is List) {
            // Format: {"success":true,"data":{"locations":[...]}}
            final locations = (parsed['data']['locations'] as List)
                .map((e) => e.toString())
                .where((location) => location.isNotEmpty)
                .toList();
            developer.log(
              '=== FOUND ${locations.length} LOCATIONS FROM DATA KEY ===',
            );
            return locations;
          } else if (parsed['locations'] is List) {
            // Format: {"success":true,"locations":[...]}
            final locations = (parsed['locations'] as List)
                .map((e) => e.toString())
                .where((location) => location.isNotEmpty)
                .toList();
            developer.log(
              '=== FOUND ${locations.length} LOCATIONS FROM ROOT KEY ===',
            );
            return locations;
          }
        } else if (parsed['ok'] == true && parsed['locations'] is List) {
          // Format: {"ok":true,"locations":[...]}
          final locations = (parsed['locations'] as List)
              .map((e) => e.toString())
              .where((location) => location.isNotEmpty)
              .toList();
          developer.log(
            '=== FOUND ${locations.length} LOCATIONS FROM OK FORMAT ===',
          );
          return locations;
        }
      }

      developer.log('=== NO LOCATIONS FOUND OR INVALID FORMAT ===');
      return [];
    } catch (e) {
      developer.log('=== GET LOCATIONS ERROR ===');
      developer.log('Error: $e');
      return [];
    }
  }

  /// Get units by customer and location
  Future<List<Map<String, dynamic>>> getUnitsByCustomerLocation(
    String customer,
    String location,
    String branch,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/penarikan/penarikan_api.php?action=get_units&customer=${Uri.encodeComponent(customer)}&location=${Uri.encodeComponent(location)}&branch=${Uri.encodeComponent(branch)}',
      );
      developer.log(
        '=== FETCHING UNITS FOR CUSTOMER: $customer, LOCATION: $location, BRANCH: $branch ===',
      );

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);
        developer.log('Parsed units response: $parsed');

        // Handle different response formats
        if (parsed['success'] == true) {
          if (parsed['data'] != null && parsed['data']['units'] is List) {
            // Format: {"success":true,"data":{"units":[...]}}
            final units = (parsed['data']['units'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            developer.log('=== FOUND ${units.length} UNITS FROM DATA KEY ===');
            return units;
          } else if (parsed['units'] is List) {
            // Format: {"success":true,"units":[...]}
            final units = (parsed['units'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            developer.log('=== FOUND ${units.length} UNITS FROM ROOT KEY ===');
            return units;
          }
        } else if (parsed['ok'] == true && parsed['units'] is List) {
          // Format: {"ok":true,"units":[...]}
          final units = (parsed['units'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          developer.log('=== FOUND ${units.length} UNITS FROM OK FORMAT ===');
          return units;
        }
      } else if (resp.statusCode == 400) {
        developer.log('❌ BAD REQUEST (400) - Check parameters');
        developer.log(
          '🔍 Customer: $customer, Location: $location, Branch: $branch',
        );
      }

      developer.log('=== NO UNITS FOUND OR INVALID FORMAT ===');
      return [];
    } catch (e) {
      developer.log('=== GET UNITS ERROR ===');
      developer.log('Error: $e');
      return [];
    }
  }
  // Di dalam class ApiService, tambahkan method ini:

  /// Fetch dashboard statistics (troubleshooting vs preventive, current vs previous month)
  Future<DashboardStats> fetchDashboardStats(String branch) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/dashboard_stats.php?branch=${Uri.encodeComponent(branch)}',
      );
      developer.log('=== FETCHING DASHBOARD STATS FOR BRANCH: $branch ===');
      developer.log('URL: $uri');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        try {
          final parsed = json.decode(resp.body);

          if (parsed is Map) {
            // Check if 'data' key exists
            if (parsed.containsKey('data') && parsed['data'] is Map) {
              return DashboardStats.fromJson(
                Map<String, dynamic>.from(parsed['data']),
              );
            } else {
              // Treat entire response as data
              return DashboardStats.fromJson(Map<String, dynamic>.from(parsed));
            }
          }

          throw Exception('Unexpected response format');
        } catch (e) {
          developer.log('=== PARSE ERROR ===');
          developer.log('Error: $e');
          throw Exception('Failed to parse dashboard stats: $e');
        }
      } else {
        throw Exception('Failed to fetch dashboard stats: ${resp.statusCode}');
      }
    } catch (e) {
      developer.log('=== FETCH DASHBOARD STATS ERROR ===');
      developer.log('Error: $e');
      // Return default stats jika error
      return DashboardStats(
        currentMonthTroubleshooting: 0,
        currentMonthPreventive: 0,
        previousMonthTroubleshooting: 0,
        previousMonthPreventive: 0,
        totalUnits: 0,
        sudahPM: 0,
        belumPM: 0,
        pmPercentage: 0,
        currentMonthName: 'Current',
        previousMonthName: 'Previous',
      );
    }
  }

  // ===== BATTERY METHODS =====

  Future<List<Battery>> fetchBattery() async {
    try {
      final uri = Uri.parse('$baseUrl/battery/battery_api.php?action=read');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['data'] is List) {
          return (parsed['data'] as List)
              .map((e) => Battery.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching battery: $e');
      return [];
    }
  }

  Future<Battery?> fetchOneBattery(int id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/battery/battery_api.php?action=read_one&id=$id',
      );
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['data'] != null) {
          return Battery.fromJson(Map<String, dynamic>.from(parsed['data']));
        }
      }
      return null;
    } catch (e) {
      developer.log('Error fetching one battery: $e');
      return null;
    }
  }

  Future<List<Battery>> fetchBatteryByBranch(String branch) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/battery/battery_api.php?action=read&branch=$branch',
      );
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['data'] is List) {
          return (parsed['data'] as List)
              .map((e) => Battery.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching battery by branch: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createBattery(Battery battery) async {
    try {
      final uri = Uri.parse('$baseUrl/battery/battery_api.php?action=create');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(battery.toJson()),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to create battery'};
    } catch (e) {
      developer.log('Error creating battery: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBattery(Battery battery) async {
    try {
      final uri = Uri.parse('$baseUrl/battery/battery_api.php?action=update');
      final resp = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(battery.toJson()),
      );

      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to update battery'};
    } catch (e) {
      developer.log('Error updating battery: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteBattery(int id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/battery/battery_api.php?action=delete&id=$id',
      );
      final resp = await http.delete(uri);

      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to delete battery'};
    } catch (e) {
      developer.log('Error deleting battery: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ===== CHARGER METHODS =====

  Future<List<Charger>> fetchCharger() async {
    try {
      final uri = Uri.parse('$baseUrl/charger/charger_api.php?action=read');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['data'] is List) {
          return (parsed['data'] as List)
              .map((e) => Charger.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching charger: $e');
      return [];
    }
  }

  Future<Charger?> fetchOneCharger(int id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/charger/charger_api.php?action=read_one&id=$id',
      );
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final parsed = json.decode(resp.body);
        if (parsed['ok'] == true && parsed['data'] != null) {
          return Charger.fromJson(Map<String, dynamic>.from(parsed['data']));
        }
      }
      return null;
    } catch (e) {
      developer.log('Error fetching one charger: $e');
      return null;
    }
  }

  Future<List<Charger>> fetchChargerByBranch(String branch) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/charger/charger_api.php?action=read&branch=${Uri.encodeComponent(branch)}',
      );
      developer.log('=== FETCHING CHARGERS BY BRANCH: $branch ===');

      final resp = await http.get(uri);
      developer.log('Response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        try {
          final parsed = json.decode(resp.body);
          if (parsed['ok'] == true && parsed['data'] is List) {
            final chargers = (parsed['data'] as List)
                .map((e) => Charger.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            developer.log(
              '=== SUCCESSFULLY PARSED ${chargers.length} CHARGERS FOR BRANCH: $branch ===',
            );
            return chargers;
          } else {
            developer.log(
              '=== EMPTY OR UNEXPECTED FORMAT FOR BRANCH: $branch ===',
            );
            return [];
          }
        } catch (e) {
          throw Exception('Parse error fetchChargerByBranch: $e');
        }
      } else {
        throw Exception(
          'Failed to fetch chargers by branch: ${resp.statusCode}',
        );
      }
    } catch (e) {
      developer.log('=== FETCH CHARGERS BY BRANCH ERROR ===');
      developer.log('Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createCharger(Charger charger) async {
    try {
      final uri = Uri.parse('$baseUrl/charger/charger_api.php?action=create');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(charger.toJson()),
      );

      developer.log('>>> CREATE CHARGER POST $uri');
      developer.log('<<< Response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to create charger'};
    } catch (e) {
      developer.log('Error creating charger: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCharger(Charger charger) async {
    try {
      final uri = Uri.parse('$baseUrl/charger/charger_api.php?action=update');
      final resp = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(charger.toJson()),
      );

      developer.log('>>> UPDATE CHARGER PUT $uri');
      developer.log('<<< Response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to update charger'};
    } catch (e) {
      developer.log('Error updating charger: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteCharger(int id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/charger/charger_api.php?action=delete&id=$id',
      );
      final resp = await http.delete(uri);

      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'ok': false, 'message': 'Failed to delete charger'};
    } catch (e) {
      developer.log('Error deleting charger: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ===================================
  // ===== DELIVERY UNITS METHODS ======
  // ===================================

  // 1. READ (Fetch List of Delivery Units)
  Future<List<Delivery>> fetchDelivery({String? branch}) async {
    final client = http.Client();
    final url = branch == null
        ? '$baseUrl${AppConstants.deliveryEndpoint}?action=read'
        : '$baseUrl${AppConstants.deliveryEndpoint}?action=read&branch=$branch';

    developer.log('DEBUG: GET $url');
    try {
      final response = await client
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      developer.log('DEBUG: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map((item) => Delivery.fromJson(item as Map<String, dynamic>))
              .toList();
          return list;
        } else {
          throw Exception(data['message'] ?? 'Failed to load delivery data');
        }
      } else {
        throw Exception(
          'Failed to load delivery data. Status Code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timeout.');
    } catch (e) {
      developer.log('ERROR: fetchDelivery failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 2. CREATE
  Future<Map<String, dynamic>> createDelivery(Delivery delivery) async {
    final client = http.Client();
    final url = '$baseUrl${AppConstants.deliveryEndpoint}?action=create';

    developer.log('DEBUG: POST $url');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: _getHeaders(),
            body: json.encode(delivery.toJson()),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      developer.log('DEBUG: status=${response.statusCode}');
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create delivery');
      }
    } on TimeoutException {
      throw Exception('Request timeout.');
    } catch (e) {
      developer.log('ERROR: createDelivery failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 3. UPDATE
  Future<Map<String, dynamic>> updateDelivery(Delivery delivery) async {
    final client = http.Client();
    final url = '$baseUrl${AppConstants.deliveryEndpoint}?action=update';

    developer.log('DEBUG: POST $url');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: _getHeaders(),
            body: json.encode(delivery.toJson()),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      developer.log('DEBUG: status=${response.statusCode}');
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update delivery');
      }
    } on TimeoutException {
      throw Exception('Request timeout.');
    } catch (e) {
      developer.log('ERROR: updateDelivery failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 4. DELETE
  Future<bool> deleteDelivery(String id) async {
    final client = http.Client();
    final url = '$baseUrl${AppConstants.deliveryEndpoint}?action=delete';

    developer.log('DEBUG: POST $url');
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: _getHeaders(),
            body: json.encode({'id': id}),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      developer.log('DEBUG: status=${response.statusCode}');
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete delivery');
      }
    } on TimeoutException {
      throw Exception('Request timeout.');
    } catch (e) {
      developer.log('ERROR: deleteDelivery failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 5. HELPER: Generate Unique ID
  // Method generateDeliveryId() yang DIPERBAIKI
  // Baris ~1040
  Future<String> generateDeliveryId() async {
    final now = DateTime.now();
    final random = Random();

    // Format: DL + YYMMDDHHmmss + 3 digit random
    // Contoh: DL251115174532847
    final timestamp =
        '${now.year.toString().substring(2)}' // 25
        '${now.month.toString().padLeft(2, '0')}' // 11
        '${now.day.toString().padLeft(2, '0')}' // 15
        '${now.hour.toString().padLeft(2, '0')}' // 17
        '${now.minute.toString().padLeft(2, '0')}' // 45
        '${now.second.toString().padLeft(2, '0')}'; // 32

    // Tambah 3 digit random untuk extra uniqueness (000-999)
    final randomSuffix = random.nextInt(1000).toString().padLeft(3, '0');

    final deliveryId = 'DL$timestamp$randomSuffix';

    developer.log('✅ Generated Random Delivery ID: $deliveryId');
    return deliveryId;
  }

  // 6. HELPER: Get Customer List
  Future<List<String>> getDeliveryCustomers({required String branch}) async {
    final client = http.Client();
    final url =
        '$baseUrl${AppConstants.deliveryEndpoint}?action=get_customers&branch=$branch';

    developer.log('DEBUG: GET $url');
    try {
      final response = await client
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          return List<String>.from(data['data'] as List);
        } else {
          throw Exception(data['message'] ?? 'Failed to load customers');
        }
      } else {
        throw Exception(
          'Failed to load customers. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('ERROR: getDeliveryCustomers failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 7. HELPER: Get Location List
  Future<List<String>> getDeliveryLocations({required String customer}) async {
    final client = http.Client();
    final url =
        '$baseUrl${AppConstants.deliveryEndpoint}?action=get_locations&customer=$customer';

    developer.log('DEBUG: GET $url');
    try {
      final response = await client
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          return List<String>.from(data['data'] as List);
        } else {
          throw Exception(data['message'] ?? 'Failed to load locations');
        }
      } else {
        throw Exception(
          'Failed to load locations. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('ERROR: getDeliveryLocations failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // 8. HELPER: Get Unit List
  Future<List<Map<String, dynamic>>> getDeliveryUnits({
    required String customer,
    required String location,
  }) async {
    final client = http.Client();
    final url =
        '$baseUrl${AppConstants.deliveryEndpoint}?action=get_units&customer=$customer&location=$location';

    developer.log('DEBUG: GET $url');
    try {
      final response = await client
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          // Mengembalikan List<Map<String, dynamic>> karena Unit model mungkin belum tersedia/diperlukan di sini.
          return List<Map<String, dynamic>>.from(data['data'] as List);
        } else {
          throw Exception(data['message'] ?? 'Failed to load units');
        }
      } else {
        throw Exception(
          'Failed to load units. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('ERROR: getDeliveryUnits failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
  // ===== PROFILE & ACCOUNT METHODS =====

  /// Change user password - IMPROVED VERSION
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String nrpp,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.changePasswordEndpoint}');

      developer.log('>>> CHANGE PASSWORD POST $uri');
      developer.log('>>> User ID: $userId, NRPP: $nrpp');

      final body = json.encode({
        'user_id': userId,
        'nrpp': nrpp,
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      developer.log('<<< CHANGE PASSWORD -> status=${resp.statusCode}');
      developer.log('<<< Response body: ${resp.body}');

      // Parse response
      final Map<String, dynamic> responseBody;
      try {
        responseBody = json.decode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        developer.log('!!! JSON Parse Error: $e');
        return {
          'ok': false,
          'statusCode': resp.statusCode,
          'message': 'Invalid response from server',
          'body': resp.body,
        };
      }

      final bool success = responseBody['success'] == true;

      return {
        'ok': success,
        'statusCode': resp.statusCode,
        'message':
            responseBody['message']?.toString() ??
            (success
                ? 'Password changed successfully'
                : 'Failed to change password'),
        'body': resp.body,
        'data': responseBody['data'],
      };
    } on http.ClientException catch (e) {
      developer.log('!!! Network Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Network error: ${e.message}',
        'body': '',
      };
    } on TimeoutException catch (e) {
      developer.log('!!! Timeout Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Request timeout. Please try again.',
        'body': '',
      };
    } catch (e) {
      developer.log('!!! Unexpected Error: $e');
      return {
        'ok': false,
        'statusCode': 0,
        'message': 'Unexpected error: $e',
        'body': '',
      };
    }
  }
}
