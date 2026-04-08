import 'package:flutter/material.dart';

import 'app/clotho_app.dart';
import 'bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await AppBootstrap.initialize();

  runApp(ClothoApp(bootstrap: bootstrap));
}
