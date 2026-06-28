import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../core/agora/agora_service.dart';
import '../../../core/agora/agora_token_service.dart';

class AgoraCallView extends StatefulWidget {
  const AgoraCallView({super.key});

  @override
  State<AgoraCallView> createState() => _AgoraCallViewState();
}

class _AgoraCallViewState extends State<AgoraCallView> {
  RtcEngine? _engine;
  late String _appId;
  late String _channelName;
  late final String _appointmentId;
  String? _token;
  bool _isInitialized = false;
  bool _isInitFailed = false;
  bool _muted = false;
  bool _cameraOff = false;
  int? _remoteUid;
  String _errorText = '';

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> args =
        (Get.arguments as Map<String, dynamic>?) ?? <String, dynamic>{};

    _appId = (args['appId'] as String?)?.trim().isNotEmpty == true
        ? (args['appId'] as String).trim()
        : AgoraService.appId;

    _channelName = (args['channelName'] as String?)?.trim().isNotEmpty == true
        ? (args['channelName'] as String).trim()
        : AgoraService.defaultChannel;

    _appointmentId = (args['appointmentId'] as String?)?.trim() ?? '';

    _token = AgoraService.resolveToken(args['token'] as String?);

    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      final bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        throw StateError('Camera and microphone permissions are required.');
      }

      if (_token == null || _token!.isEmpty) {
        if (_appointmentId.isEmpty) {
          throw StateError('Appointment ID is required to fetch Agora token.');
        }

        final AgoraTokenResponse tokenResponse =
            await AgoraTokenService.fetchRtcToken(
              appointmentId: _appointmentId,
              channelName: _channelName,
            );
        _appId = tokenResponse.appId;
        _channelName = tokenResponse.channelName;
        _token = tokenResponse.token;
      }

      if ((_token ?? '').isEmpty) {
        throw StateError('Agora token is missing or empty.');
      }

      final RtcEngine engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: _appId));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isInitialized = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) {
              return;
            }
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  if (_remoteUid == remoteUid) {
                    _remoteUid = null;
                  }
                });
              },
          onError: (ErrorCodeType err, String msg) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isInitFailed = true;
              _errorText =
                  'Agora error: ${err.name} ${msg.isNotEmpty ? '- $msg' : ''}';
            });
          },
        ),
      );

      await engine.enableVideo();
      await engine.startPreview();
      await engine.joinChannel(
        token: _token!,
        channelId: _channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine = engine;
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

  Future<bool> _requestPermissions() async {
    final ph.PermissionStatus camera = await ph.Permission.camera.request();
    final ph.PermissionStatus microphone = await ph.Permission.microphone
        .request();
    return camera.isGranted && microphone.isGranted;
  }

  Future<void> _toggleMute() async {
    final RtcEngine? engine = _engine;
    if (engine == null) {
      return;
    }
    final bool next = !_muted;
    await engine.muteLocalAudioStream(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _muted = next;
    });
  }

  Future<void> _toggleCamera() async {
    final RtcEngine? engine = _engine;
    if (engine == null) {
      return;
    }
    final bool next = !_cameraOff;
    await engine.muteLocalVideoStream(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _cameraOff = next;
    });
  }

  Future<void> _endCall() async {
    final RtcEngine? engine = _engine;
    if (engine != null) {
      await engine.leaveChannel();
    }
    if (!mounted) {
      return;
    }
    Get.back<void>();
  }

  @override
  void dispose() {
    final RtcEngine? engine = _engine;
    if (engine != null) {
      engine.leaveChannel();
      engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Stack(
      children: <Widget>[
        // الخلفية: الفيديو الرئيسي (الطرف البعيد)
        Positioned.fill(child: _buildRemoteView()),

        // الفيديو الصغير في الأسفل يمين (الكاميرا المحلية)
        Positioned(
          right: 16,
          bottom: 140,
          child: Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildLocalView(),
          ),
        ),

        // أزرار التحكم في الأسفل
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // زر الكاميرا
              _buildControlButton(
                icon: _cameraOff
                    ? Icons.videocam_off_outlined
                    : Icons.videocam_outlined,
                onPressed: _toggleCamera,
                isActive: !_cameraOff,
              ),
              const SizedBox(width: 24),
              // زر إنهاء المكالمة (أحمر كبير)
              _buildEndCallButton(),
              const SizedBox(width: 24),
              // زر المايك
              _buildControlButton(
                icon: _muted ? Icons.mic_off_outlined : Icons.mic_none_outlined,
                onPressed: _toggleMute,
                isActive: !_muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? Colors.black87 : Colors.red,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEF4444),
        boxShadow: [
          BoxShadow(
            color: Color(0x66EF4444),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: _endCall,
        icon: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildRemoteView() {
    final RtcEngine? engine = _engine;
    final int? remoteUid = _remoteUid;
    if (engine == null || remoteUid == null) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white54,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Waiting for remote participant...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: _channelName),
      ),
    );
  }

  Widget _buildLocalView() {
    final RtcEngine? engine = _engine;
    if (engine == null || _cameraOff) {
      return const Center(
        child: Icon(
          Icons.person_outline,
          color: Colors.white54,
          size: 40,
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
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
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
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