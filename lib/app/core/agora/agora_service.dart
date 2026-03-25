class AgoraService {
  static const String defaultAppId = '002258e891ae4e119f04ffb0edb5c6d8';
  static const String defaultChannel = 'test';
  static const String _appIdFromEnv = String.fromEnvironment('AGORA_APP_ID');
  static const String _tokenFromEnv = String.fromEnvironment('AGORA_TEMP_TOKEN');

  static String get appId {
    if (_appIdFromEnv.trim().isNotEmpty) {
      return _appIdFromEnv.trim();
    }
    return defaultAppId;
  }

  static String? resolveToken([String? token]) {
    final String provided = token?.trim() ?? '';
    if (provided.isNotEmpty) {
      return provided;
    }

    final String envToken = _tokenFromEnv.trim();
    if (envToken.isNotEmpty) {
      return envToken;
    }

    return null;
  }

  static String buildAppointmentChannel(String appointmentId) {
    final String normalized = appointmentId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (normalized.isEmpty) {
      return defaultChannel;
    }
    return 'appointment_$normalized';
  }
}
