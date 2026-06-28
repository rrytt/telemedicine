import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../admin_theme.dart';
import '../controllers/admin_controller.dart';

class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());

    return Scaffold(
      body: Container(
        decoration: AdminStyles.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(child: Obx(() => _buildList(controller))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AdminStyles.textPrimary),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          Text(
            'Complaints',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AdminStyles.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildList(AdminController controller) {
    if (controller.isLoadingComplaints.value) {
      return Center(
        child: CircularProgressIndicator(color: AdminStyles.navy),
      );
    }

    if (controller.complaintsError.value.isNotEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminStyles.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            controller.complaintsError.value,
            style: TextStyle(color: AdminStyles.danger, fontSize: 13),
          ),
        ),
      );
    }

    if (controller.complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 56, color: AdminStyles.success),
            SizedBox(height: 12),
            Text('No complaints', style: TextStyle(
              color: AdminStyles.slate, fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadComplaints(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.complaints.length,
        itemBuilder: (BuildContext context, int index) {
          final complaint = controller.complaints[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(18),
            decoration: AdminStyles.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AdminStyles.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(complaint.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(Icons.person_rounded, size: 14, color: AdminStyles.slate),
                    const SizedBox(width: 4),
                    Text(
                      complaint.patientName,
                      style: TextStyle(fontSize: 12, color: AdminStyles.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.medical_services_rounded, size: 14, color: AdminStyles.slate),
                    const SizedBox(width: 4),
                    Text(
                      complaint.doctorName ?? '-',
                      style: TextStyle(fontSize: 12, color: AdminStyles.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  complaint.body,
                  style: TextStyle(color: AdminStyles.textPrimary, fontSize: 13),
                ),
                if ((complaint.adminResponse ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminStyles.navy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminStyles.border),
                    ),
                    child: Text(
                      'Admin response: ${complaint.adminResponse}',
                      style: TextStyle(
                        color: AdminStyles.textPrimary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        initialValue: complaint.status,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AdminStyles.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AdminStyles.border),
                          ),
                          filled: true,
                          fillColor: AdminStyles.surface,
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'open', child: Text('open', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'in_review', child: Text('in_review', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'resolved', child: Text('resolved', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'rejected', child: Text('rejected', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (String? value) {
                          if (value != null && value != complaint.status) {
                            controller.updateComplaintStatus(complaint.id, value);
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showRespondDialog(context, controller, complaint.id),
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: const Text('Respond', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminStyles.navy,
                        side: BorderSide(color: AdminStyles.navy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'open':
        bg = AdminStyles.danger.withValues(alpha: 0.12);
        fg = AdminStyles.danger;
        break;
      case 'in_review':
        bg = AdminStyles.warning.withValues(alpha: 0.12);
        fg = AdminStyles.warning;
        break;
      case 'resolved':
        bg = AdminStyles.success.withValues(alpha: 0.12);
        fg = AdminStyles.success;
        break;
      case 'rejected':
        bg = AdminStyles.slate.withValues(alpha: 0.12);
        fg = AdminStyles.slate;
        break;
      default:
        bg = AdminStyles.slate.withValues(alpha: 0.12);
        fg = AdminStyles.slate;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Future<void> _showRespondDialog(
    BuildContext context,
    AdminController controller,
    String complaintId,
  ) async {
    final TextEditingController textController = TextEditingController();

    final bool? save = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Respond to Complaint',
          style: TextStyle(fontWeight: FontWeight.w700, color: AdminStyles.textPrimary),
        ),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: AdminStyles.inputDecoration(
            label: 'Admin response',
            hint: 'Type your response...',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: AdminStyles.slate)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyles.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true) {
      await controller.respondToComplaint(complaintId, textController.text);
    }
  }
}
