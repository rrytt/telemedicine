import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';


import '../../../core/supabase/supabase_service.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/github_theme.dart';
import '../patient_theme.dart';
import '../controllers/patient_controller.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final PatientController controller = Get.find<PatientController>();

  @override
  void initState() {
    super.initState();
    // If called with an argument (old flow), select it; otherwise, controller will pick the accepted one.
    final Object? args = Get.arguments;
    if (args is PatientAppointment) {
      controller.selectChatAppointment(args.id);
    }
  }


  @override
  void dispose() {
    controller.stopRealtimeMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final PatientAppointment? appt = controller.selectedChatAppointment;
      final bool isChatOpen = appt != null;

      return Scaffold(
        backgroundColor: PatientStyles.navy,
        appBar: AppBar(
          leading: isChatOpen
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    controller.selectChatAppointment(''); 
                  },
                )
              : null,
          title: isChatOpen
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: PatientStyles.blue,
                      backgroundImage: appt.doctorAvatarUrl != null
                          ? NetworkImage(appt.doctorAvatarUrl!)
                          : null,
                      child: appt.doctorAvatarUrl == null
                          ? Text(
                              appt.doctor.isNotEmpty == true
                                  ? appt.doctor[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Chat with ${appt.doctor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : const Text('Appointments'),

        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        foregroundColor: PatientStyles.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: PatientStyles.border, width: 1),
        ),
        actions: isChatOpen
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'View doctor profile',
                  onPressed: () {
                    final PatientAppointment? appt =
                        controller.selectedChatAppointment;
                    if (appt == null) return;
                    Get.toNamed(
                      AppRoutes.publicProfile,
                      arguments: <String, dynamic>{'id': appt.doctorId},
                    );
                  },
                ),
                IconButton(
                  onPressed: controller.canStartSelectedVideoCall
                      ? controller.openSelectedVideoCall
                      : null,
                  icon: const Icon(Icons.video_call_outlined),
                ),
              ]
            : <Widget>[],
      ),
      body: Stack(
        children: <Widget>[
          Container(decoration: PatientStyles.backgroundGradient),
          Container(
            child: isChatOpen
                ? _buildChatArea()
                : _buildAppointmentsList(),
          ),
        ],
      ),
    );
    },
    );
  }

  Widget _buildAppointmentsList() {
    final List<PatientAppointment> pending = controller.appointments
        .where((PatientAppointment item) => item.status == 'Pending')
        .toList();
    final List<PatientAppointment> accepted = controller.appointments
        .where((PatientAppointment item) => item.chatEnabled)
        .toList();
    final List<PatientAppointment> other = controller.appointments
        .where(
          (PatientAppointment item) =>
              item.status != 'Pending' && !item.chatEnabled,
        )
        .toList();

    if (controller.isLoadingAppointments.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.appointments.isEmpty) {
      return const Center(
        child: Text(
          'No appointments',
          style: TextStyle(color: PatientStyles.textSecondary),
        ),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: const SliverToBoxAdapter(
              child: Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PatientStyles.textPrimary,
                ),
              ),
            ),
          ),
          if (pending.isNotEmpty) ...<Widget>[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: const SliverToBoxAdapter(
                child: Text(
                  'Pending Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PatientStyles.slate,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final PatientAppointment item = pending[index];
                  return _appointmentListTile(
                    title: item.doctor,
                    subtitle: 'Waiting for doctor confirmation',
                    statusText: item.status,
                    statusColor: GithubTheme.warning,
                    unreadCount: 0,
                    onTap: () {
                      Get.snackbar(
                        'Pending',
                        'Your request is waiting for the doctor to accept.',
                      );
                    },
                    actionable: false,
                  );
                },
                childCount: pending.length,
              ),
            ),
          ],
          if (accepted.isNotEmpty) ...<Widget>[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Active Consultations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PatientStyles.slate,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final PatientAppointment item = accepted[index];
                  final int unread = controller.unreadForAppointment(item.id);
                  return _appointmentListTile(
                    title: item.doctor,
                    subtitle: 'Tap to continue the consultation',
                    statusText: 'Accepted',
                    statusColor: GithubTheme.success,
                    unreadCount: unread,
                    onTap: () {
                      controller.selectChatAppointment(item.id);
                    },
                    actionable: true,
                    trailingRightIcon: Icons.arrow_forward_ios,
                  );
                },
                childCount: accepted.length,
              ),
            ),
          ],
          if (other.isNotEmpty) ...<Widget>[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Other Appointments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PatientStyles.slate,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final PatientAppointment item = other[index];
                  return _appointmentListTile(
                    title: item.doctor,
                    subtitle: 'Appointment status: ${item.status}',
                    statusText: item.status,
                    statusColor: GithubTheme.textMuted,
                    unreadCount: 0,
                    onTap: () {
                      Get.snackbar(
                        'Appointment queued',
                        'This appointment has been recorded for your review.',
                      );
                    },
                    actionable: false,
                  );
                },
                childCount: other.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (controller.messagesError.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            controller.messagesError.value,
            style: const TextStyle(color: GithubTheme.danger),
          ),
        ),
      );
    }

    if (controller.isLoadingMessages.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.',
          style: TextStyle(color: GithubTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.messages.length,
            itemBuilder: (BuildContext context, int index) {
              final ChatMessageItem msg = controller.messages[index];
              final bool own = controller.isOwnMessage(msg.senderId);
              return _buildGitHubStyleMessage(msg, own, context);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: GithubTheme.bg,
            border: Border(
              top: BorderSide(color: GithubTheme.border, width: 1.0),
            ),
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: GithubTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GithubTheme.border),
              ),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: controller.sendAttachment,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: GithubTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GithubTheme.border),
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        color: GithubTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      style: const TextStyle(
                        color: PatientStyles.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Leave a comment...',
                        hintStyle: const TextStyle(
                          color: PatientStyles.slateLight,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: PatientStyles.border,
                          ),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: PatientStyles.blue,
                          ),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      onSubmitted: (_) => controller.sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GithubTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onPressed: controller.sendTextMessage,
                    child: const Text(
                      'Comment',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGitHubStyleMessage(
    ChatMessageItem msg,
    bool own,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: GithubTheme.surface,
        border: Border.all(
          color: own
              ? GithubTheme.primary.withValues(alpha: 0.5)
              : GithubTheme.border,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GithubTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Message Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: own
                  ? GithubTheme.primary.withValues(alpha: 0.1)
                  : GithubTheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: own
                      ? GithubTheme.primary.withValues(alpha: 0.5)
                      : GithubTheme.border,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        own ? 'You' : 'Doctor',
                        style: const TextStyle(
                          color: GithubTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'commented ${controller.formatMessageTime(msg.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GithubTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (own)
                  Builder(
                    builder: (BuildContext context) {
                      final String status = controller.messageStatusFor(msg);
                      final IconData icon =
                          status == 'Seen' || status == 'Delivered'
                              ? Icons.done_all
                              : Icons.done;
                      final Color color = status == 'Seen'
                          ? GithubTheme.primary
                          : GithubTheme.textSecondary;
                      return Icon(icon, size: 14, color: color);
                    },
                  ),
              ],
            ),
          ),
          // Message Body
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if ((msg.message ?? '').isNotEmpty)
                  Text(
                    msg.message!,
                    style: const TextStyle(
                      color: GithubTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                if ((msg.attachmentName ?? '').isNotEmpty)
                  if (_isImage(msg.attachmentType, msg.attachmentName) &&
                      msg.attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          controller.openImage(msg);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: msg.attachmentPath!,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: GithubTheme.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: CachedNetworkImage(
                                imageUrl: _getAttachmentUrl(
                                  msg.attachmentPath!,
                                ),
                                httpHeaders: {
                                  'Authorization':
                                      'Bearer ${SupabaseService.client.auth.currentSession?.accessToken ?? ""}',
                                  'apikey': SupabaseService.anonKey,
                                },
                                width: 250,
                                fit: BoxFit.cover,
                                placeholder:
                                    (BuildContext context, String url) =>
                                        Container(
                                          width: 250,
                                          height: 200,
                                          color: GithubTheme.bg,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                errorWidget:
                                    (
                                      BuildContext context,
                                      String url,
                                      dynamic error,
                                    ) {
                                      return Container(
                                        width: 250,
                                        height: 200,
                                        color: GithubTheme.bg,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Icons.broken_image,
                                              color: GithubTheme.textSecondary,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    GithubTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ) // Removed comma here to connect to the 'else' below
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.attach_file,
                            size: 16,
                            color: GithubTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              msg.attachmentName ?? 'Attachment',
                              style: const TextStyle(
                                color: GithubTheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentListTile({
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required int unreadCount,
    required VoidCallback onTap,
    required bool actionable,
    IconData? trailingRightIcon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: PatientStyles.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: PatientStyles.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PatientStyles.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PatientStyles.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionable)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    trailingRightIcon ?? Icons.arrow_forward_ios,
                    size: 16,
                    color: GithubTheme.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isImage(String? type, String? filename) {

    final String lowerType = (type ?? '').toLowerCase();
    final String lowerName = (filename ?? '').toLowerCase();
    return lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png') ||
        lowerType.contains('gif') ||
        lowerType.contains('webp') ||
        lowerType.startsWith('image/') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp');
  }

  String _getAttachmentUrl(String path) {
    final String baseUrl = SupabaseService.supabaseUrl;
    final String authenticatedUrl =
        '$baseUrl/storage/v1/object/authenticated/medical-files/$path';
    debugPrint('Patient Authenticated Image URL: $authenticatedUrl');
    return authenticatedUrl;
  }
}
