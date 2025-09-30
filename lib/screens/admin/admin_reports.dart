import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // For mobile sharing

import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'admin_shell.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  final AdminRepository _repo = AdminRepository();
  String? _selectedReportType;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  void _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedReportType == null) {
      _showError("Please select a report type.");
      return;
    }
    if (_selectedDateRange == null) {
      _showError("Please select a date range.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> data = [];
      List<String> headers = [];

      switch (_selectedReportType) {
        case 'User Activity':
          headers = ['UserID', 'Name', 'Email', 'Role', 'Registered On'];
          data = await _repo.getUserActivityReport(_selectedDateRange!);
          break;
        case 'Content Status':
          headers = ['TopicID', 'Title', 'Author', 'Status', 'Category', 'Level', 'Last Updated'];
          data = await _repo.getContentStatusReport(_selectedDateRange!);
          break;
        case 'System Logs':
          headers = ['Timestamp', 'Type', 'Title', 'Message'];
          data = await _repo.getSystemLogsReport(_selectedDateRange!);
          break;
      }
      _showReportDialog(data, headers);
    } catch (e) {
      _showError("Failed to generate report: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReportDialog(List<Map<String, dynamic>> data, List<String> headers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report: $_selectedReportType'),
        content: SizedBox(
          width: double.maxFinite,
          child: data.isEmpty
              ? const Center(child: Text("No data found for the selected criteria."))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                rows: data.map((row) {
                  return DataRow(
                    cells: headers.map((header) {
                      dynamic value = row[header];
                      if (value is Timestamp) {
                        value = DateFormat('yyyy-MM-dd').format(value.toDate());
                      }
                      return DataCell(Text(value?.toString() ?? 'N/A'));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          if (data.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Download CSV"),
              onPressed: () => _downloadCsv(data, headers),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCsv(List<Map<String, dynamic>> data, List<String> headers) async {
    try {
      // Step 1: Build CSV data
      List<List<dynamic>> rows = [];
      rows.add(headers);

      for (var row in data) {
        List<dynamic> rowData = headers.map((header) {
          dynamic value = row[header];
          if (value is Timestamp) {
            return DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toDate());
          }
          return value?.toString() ?? 'N/A';
        }).toList();
        rows.add(rowData);
      }

      final String csv = const ListToCsvConverter().convert(rows);
      final String fileName =
          "${_selectedReportType!.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";

      // Step 2: Ask user what to do
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Download Options"),
          content: const Text("Would you like to save the file, share it, or do both?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text("Save Only")),
            TextButton(onPressed: () => Navigator.pop(context, 'share'), child: const Text("Share Only")),
            TextButton(onPressed: () => Navigator.pop(context, 'both'), child: const Text("Save & Share")),
          ],
        ),
      );

      if (choice == null) return;

      // Step 3: Handle permissions (Android only)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError("Storage permission denied. Please grant permission and try again.");
          return;
        }
      }

      // Step 4: Get Downloads folder path
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final String filePath = "${downloadsDir.path}/$fileName";
      final file = File(filePath);

      // Step 5: Save the file
      await file.writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved successfully at:\n$filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Step 6: Handle Share logic
      final XFile xfile = XFile(file.path, mimeType: 'text/csv', name: fileName);

      if (choice == 'share') {
        await Share.shareXFiles([xfile], text: '$_selectedReportType Report');
      } else if (choice == 'both') {
        await Share.shareXFiles([xfile], text: '$_selectedReportType Report');
      }

    } catch (e) {
      _showError("Failed to download CSV: $e");
    }
  }



  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth * 0.9 : 300.0;

    return AdminShell(
      title: "Reports",
      currentIndex: 6,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("System Reports", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text("Generate and download reports for users, content, and system activity.", style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Step 1: Select Report Type
            Text("1. Select Report Type", style: AppTextStyles.subHeading.copyWith(fontSize: 18)),
            const SizedBox(height: 12),

            // Centered selection buttons with consistent sizing
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildReportCard("User Activity", Icons.people, AppColors.primary),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildReportCard("Content Status", Icons.article, AppColors.secondary),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildReportCard("System Logs", Icons.history, AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Select Date Range
            Text("2. Select Date Range", style: AppTextStyles.subHeading.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDateRange == null
                              ? "Click to select date range"
                              : "${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}",
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Step 3: Generate Report Button
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text("Generate Report"),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color) {
    final bool isSelected = _selectedReportType == title;
    return Card(
      color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReportType = title;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.midFont.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}