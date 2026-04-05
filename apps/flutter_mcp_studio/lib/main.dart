import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/config/studio_launch_config.dart';
import 'features/persistence/local_draft_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final draftStore = LocalDraftStore();
  await draftStore.init();
  final config = StudioLaunchConfig.fromEnvironment();
  runApp(FlutterMcpStudioApp(draftStore: draftStore, config: config));
}
