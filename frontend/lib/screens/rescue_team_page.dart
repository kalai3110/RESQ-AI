import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

// ============================================================
// RESQ AI
// RESCUE TEAM PAGE
// Smart Response. Safer Communities.
// ============================================================

class RescueTeamPage extends StatefulWidget {
  final int teamId;

  const RescueTeamPage({
    super.key,
    required this.teamId,
  });

  @override
  State<RescueTeamPage> createState() => _RescueTeamPageState();
}

// ============================================================
// RESCUE TEAM HOME
// ============================================================

class _RescueTeamPageState extends State<RescueTeamPage> {
  final FlutterSecureStorage secure =
      const FlutterSecureStorage();

  static const String baseUrl =
    'https://backend-h003ewnzr-kalai3110s-projects.vercel.app/api';

  Map<String, dynamic>? team;

  Map<String, dynamic>? assignedReport;

  List<Map<String, dynamic>> notifications = [];

  List<Map<String, dynamic>> completedReports = [];

  Set<int> readNotificationIds = {};

  bool loading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadReadNotificationIds();
    loadTeam();
    loadNotifications();
    loadCompletedReports();
  }

  // ============================================================
  // LOAD READ NOTIFICATION IDS
  // ============================================================

  Future<void> loadReadNotificationIds() async {
    try {
      final value = await secure.read(
        key: 'read_notification_ids',
      );

      if (value == null || value.isEmpty) {
        return;
      }

      final decoded = jsonDecode(value);

      if (decoded is List) {
        if (!mounted) return;

        setState(() {
          readNotificationIds = decoded
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toSet();
        });
      }
    } catch (e) {
      debugPrint(
        'READ NOTIFICATIONS ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE READ NOTIFICATION IDS
  // ============================================================

  Future<void> saveReadNotificationIds() async {
    try {
      await secure.write(
        key: 'read_notification_ids',
        value: jsonEncode(
          readNotificationIds.toList(),
        ),
      );
    } catch (e) {
      debugPrint(
        'SAVE READ NOTIFICATIONS ERROR: $e',
      );
    }
  }

  // ============================================================
  // LOAD TEAM
  // ============================================================

  Future<void> loadTeam() async {
    try {
      final token = await secure.read(
        key: 'token',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/rescue/teams',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'TEAMS STATUS: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      if (data is! Map ||
          data['success'] != true ||
          data['teams'] is! List) {
        return;
      }

      final teams = (data['teams'] as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();

      Map<String, dynamic>? foundTeam;

      for (final item in teams) {
        final id = int.tryParse(
          item['id']?.toString() ?? '',
        );

        if (id == widget.teamId) {
          foundTeam = item;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        team = foundTeam;

        if (foundTeam != null &&
            foundTeam['assigned_disaster'] is Map) {
          assignedReport =
              Map<String, dynamic>.from(
            foundTeam['assigned_disaster'],
          );
        } else {
          assignedReport = null;
        }

        loading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint(
        'LOAD TEAM ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> loadNotifications() async {
    try {
      final token = await secure.read(
        key: 'token',
      );

      final userIdString = await secure.read(
        key: 'user_id',
      );

      final userId = int.tryParse(
        userIdString ?? '',
      );

      if (userId == null) {
        debugPrint(
          'USER ID NOT FOUND',
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/rescue/notifications/$userId',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'NOTIFICATIONS STATUS: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      if (data is Map &&
          data['success'] == true &&
          data['notifications'] is List) {
        final list = (data['notifications'] as List)
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        if (!mounted) return;

        setState(() {
          notifications = list;
        });
      }
    } catch (e) {
      debugPrint(
        'NOTIFICATIONS ERROR: $e',
      );
    }
  }

  // ============================================================
  // LOAD COMPLETED REPORTS
  // ============================================================

  Future<void> loadCompletedReports() async {
    try {
      final token = await secure.read(
        key: 'token',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/rescue/completed-reports/${widget.teamId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'COMPLETED REPORTS STATUS: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      if (data is Map &&
          data['success'] == true &&
          data['reports'] is List) {
        final list = (data['reports'] as List)
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        if (!mounted) return;

        setState(() {
          completedReports = list;
        });
      }
    } catch (e) {
      debugPrint(
        'COMPLETED REPORTS ERROR: $e',
      );
    }
  }

  // ============================================================
  // OPEN NOTIFICATION REPORT
  // ============================================================

  Future<void> _openNotificationReport(
    Map<String, dynamic> notification,
  ) async {
    final reportId = notification['report_id'];

    if (reportId == null) {
      return;
    }

    final id = int.tryParse(
      reportId.toString(),
    );

    if (id == null) {
      return;
    }

    final notificationId = int.tryParse(
      notification['id']?.toString() ?? '',
    );

    if (notificationId != null) {
      setState(() {
        readNotificationIds.add(notificationId);
      });

      await saveReadNotificationIds();
    }

    if (!mounted) return;

    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RescueReportPage(
          teamId: widget.teamId,
          reportId: id,
          notificationReport:
              notification['report'] is Map
                  ? Map<String, dynamic>.from(
                      notification['report'],
                    )
                  : null,
          onStatusChanged: () async {
            await loadTeam();
            await loadNotifications();
            await loadCompletedReports();
          },
        ),
      ),
    );

    await loadTeam();
    await loadNotifications();
    await loadCompletedReports();
  }

  // ============================================================
  // NOTIFICATION COUNT
  // ============================================================

  int get unreadCount {
    return notifications.where((notification) {
      final id = int.tryParse(
        notification['id']?.toString() ?? '',
      );

      if (id == null) {
        return false;
      }

      return !readNotificationIds.contains(id);
    }).length;
  }

  // ============================================================
  // SHOW NOTIFICATIONS
  // ============================================================

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.70,
            child: Column(
              children: [
                const SizedBox(height: 15),

                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: notifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              notifications.length,
                          itemBuilder:
                              (context, index) {
                            final notification =
                                notifications[index];

                            final id =
                                int.tryParse(
                              notification['id']
                                      ?.toString() ??
                                  '',
                            );

                            final isRead =
                                id != null &&
                                    readNotificationIds
                                        .contains(id);

                            return ListTile(
                              leading:
                                  CircleAvatar(
                                backgroundColor:
                                    isRead
                                        ? Colors
                                            .grey
                                            .shade200
                                        : Colors
                                            .orange
                                            .withOpacity(
                                            0.12,
                                          ),
                                child: Icon(
                                  Icons.notifications,
                                  color: isRead
                                      ? Colors.grey
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(
                                notification['title']
                                        ?.toString() ??
                                    'Rescue Notification',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                notification['message']
                                        ?.toString() ??
                                    '',
                              ),
                              onTap: () {
                                _openNotificationReport(
                                  notification,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await secure.delete(key: 'token');
    await secure.delete(key: 'user_id');
    await secure.delete(key: 'user_role');
    await secure.delete(key: 'user_name');
    await secure.delete(key: 'user_email');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // TEAM STATUS
  // ============================================================

  String get teamStatus {
    return team?['status']?.toString() ??
        'Available';
  }

  String get teamName {
    return team?['team_name']?.toString() ??
        'Rescue Team';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Text(
          'RESQ AI',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 27,
                ),
                onPressed: _showNotifications,
              ),

              if (unreadCount > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.all(4),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9
                          ? '9+'
                          : unreadCount.toString(),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black87,
            ),
            onPressed: logout,
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await loadTeam();
                await loadNotifications();
                await loadCompletedReports();
              },
              child: _buildHome(),
            ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ======================================================
        // TEAM CARD
        // ======================================================

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  Colors.grey.withOpacity(0.18),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFE0F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups,
                  size: 44,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                teamName,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              _statusChip(teamStatus),

              const SizedBox(height: 12),

              if (teamStatus == 'Available')
                const Text(
                  'Waiting for new assignment',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              else
                Text(
                  'Current status: $teamStatus',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ======================================================
        // ASSIGNED REPORTS HEADER
        // ======================================================

        Row(
          children: [
            const Icon(
              Icons.assignment_outlined,
              color: Colors.orange,
              size: 24,
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                'Assigned Reports',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.orange
                    .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                assignedReport == null
                    ? '0'
                    : '1',
                style:
                    const TextStyle(
                  color: Colors.orange,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ======================================================
        // ASSIGNED REPORT
        // ======================================================

        if (assignedReport == null)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey
                    .withOpacity(0.18),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 52,
                  color: Colors.grey,
                ),

                SizedBox(height: 12),

                Text(
                  'No assigned reports.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          _assignedReportCard(
            assignedReport!,
          ),

        const SizedBox(height: 28),

        // ======================================================
        // COMPLETED REPORTS HEADER
        // ======================================================

        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 24,
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                'Completed Reports',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                completedReports.length
                    .toString(),
                style:
                    const TextStyle(
                  color: Colors.green,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ======================================================
        // COMPLETED REPORTS
        // ======================================================

        if (completedReports.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey
                    .withOpacity(0.18),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons
                      .assignment_turned_in_outlined,
                  size: 52,
                  color: Colors.grey,
                ),

                SizedBox(height: 12),

                Text(
                  'No completed reports yet.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...completedReports.map(
            (report) =>
                _completedReportCard(report),
          ),
      ],
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case 'Assigned':
        color = Colors.orange;
        break;

      case 'Preparing':
        color = Colors.amber;
        break;

      case 'On the Way':
        color = Colors.blue;
        break;

      case 'Reached':
        color = Colors.purple;
        break;

      case 'Completed':
        color = Colors.green;
        break;

      default:
        color = Colors.green;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 7),

          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIORITY CHIP
  // ============================================================

  Widget _priorityChip(
    String priority,
  ) {
    Color color;

    switch (priority.toUpperCase()) {
      case 'CRITICAL':
      case 'P1':
        color = Colors.red;
        break;

      case 'HIGH':
      case 'P2':
        color = Colors.orange;
        break;

      case 'MEDIUM':
      case 'P3':
        color = Colors.amber.shade800;
        break;

      default:
        color = Colors.green;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNED REPORT CARD
  // ============================================================

  Widget _assignedReportCard(
    Map<String, dynamic> report,
  ) {
    final reportId =
        report['id']?.toString() ?? 'N/A';

    final disaster =
        report['disaster_type']?.toString() ??
            'Emergency';

    final district =
        report['district']?.toString() ??
            'Unknown';

    final area =
        report['area']?.toString() ?? '';

    final address =
        report['address']?.toString() ??
            report['landmark']?.toString() ??
            'Not provided';

    final affected =
        report['people_affected']
                ?.toString() ??
            report['affected_people']
                ?.toString() ??
            report['affectedPeople']
                ?.toString() ??
            'N/A';

    final priority =
        report['priority']?.toString() ??
            report['severity']?.toString() ??
            'N/A';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color:
              Colors.orange.withOpacity(
            0.25,
          ),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: Colors.orange
                        .withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Report #$reportId',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        disaster,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusChip(
                  teamStatus,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                const Text(
                  'Priority: ',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                _priorityChip(
                  priority,
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 14),

            const Text(
              'Incident Details',
              style:
                  TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _assignedDetailRow(
              'District',
              district,
            ),

            if (area.isNotEmpty)
              _assignedDetailRow(
                'Area',
                area,
              ),

            _assignedDetailRow(
              'Address / Landmark',
              address,
            ),

            _assignedDetailRow(
              'Affected People',
              affected,
            ),

            _assignedDetailRow(
              'Status',
              teamStatus,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child:
                  OutlinedButton.icon(
                onPressed: () async {
                  final id =
                      int.tryParse(
                    reportId,
                  );

                  if (id == null) {
                    return;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RescueReportPage(
                        teamId:
                            widget.teamId,
                        reportId: id,
                        notificationReport:
                            report,
                        onStatusChanged:
                            () async {
                          await loadTeam();
                          await loadNotifications();
                          await loadCompletedReports();
                        },
                      ),
                    ),
                  );

                  await loadTeam();
                  await loadNotifications();
                  await loadCompletedReports();
                },
                icon: const Icon(
                  Icons.open_in_new,
                  size: 18,
                ),
                label: const Text(
                  'VIEW FULL REPORT',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNED DETAIL ROW
  // ============================================================

  Widget _assignedDetailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED REPORT CARD
  // ============================================================

  Widget _completedReportCard(
    Map<String, dynamic> report,
  ) {
    final reportId =
        report['id']?.toString() ?? 'N/A';

    final disaster =
        report['disaster_type']?.toString() ??
            'Emergency';

    final district =
        report['district']?.toString() ??
            'Unknown';

    final address =
        report['address']?.toString() ??
            report['landmark']?.toString() ??
            'Not provided';

    final affected =
        report['people_affected']
                ?.toString() ??
            report['affected_people']
                ?.toString() ??
            report['affectedPeople']
                ?.toString() ??
            'N/A';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color:
              Colors.green.withOpacity(
            0.20,
          ),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color: Colors.green
                        .withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .check_circle_outline,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Report #$reportId',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        disaster,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusChip(
                  'Completed',
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 12),

            _assignedDetailRow(
              'District',
              district,
            ),

            _assignedDetailRow(
              'Address / Landmark',
              address,
            ),

            _assignedDetailRow(
              'Affected People',
              affected,
            ),

            if (report['completed_at'] !=
                null)
              _assignedDetailRow(
                'Completed At',
                report['completed_at']
                    .toString()
                    .replaceFirst(
                      'T',
                      ' ',
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RESCUE REPORT PAGE
// ============================================================

class RescueReportPage
    extends StatefulWidget {
  final int teamId;

  final int reportId;

  final Map<String, dynamic>?
      notificationReport;

  final Future<void> Function()
      onStatusChanged;

  const RescueReportPage({
    super.key,
    required this.teamId,
    required this.reportId,
    this.notificationReport,
    required this.onStatusChanged,
  });

  @override
  State<RescueReportPage> createState() =>
      _RescueReportPageState();
}

// ============================================================
// REPORT PAGE STATE
// ============================================================

class _RescueReportPageState
    extends State<RescueReportPage> {
  final FlutterSecureStorage secure =
      const FlutterSecureStorage();

  static const String baseUrl =
    'https://backend-h003ewnzr-kalai3110s-projects.vercel.app/api';
  Map<String, dynamic>? report;

  String teamStatus = 'Assigned';

  bool loading = true;

  bool updating = false;

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.notificationReport != null) {
      report = widget.notificationReport;
      loading = false;
      loadCurrentTeamStatus();
    } else {
      loadReport();
    }
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> loadReport() async {
    try {
      final token = await secure.read(
        key: 'token',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/disaster/reports/${widget.reportId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'REPORT STATUS: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          loading = false;
          errorMessage =
              'Unable to load report.';
        });

        return;
      }

      final data = jsonDecode(
        response.body,
      );

      if (data is Map &&
          data['success'] == true) {
        Map<String, dynamic>? reportData;

        if (data['report'] is Map) {
          reportData =
              Map<String, dynamic>.from(
            data['report'],
          );
        }

        if (mounted) {
          setState(() {
            report = reportData;
            loading = false;
            errorMessage = null;
          });
        }

        await loadCurrentTeamStatus();
      }
    } catch (e) {
      debugPrint(
        'LOAD REPORT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD CURRENT TEAM STATUS
  // ============================================================

  Future<void> loadCurrentTeamStatus() async {
    try {
      final token = await secure.read(
        key: 'token',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/rescue/teams',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(
        response.body,
      );

      if (data is! Map ||
          data['teams'] is! List) {
        return;
      }

      for (final item in data['teams']) {
        if (item is! Map) {
          continue;
        }

        final id = int.tryParse(
          item['id']?.toString() ?? '',
        );

        if (id == widget.teamId) {
          if (!mounted) return;

          setState(() {
            teamStatus =
                item['status']?.toString() ??
                    'Assigned';
          });

          break;
        }
      }
    } catch (e) {
      debugPrint(
        'LOAD TEAM STATUS ERROR: $e',
      );
    }
  }

  // ============================================================
  // UPDATE TEAM STATUS
  // ============================================================

  Future<void> updateStatus(
    String newStatus,
  ) async {
    if (updating) {
      return;
    }

    if (!mounted) return;

    setState(() {
      updating = true;
    });

    try {
      final token = await secure.read(
        key: 'token',
      );

      final response = await http.patch(
        Uri.parse(
          '$baseUrl/rescue/teams/${widget.teamId}/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': newStatus,
        }),
      );

      debugPrint(
        'UPDATE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'UPDATE STATUS BODY: ${response.body}',
      );

      final data = jsonDecode(
        response.body,
      );

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        if (mounted) {
          setState(() {
            teamStatus = newStatus;
          });
        }

        await widget.onStatusChanged();

        if (newStatus == 'Completed') {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Response completed successfully.',
              ),
              backgroundColor:
                  Colors.green,
            ),
          );

          Navigator.pop(context);
          return;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to $newStatus',
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              data is Map
                  ? data['message']
                          ?.toString() ??
                      'Failed to update status.'
                  : 'Failed to update status.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'UPDATE STATUS ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          updating = false;
        });
      }
    }
  }

  // ============================================================
  // NEXT STATUS
  // ============================================================

  String? get nextStatus {
    switch (teamStatus) {
      case 'Assigned':
        return 'On the Way';

      case 'On the Way':
        return 'Reached';

      case 'Reached':
        return 'Completed';

      default:
        return null;
    }
  }

  // ============================================================
  // NEXT BUTTON TEXT
  // ============================================================

  String get nextButtonText {
    switch (teamStatus) {
      case 'Assigned':
        return 'START RESPONSE';

      case 'On the Way':
        return 'MARK REACHED';

      case 'Reached':
        return 'COMPLETE RESPONSE';

      default:
        return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Assigned Report',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 55,
                          color: Colors.red,
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        ElevatedButton(
                          onPressed: loadReport,
                          child:
                              const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildReportPage(),
    );
  }

  // ============================================================
  // REPORT CONTENT
  // ============================================================

  Widget _buildReportPage() {
    if (report == null) {
      return const Center(
        child: Text(
          'Report not found.',
        ),
      );
    }

    final reportId =
        report!['id']?.toString() ?? 'N/A';

    final disaster =
        report!['disaster_type']?.toString() ??
            'Emergency';

    final district =
        report!['district']?.toString() ??
            'Unknown';

    final area =
        report!['area']?.toString() ??
            '';

    final address =
        report!['address']?.toString() ??
            report!['landmark']?.toString() ??
            'Not provided';

    final affected =
        report!['people_affected']
                ?.toString() ??
            report!['affected_people']
                ?.toString() ??
            report!['affectedPeople']
                ?.toString() ??
            'N/A';

    final priority =
        report!['priority']?.toString() ??
            report!['severity']?.toString() ??
            'N/A';

    final status =
        report!['status']?.toString() ??
            teamStatus;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // REPORT HEADER
          // ====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey
                    .withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .warning_amber_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Report #$reportId',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            disaster,
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                Row(
                  children: [
                    const Text(
                      'Priority: ',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    _priorityChip(priority),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // LOCATION
          // ====================================================

          _detailCard(
            title: 'Location',
            icon:
                Icons.location_on_outlined,
            children: [
              _detailRow(
                'District',
                district,
              ),

              if (area.isNotEmpty)
                _detailRow(
                  'Area',
                  area,
                ),

              _detailRow(
                'Address / Landmark',
                address,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // INCIDENT DETAILS
          // ====================================================

          _detailCard(
            title: 'Incident Details',
            icon: Icons.info_outline,
            children: [
              _detailRow(
                'Affected People',
                affected,
              ),

              _detailRow(
                'Report Status',
                status,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // RESPONSE STATUS
          // ====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey
                    .withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Response Status',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                _responseTimeline(),

                const SizedBox(
                  height: 20,
                ),

                if (nextStatus != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      onPressed: updating
                          ? null
                          : () {
                              updateStatus(
                                nextStatus!,
                              );
                            },
                      icon: updating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : Icon(
                              teamStatus ==
                                      'Reached'
                                  ? Icons
                                      .check_circle
                                  : Icons
                                      .arrow_forward,
                            ),
                      label: Text(
                        updating
                            ? 'UPDATING...'
                            : nextButtonText,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            teamStatus ==
                                    'Reached'
                                ? Colors.green
                                : Colors.blue,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIORITY CHIP
  // ============================================================

  Widget _priorityChip(
    String priority,
  ) {
    Color color;

    switch (priority.toUpperCase()) {
      case 'CRITICAL':
      case 'P1':
        color = Colors.red;
        break;

      case 'HIGH':
      case 'P2':
        color = Colors.orange;
        break;

      case 'MEDIUM':
      case 'P3':
        color = Colors.amber.shade800;
        break;

      default:
        color = Colors.green;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL CARD
  // ============================================================

  Widget _detailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSE TIMELINE
  // ============================================================

  Widget _responseTimeline() {
    final steps = [
      'Assigned',
      'On the Way',
      'Reached',
      'Completed',
    ];

    int currentIndex =
        steps.indexOf(teamStatus);

    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return Column(
      children: List.generate(
        steps.length,
        (index) {
          final step = steps[index];

          final completed =
              index <= currentIndex;

          final isLast =
              index == steps.length - 1;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color: completed
                          ? Colors.green
                          : Colors.grey
                              .withOpacity(
                              0.20,
                            ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      completed
                          ? Icons.check
                          : Icons.circle,
                      size: completed
                          ? 17
                          : 8,
                      color: completed
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),

                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: index <
                              currentIndex
                          ? Colors.green
                          : Colors.grey
                              .withOpacity(
                              0.25,
                            ),
                    ),
                ],
              ),

              const SizedBox(
                width: 12,
              ),

              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 5,
                ),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: completed
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: completed
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}