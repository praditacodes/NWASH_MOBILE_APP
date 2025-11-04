// import '../services/ftp_service.dart';
import '../models/user_model.dart';

// AuthService for FTP/local authentication
class AuthService {
  // final FTPService _ftpService = FTPService();

  Future<UserModel?> signIn(String email, String password) async {
    return null; // await _ftpService.authenticateUser(email, password);
  }

  Future<UserModel?> register(String email, String password, String name) async {
    final user = UserModel(
      uid: email, // or generate a unique ID
      email: email,
      name: name,
    );
    return null; // final success = await _ftpService.registerUser(user, password);
  }

  // Add signOut, resetPassword, etc. as needed
} 