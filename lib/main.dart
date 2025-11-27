import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:streaming_and_chat_app/app.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async{
    WidgetsFlutterBinding.ensureInitialized();
AppLogger.init();
  AppLogger.info('Starting application...');
try {
    await dotenv.load(fileName: ".env");
    AppLogger.info('Environment variables loaded');
    
    await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,

    );
    AppLogger.info('Firebase initialized');
    
    await configureDependencies();
    AppLogger.info('Dependencies configured');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize app', e, stackTrace);
    rethrow;
  }
}
