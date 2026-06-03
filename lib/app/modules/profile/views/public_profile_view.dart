import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../theme/github_theme.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  Map<String, dynamic>? profile;
  String avatarUrl = '';
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final Map<String, dynamic> args =
        Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final String id = args['id']?.toString() ?? '';

    if (id.isEmpty) {
      setState(() {
        error = 'Invalid profile id.';
        isLoading = false;
      });
      return;
    }

    try {
      final dynamic res = await SupabaseService.client
          .from('profiles')
          .select(
            'id, full_name, role, specialty, phone_number, bio, avatar_url, blood_type, medical_record',
          )
          .eq('id', id)
          .maybeSingle();

      if (res is Map<String, dynamic>) {
        profile = res;
        final String path = profile?['avatar_url']?.toString() ?? '';
        if (path.isNotEmpty) {
          try {
            final String signed = await SupabaseService.client.storage
                .from('avatars')
                .createSignedUrl(path, 3600);
            avatarUrl = signed;
          } catch (_) {
            avatarUrl = '';
          }
        }
      } else {
        error = 'Profile not found.';
      }
    } catch (e) {
      error = 'Failed to load profile: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GithubTheme.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: GithubTheme.surface,
        foregroundColor: GithubTheme.textPrimary,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      error,
                      style: const TextStyle(color: GithubTheme.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          : _buildProfileCard(),
    );
  }

  Widget _buildProfileCard() {
    if (profile == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: GithubTheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  gradient: GithubTheme.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              (profile?['full_name']?.toString().isNotEmpty ??
                                      false)
                                  ? profile!['full_name'][0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            profile?['full_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Role: ${profile?['role'] ?? '-'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if ((profile?['specialty'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Specialty: ${profile!['specialty']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if ((profile?['phone_number'] ?? '').toString().isNotEmpty) ...[
                _buildInfoRow('Phone', profile!['phone_number'] ?? ''),
              ],
              if ((profile?['blood_type'] ?? '').toString().isNotEmpty) ...[
                _buildInfoRow('Blood Type', profile!['blood_type'] ?? ''),
              ],
              if ((profile?['medical_record'] ?? '').toString().isNotEmpty) ...[
                _buildInfoRow(
                  'Medical Record',
                  profile!['medical_record'] ?? '',
                ),
              ],
              if ((profile?['bio'] ?? '').toString().isNotEmpty) ...[
                _buildInfoRow('Bio', profile!['bio'] ?? ''),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: GithubTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: GithubTheme.textSecondary)),
        ],
      ),
    );
  }
}
