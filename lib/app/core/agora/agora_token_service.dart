import '../supabase/supabase_service.dart';

class AgoraTokenResponse {
  const AgoraTokenResponse({
    required this.appId,
    required this.token,
    required this.channelName,
    required this.appointmentId,
    required this.account,
    required this.expiresAt,
  });

  final String appId;
  final String token;
  final String channelName;
  final String appointmentId;
  final String account;
  final int expiresAt;

  factory AgoraTokenResponse.fromMap(Map<String, dynamic> map) {
    return AgoraTokenResponse(
      appId: map['appId']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      channelName: map['channelName']?.toString() ?? '',
      appointmentId: map['appointmentId']?.toString() ?? '',
      account: map['account']?.toString() ?? '',
      expiresAt: int.tryParse(map['expiresAt']?.toString() ?? '') ?? 0,
    );
  }
}

class AgoraTokenService {
  const AgoraTokenService._();

  static Future<AgoraTokenResponse> fetchRtcToken({
    required String appointmentId,
    required String channelName,
    String role = 'publisher',
    int expiresInSeconds = 3600,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'agora-token',
      body: <String, dynamic>{
        'appointmentId': appointmentId,
        'channelName': channelName,
        'role': role,
        'expiresInSeconds': expiresInSeconds,
      },
    );

    final dynamic data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Agora token response is invalid.');
    }

    final AgoraTokenResponse tokenResponse = AgoraTokenResponse.fromMap(data);
    if (tokenResponse.appId.isEmpty || tokenResponse.token.isEmpty) {
      throw StateError(data['error']?.toString() ?? 'Agora token is missing from response.');
    }

    return tokenResponse;
  }
}
