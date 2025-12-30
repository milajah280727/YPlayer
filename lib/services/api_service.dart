class ApiService {
  // Url API
  static const String _baseUrl = 'https://output-columns-jet-portable.trycloudflare.com';

  //Endpoint get format

  static String getFormatsEndpoint(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/get-formats?url=$url';
  }

  //Endpoint Streaming Audio
  static String getStreamAudioEndpoint(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/stream-audio?url=$url';
  }

  //Endpoint Streaming Audio
  static String getStreamVideoEndpoint(String videoId, String resolution) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/stream-video?url=$url&resolution=$resolution';
  }

  //Endpoint download Audio
static String getDownloadAudioEndpoint(String videoId) {
  final url = 'https://www.youtube.com/watch?v=$videoId';
  // Tidak perlu encoding manual, Dio akan menangani ini
  return '$_baseUrl/download-audio?url=$url';
}

  //Endpoint Download Video
  static String getDownloadVideoEndpoint(String videoId, String resolution) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/download?url=$url&quality=$resolution';
  }
}