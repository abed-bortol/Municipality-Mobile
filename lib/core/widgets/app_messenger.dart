import 'package:flutter/material.dart';

/// Root messenger so snackbars survive route changes (e.g. "signed out"
/// shown while the router swaps Home for Sign In).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String message) {
  rootScaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
