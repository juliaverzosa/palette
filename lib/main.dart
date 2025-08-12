import 'package:flutter/material.dart';
import 'package:project_pallete/screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase initialized successfully!");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qmbjdidwrzozjfisqyac.supabase.co', // Your Supabase Project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtYmpkaWR3cnpvempmaXNxeWFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM4MTg4MDAsImV4cCI6MjA0OTM5NDgwMH0.xntjOcrt_xmhqH9bzjgaLbsgtiMZ5BCIZ45pDnCzZEc',       // Your Supabase Public Anonymous Key
  );
  print("Supabase initialized successfully!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Palette App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
