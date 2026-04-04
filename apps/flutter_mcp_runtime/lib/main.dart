import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/config/runtime_launch_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = RuntimeLaunchConfig.fromEnvironment();
  runApp(FlutterMcpRuntimeApp(config: config));
}
