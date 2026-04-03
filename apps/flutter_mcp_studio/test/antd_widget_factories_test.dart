import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mcp_ui_runtime/flutter_mcp_ui_runtime.dart';
import 'package:flutter_mcp_ui_runtime/src/binding/binding_engine.dart';
import 'package:flutter_mcp_ui_runtime/src/theme/theme_manager.dart';

import 'package:flutter_mcp_studio/widgets/antd_widget_factories.dart';

void main() {
  testWidgets(
    'FormFactory renders both child and children blocks',
    (WidgetTester tester) async {
      final widgetRegistry = WidgetRegistry()
        ..register('form', FormFactory())
        ..register('text', _TextEchoFactory());
      final renderer = Renderer(
        widgetRegistry: widgetRegistry,
        bindingEngine: BindingEngine(),
        actionHandler: ActionHandler(),
        stateManager: StateManager(),
      );
      final context = RenderContext(
        renderer: renderer,
        stateManager: renderer.stateManager,
        bindingEngine: renderer.bindingEngine,
        actionHandler: renderer.actionHandler,
        themeManager: ThemeManager.instance,
      );

      final widget = FormFactory().build(
        <String, dynamic>{
          'type': 'form',
          'title': 'Mixed Form',
          'child': <String, dynamic>{
            'type': 'text',
            'content': 'Primary helper',
          },
          'children': <dynamic>[
            <String, dynamic>{
              'type': 'text',
              'content': 'Secondary helper',
            },
          ],
        },
        context,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.text('Primary helper'), findsOneWidget);
      expect(find.text('Secondary helper'), findsOneWidget);
    },
  );
}

class _TextEchoFactory extends WidgetFactory {
  @override
  Widget build(Map<String, dynamic> definition, RenderContext context) {
    final properties = extractProperties(definition);
    return Text(context.resolve<String>(properties['content'] ?? ''));
  }
}
