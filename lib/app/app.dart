import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_ucp_flutter/app/theme.dart';
import 'package:ask_ucp_flutter/auth/auth_gate.dart';
import 'package:ask_ucp_flutter/core/scaffold_messenger.dart'; // <-- add

class AskUcpApp extends ConsumerWidget {
  const AskUcpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASK-UCP',
      theme: lightTheme,
      darkTheme: darkTheme,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const AuthGate(),
    );
  }
}
