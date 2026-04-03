import 'package:flutter/material.dart';
import 'package:flutter_mcp_ui_runtime/flutter_mcp_ui_runtime.dart';

void registerAntdWidgets(WidgetRegistry widgetRegistry) {
  widgetRegistry.register('antdSection', AntdSectionFactory());
  widgetRegistry.register('antdStat', AntdStatFactory());
  widgetRegistry.register('antdTable', AntdTableFactory());
}

class AntdSectionFactory extends WidgetFactory {
  @override
  Widget build(Map<String, dynamic> definition, RenderContext context) {
    final properties = extractProperties(definition);
    final title = context.resolve<String?>(properties['title']) ?? '';
    final subtitle = context.resolve<String?>(properties['subtitle']);
    final childDef = properties['child'] as Map<String, dynamic>?;
    final child = childDef != null
        ? context.buildWidget(childDef)
        : const SizedBox.shrink();

    final widget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: parseColor(properties['backgroundColor']) ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              parseColor(properties['borderColor']) ?? const Color(0xFFE2E8F0),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );

    return applyCommonWrappers(widget, properties, context);
  }
}

class AntdStatFactory extends WidgetFactory {
  @override
  Widget build(Map<String, dynamic> definition, RenderContext context) {
    final properties = extractProperties(definition);
    final title = context.resolve<String?>(properties['title']) ?? '';
    final value = context.resolve<String?>(properties['value']) ?? '';
    final suffix = context.resolve<String?>(properties['suffix']) ?? '';
    final trend = context.resolve<String?>(properties['trend']) ?? '';
    final tone = context.resolve<String?>(properties['tone']) ?? 'slate';
    final colors = _tone(tone);

    final widget = Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.$1, colors.$2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: colors.$3,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: colors.$4,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
              children: <InlineSpan>[
                TextSpan(text: value),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      color: colors.$3,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (trend.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              trend,
              style: TextStyle(
                color: colors.$3,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return applyCommonWrappers(widget, properties, context);
  }

  (Color, Color, Color, Color) _tone(String tone) {
    switch (tone) {
      case 'teal':
        return const (
          Color(0xFFE6FFFB),
          Color(0xFFCCFBF1),
          Color(0xFF0F766E),
          Color(0xFF115E59)
        );
      case 'blue':
        return const (
          Color(0xFFE0F2FE),
          Color(0xFFDBEAFE),
          Color(0xFF1D4ED8),
          Color(0xFF1E3A8A)
        );
      case 'amber':
        return const (
          Color(0xFFFEF3C7),
          Color(0xFFFDE68A),
          Color(0xFFB45309),
          Color(0xFF92400E)
        );
      default:
        return const (
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0),
          Color(0xFF475569),
          Color(0xFF0F172A)
        );
    }
  }
}

class AntdTableFactory extends WidgetFactory {
  @override
  Widget build(Map<String, dynamic> definition, RenderContext context) {
    final properties = extractProperties(definition);
    final columns =
        context.resolve<List<dynamic>?>(properties['columns']) ?? <dynamic>[];
    final rows =
        context.resolve<List<dynamic>?>(properties['rows']) ?? <dynamic>[];

    final widget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              const WidgetStatePropertyAll<Color>(Color(0xFFF8FAFC)),
          dataRowMinHeight: 52,
          columns: columns.map((dynamic column) {
            final map = Map<String, dynamic>.from(column as Map);
            final title = map['title'];
            return DataColumn(
              label: Text(
                title == null ? '' : title.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            );
          }).toList(),
          rows: rows.map((dynamic row) {
            final map = Map<String, dynamic>.from(row as Map);
            return DataRow(
              cells: columns.map((dynamic column) {
                final columnMap = Map<String, dynamic>.from(column as Map);
                final keyValue = columnMap['key'];
                final key = keyValue == null ? '' : keyValue.toString();
                final value = map[key];
                return DataCell(_buildCell(key, value));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );

    return applyCommonWrappers(widget, properties, context);
  }

  Widget _buildCell(String key, dynamic value) {
    if (key == 'status') {
      final normalized = value?.toString().toLowerCase() ?? '';
      Color background;
      Color foreground;
      switch (normalized) {
        case 'healthy':
        case '稳态':
        case '稳定':
          background = const Color(0xFFDCFCE7);
          foreground = const Color(0xFF166534);
          break;
        case 'watch':
        case '关注':
          background = const Color(0xFFFEF3C7);
          foreground = const Color(0xFF92400E);
          break;
        default:
          background = const Color(0xFFFEE2E2);
          foreground = const Color(0xFFB91C1C);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          value?.toString() ?? '',
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Text(
      value?.toString() ?? '',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 13,
      ),
    );
  }
}
