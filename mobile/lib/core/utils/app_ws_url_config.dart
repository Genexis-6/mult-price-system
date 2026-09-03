
class AppWsUrlConfig {
 
  static const bool isProduction = true;
  
  static String get baseUrl {
    if (isProduction) {
      return 'https://denture-shorthand-hardcover.ngrok-free.dev';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }
  
  static String get wsUrl {
    return baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }
}