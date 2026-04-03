import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/persistence/local_draft_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final draftStore = LocalDraftStore();
  await draftStore.init();
  runApp(FlutterMcpStudioApp(draftStore: draftStore));
}

