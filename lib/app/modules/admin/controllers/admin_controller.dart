import 'package:get/get.dart';

import '../../../core/supabase/supabase_service.dart';

class AdminAccountItem {
  const AdminAccountItem({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isApproved,
  });

  final String id;
  final String fullName;
  final String role;
  final bool isApproved;
}

class AdminComplaintItem {
  const AdminComplaintItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.patientName,
    this.doctorName,
    this.adminResponse,
  });

  final String id;
  final String title;
  final String body;
  final String status;
  final String patientName;
  final String? doctorName;
  final String? adminResponse;
}

class AdminController extends GetxController {
  final RxList<AdminAccountItem> accounts = <AdminAccountItem>[].obs;
  final RxList<AdminComplaintItem> complaints = <AdminComplaintItem>[].obs;

  final RxBool isLoadingAccounts = false.obs;
  final RxBool isLoadingComplaints = false.obs;
  final RxString accountsError = ''.obs;
  final RxString complaintsError = ''.obs;

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
    loadComplaints();
  }

  Future<void> loadAccounts() async {
    accountsError.value = '';
    if (!SupabaseService.isConfigured) {
      accountsError.value = 'Supabase is not configured.';
      return;
    }

    try {
      isLoadingAccounts.value = true;
      final List<dynamic> response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, role, is_approved')
          .order('created_at', ascending: false)
          .limit(300);

      accounts.assignAll(response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        return AdminAccountItem(
          id: map['id']?.toString() ?? '',
          fullName: map['full_name']?.toString() ?? 'Unknown',
          role: map['role']?.toString() ?? 'patient',
          isApproved: map['is_approved'] == true,
        );
      }).toList());
    } catch (_) {
      accountsError.value = 'Failed to load accounts.';
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  Future<void> approveAccount(String accountId, bool approved) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update(<String, dynamic>{'is_approved': approved}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', approved ? 'Account approved.' : 'Approval revoked.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account approval.');
    }
  }

  Future<void> updateAccountRole(String accountId, String role) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update(<String, dynamic>{'role': role}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', 'Account role updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account role.');
    }
  }

  Future<void> updateAccountName(String accountId, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      await SupabaseService.client
          .from('profiles')
          .update(<String, dynamic>{'full_name': trimmed}).eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Updated', 'Account name updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update account name.');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (accountId == _currentUserId) {
      Get.snackbar('Blocked', 'You cannot delete your own admin account.');
      return;
    }

    try {
      await SupabaseService.client.from('profiles').delete().eq('id', accountId);
      await loadAccounts();
      Get.snackbar('Deleted', 'Account removed from profiles.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete account.');
    }
  }

  Future<void> loadComplaints() async {
    complaintsError.value = '';
    if (!SupabaseService.isConfigured) {
      complaintsError.value = 'Supabase is not configured.';
      return;
    }

    try {
      isLoadingComplaints.value = true;
      final List<dynamic> response = await SupabaseService.client
          .from('complaints')
          .select(
            'id, title, body, status, admin_response, patient:patient_id(full_name), doctor:doctor_id(full_name)',
          )
          .order('created_at', ascending: false)
          .limit(200);

      complaints.assignAll(response.map((dynamic row) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final Map<String, dynamic>? patient = map['patient'] as Map<String, dynamic>?;
        final Map<String, dynamic>? doctor = map['doctor'] as Map<String, dynamic>?;

        return AdminComplaintItem(
          id: map['id']?.toString() ?? '',
          title: map['title']?.toString() ?? '-',
          body: map['body']?.toString() ?? '-',
          status: map['status']?.toString() ?? 'open',
          patientName: patient?['full_name']?.toString() ?? 'Patient',
          doctorName: doctor?['full_name']?.toString(),
          adminResponse: map['admin_response']?.toString(),
        );
      }).toList());
    } catch (_) {
      complaintsError.value = 'Failed to load complaints.';
    } finally {
      isLoadingComplaints.value = false;
    }
  }

  Future<void> updateComplaintStatus(String complaintId, String status) async {
    try {
      await SupabaseService.client
          .from('complaints')
          .update(<String, dynamic>{'status': status}).eq('id', complaintId);
      await loadComplaints();
      Get.snackbar('Updated', 'Complaint status updated.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update complaint status.');
    }
  }

  Future<void> respondToComplaint(String complaintId, String responseText) async {
    if (responseText.trim().isEmpty) {
      return;
    }

    try {
      await SupabaseService.client.from('complaints').update(
        <String, dynamic>{
          'admin_response': responseText.trim(),
          'status': 'in_review',
        },
      ).eq('id', complaintId);
      await loadComplaints();
      Get.snackbar('Saved', 'Admin response saved.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to save response.');
    }
  }
}
