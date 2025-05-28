import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:shop/Authentication/IntroScreen/intro_screen.dart';
import 'package:shop/Authentication/LoginScreen/login_screen.dart';
import 'package:shop/NavigationBar/HomePage/mainScreen.dart';
import 'package:shop/Details/create_account_screen.dart';
import 'package:shop/firebase/firebase_options.dart';
import 'package:shop/provider/bag_provider.dart';
import 'package:shop/provider/wishlist_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));

  final currentUser = FirebaseAuth.instance.currentUser;
  final bagProvider = BagProvider();
  final wishlistProvider = WishlistProvider();

  if (currentUser != null) {
    try {
      await bagProvider.loadBag();
      await wishlistProvider.loadWishlist();
    } catch (e) {
      debugPrint("Error loading bag/wishlist: $e");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BagProvider>.value(value: bagProvider),
        ChangeNotifierProvider<WishlistProvider>.value(value: wishlistProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initFCM();
  }

  void initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    final token = await messaging.getToken();
    _saveTokenToFirestore(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  void _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  /// 🔥 This is the new method to remove FCM token on back
  Future<void> _clearUserDataAndSignOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete entire user document from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Sign out from Firebase and Google
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (e) {
        debugPrint('❌ Error deleting user data or signing out: $e');
      }
    }
  }

  Future<Widget> _determineStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists ||
        doc['firstName'] == null ||
        doc['lastName'] == null ||
        doc['phone'] == null) {
      return CreateAccountScreen(
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        onBack: _clearUserDataAndSignOut, // 👈 Pass function to screen
      );
    }

    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        // colorScheme: ColorScheme.light(
        //   primary: Colors.black,
        //   onPrimary: Colors.white,
        //   secondary: Colors.black,
        //   onSecondary: Colors.white,
        // ),
        // inputDecorationTheme: InputDecorationTheme(
        //   filled: true,
        //   fillColor: Colors.white,
        //   contentPadding:
        //       const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        //   border: OutlineInputBorder(
        //     borderSide: BorderSide(color: Colors.grey.shade300),
        //   ),
        //   enabledBorder: OutlineInputBorder(
        //     borderSide: BorderSide(color: Colors.grey.shade300),
        //   ),
        //   focusedBorder: const OutlineInputBorder(
        //     borderSide: BorderSide(color: Colors.black),
        //   ),
        //   errorBorder: const OutlineInputBorder(
        //     borderSide: BorderSide(color: Colors.red),
        //   ),
        //   focusedErrorBorder: const OutlineInputBorder(
        //     borderSide: BorderSide(color: Colors.redAccent),
        //   ),
        //   labelStyle: const TextStyle(fontSize: 14, color: Colors.black),
        // ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.all(Colors.black),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(Colors.black),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(Colors.black),
          trackColor: MaterialStateProperty.all(Colors.black.withOpacity(0.4)),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.black),
        ),
        highlightColor: Colors.black.withOpacity(0.1),
        splashColor: Colors.black.withOpacity(0.1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
          elevation: 0,
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _determineStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const IntroScreen();
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
