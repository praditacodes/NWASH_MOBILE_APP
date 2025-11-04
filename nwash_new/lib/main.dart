import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'screens/login_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/history.dart';
import 'screens/settings.dart';
import 'screens/collect_data.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/capture_provider.dart';
import 'providers/data_provider.dart';
import 'providers/sync_provider.dart';
import 'services/api_service.dart';
// import 'config/ftp_config.dart';

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
}

// Add ThemeProvider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

Future<void> main() async {
  // Initialize logging
  _setupLogging();
  final logger = Logger('main');
  
  try {
    logger.info('Initializing Flutter bindings');
    WidgetsFlutterBinding.ensureInitialized();
    // Ensure ApiService is initialized before any usage
    await ApiService().init();
    
    logger.info('Starting app...');
    runApp(MyApp());
  } catch (e, stackTrace) {
    logger.severe('Error during app initialization', e, stackTrace);
    // Handle the error appropriately, maybe show an error UI
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error: ${details.exception}'),
          ),
        ),
      );
    };
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final ApiService _apiService = ApiService();
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CaptureProvider()),
        ChangeNotifierProvider<DataProvider>(
          create: (_) => DataProvider(_apiService),
        ),
        ChangeNotifierProvider<SyncProvider>(
          create: (_) => SyncProvider(_apiService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'NWASH',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoading) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Checking authentication...'),
                        ],
                      ),
                    ),
                  );
                }
                if (authProvider.isAuthenticated) {
                  return HomeScreen();
                } else {
                  return LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
              '/capture': (context) => CaptureScreen(),
              '/history': (context) => HistoryScreen(),
              '/settings': (context) => SettingsScreen(),
              '/collect_data': (context) => CollectDataScreen(),
            },
          );
        },
      ),
    );
  }
}
