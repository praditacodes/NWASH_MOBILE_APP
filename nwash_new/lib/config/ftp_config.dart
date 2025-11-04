// FTP configuration is now disabled. All code commented out.
class FTPConfig {
  // FTP Server Configuration
  static const String host = 'your-ftp-server.com'; // Replace with your FTP server address
  static const String username = 'your-username'; // Replace with your FTP username
  static const String password = 'your-password'; // Replace with your FTP password
  static const int port = 21; // Standard FTP port, change if using SFTP or different port
  
  // Optional: SFTP Configuration (if using SFTP instead of FTP)
  static const bool useSFTP = false; // Set to true if using SFTP
  static const int sftpPort = 22; // Standard SFTP port
  
  // Connection timeout settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int dataTimeout = 60000; // 60 seconds
  
  // Retry settings
  static const int maxRetries = 3;
  static const int retryDelay = 2000; // 2 seconds
  
  // Directory structure on FTP server
  static const String usersDirectory = '/users';
  static const String sessionsDirectory = '/sessions';
  static const String mediaDirectory = '/media';
  static const String dataDirectory = '/data';
  
  // File naming conventions
  static const String userFileExtension = '.json';
  static const String sessionFileExtension = '.json';
  static const String dataFileExtension = '.json';
  
  // Validation
  static bool get isValid {
    return host.isNotEmpty && 
           username.isNotEmpty && 
           password.isNotEmpty && 
           port > 0 && 
           port <= 65535;
  }
  
  // Get connection string for logging (without password)
  static String get connectionString {
    return 'ftp://$username@$host:$port';
  }
  
  // Helper method to get the appropriate port
  static int get effectivePort {
    return useSFTP ? sftpPort : port;
  }
} 