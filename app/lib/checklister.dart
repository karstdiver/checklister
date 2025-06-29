/* This is a barrel file that contains all of the exports in the source code.
     Do this in a .dart file to use these exports:
     import 'package:iplanning/iplanning.dart'; // import this app routines
  */
// Create wrapper files in lib/ if you want to expose public APIs:
// lib/checklister.dart

// screens
//export 'src/ui/screens/figma_hello_world.dart';
//export 'src/ui/screens/Firebase_hello_world.dart';
//export 'src/ui/screens/about_screen.dart';

// Error handling
//export 'src/state/app_error_notifier.dart';

// models
//export 'src/models/team.dart';

// state notifiers providers
//export 'src/state/counter_notifier.dart'; // call this to update the counter variable state in UI tree
//export 'src/state/temp_notifier.dart'; // this is a temporary notifier for expansion
//export 'src/state/db_helloworld_notifier.dart'; // this is the first db access state change notifier

// services
//export 'src/services/version_service.dart';

// widgets
//export 'src/ui/app_root.dart'; // app's main screen. Invoked in main.dart
//export 'src/ui/widgets/app_error_handler.dart';
//export 'src/ui/widgets/error_dialog.dart';
//export 'src/ui/widgets/db_error_handler.dart';

// utils
//export 'src/utils/logger.dart';

// You need to declare a GlobalKey<NavigatorState> before you can use it.
import 'package:flutter/material.dart';

/// A global key so we can grab a BuildContext
/// from anywhere (for SnackBars, dialogs, etc.)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
