import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/agora/agora_service.dart';
import '../../../core/agora/agora_token_service.dart';

class AgoraCallView extends StatefulWidget {
  const AgoraCallView({super.key});

  @override
  State<AgoraCallView> createState() => _AgoraCallViewState();
}

class _AgoraCallViewState extends State<AgoraCallView> {
  late final AgoraClient _client;
  late String _appId;
  late String _channelName;
  late final String _appointmentId;
  String? _token;
  bool _isInitialized = false;
  bool _isInitFailed = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> args =
        (Get.arguments as Map<String, dynamic>?) ?? <String, dynamic>{};

    _appId = (args['appId'] as String?)?.trim().isNotEmpty == true
        ? (args['appId'] as String).trim()
      : AgoraService.appId;

    _channelName =
        (args['channelName'] as String?)?.trim().isNotEmpty == true
            ? (args['channelName'] as String).trim()
        : AgoraService.defaultChannel;

    _appointmentId = (args['appointmentId'] as String?)?.trim() ?? '';

    _token = AgoraService.resolveToken(args['token'] as String?);

    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      if (_token == null || _token!.isEmpty) {
        if (_appointmentId.isEmpty) {
          throw StateError('Appointment ID is required to fetch Agora token.');
        }

        final AgoraTokenResponse tokenResponse = await AgoraTokenService.fetchRtcToken(
          appointmentId: _appointmentId,
          channelName: _channelName,
        );
        _appId = tokenResponse.appId;
        _channelName = tokenResponse.channelName;
        _token = tokenResponse.token;
      }

      _client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: _appId,
          channelName: _channelName,
          tempToken: _token,
        ),
        enabledPermission: <Permission>[
          Permission.camera,
          Permission.microphone,
        ],
      );

      await _client.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitFailed = true;
        _errorText = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call: $_channelName'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_appId.isEmpty) {
      return _buildInfo(
        title: 'Missing Agora App ID',
        subtitle:
            'Provide AGORA_APP_ID with dart-define or pass appId in route arguments.',
      );
    }

    if (_isInitFailed) {
      return _buildInfo(
        title: 'Unable to initialize call',
        subtitle: _errorText.isNotEmpty
            ? _errorText
            : 'Check App ID, channel name, and token settings for Agora.',
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: <Widget>[
        AgoraVideoViewer(client: _client),
        AgoraVideoButtons(client: _client),
      ],
    );
  }

  Widget _buildInfo({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Get.back<void>(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
