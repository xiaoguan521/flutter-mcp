import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/editor/studio_controller.dart';
import '../features/runtime/runtime_canvas.dart';

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  final TextEditingController _sourceController = TextEditingController();
  int _lastSourceRevision = -1;

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudioController>(
      builder: (context, controller, _) {
        if (_lastSourceRevision != controller.sourceRevision) {
          _lastSourceRevision = controller.sourceRevision;
          _sourceController.value = TextEditingValue(
            text: controller.prettySource,
            selection: TextSelection.collapsed(
              offset: controller.prettySource.length,
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F1EA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4F1EA),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Flutter MCP Studio',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  controller.statusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => controller.reconnectMcp(),
                child: Text(
                  controller.isMcpConnected ? 'MCP 已连接' : '连接 MCP',
                  style: TextStyle(
                    color: controller.isMcpConnected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: controller.currentDocument == null || controller.isSaving
                    ? null
                    : () => controller.persistCurrentPage(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                ),
                child: controller.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('固化当前页'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                if (controller.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      controller.error!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 1100) {
                        return _buildCompactLayout(controller);
                      }
                      return _buildWideLayout(controller);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(StudioController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 300,
            child: _buildPageRail(controller),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPreviewPanel(controller),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: _buildEditorPanel(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(StudioController controller) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Tab>[
              Tab(text: '页面'),
              Tab(text: '预览'),
              Tab(text: '编辑'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildPageRail(controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildPreviewPanel(controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildEditorPanel(controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageRail(StudioController controller) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '页面版本',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.refreshPages(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (controller.draftUpdatedAt != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '本地草稿：${controller.draftUpdatedAt}',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Text(
            '页面列表',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: <Widget>[
                ...controller.pages.map(
                  (page) => Card(
                    elevation: 0,
                    color: controller.selectedSlug == page.slug
                        ? const Color(0xFFE0F2FE)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      title: Text(page.title),
                      subtitle: Text(page.description ?? page.slug),
                      trailing: page.isBundled
                          ? const Icon(Icons.inventory_2_outlined, size: 18)
                          : const Icon(Icons.cloud_done_outlined, size: 18),
                      onTap: () => controller.loadPage(page.slug),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '版本记录',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.versions.map(
                  (version) => Card(
                    elevation: 0,
                    color: version.version == controller.selectedVersion
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      dense: true,
                      title: Text(version.version),
                      subtitle: Text(version.note ?? version.createdAt),
                      trailing: version.isStable
                          ? const Icon(Icons.push_pin_outlined, size: 18)
                          : const Icon(Icons.history_rounded, size: 18),
                      onTap: controller.isUsingBundledFallback
                          ? null
                          : () => controller.loadPage(
                                version.slug,
                                version: version.version,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(StudioController controller) {
    final document = controller.currentDocument;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            document?.title ?? '未选择页面',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            document?.description ?? '从左侧选择一个样例页面开始编辑。',
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (document?.versionUri != null && document!.versionUri!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(
                document.versionUri!,
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAF9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: document == null
                  ? const Center(
                      child: Text('暂无页面'),
                    )
                  : RuntimeCanvas(
                      definition: document.definition,
                      revision: controller.runtimeRevision,
                      onToolCall: controller.invokeRuntimeTool,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel(StudioController controller) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '人工定制',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('kpi'),
                child: const Text('添加 KPI'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('table'),
                child: const Text('添加表格'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('toolbar'),
                child: const Text('添加操作条'),
              ),
              OutlinedButton(
                onPressed: controller.currentDocument == null
                    ? null
                    : () => controller.addBlock('note'),
                child: const Text('添加说明'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '拖拽排序',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: ReorderableListView.builder(
              itemCount: controller.contentBlocks.length,
              onReorder: (oldIndex, newIndex) {
                controller.moveBlock(oldIndex, newIndex);
              },
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final block = controller.contentBlocks[index];
                return Card(
                  key: ValueKey('${block['metaId'] ?? block['title'] ?? index}'),
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  child: ListTile(
                    title: Text(controller.describeBlock(block, index)),
                    subtitle: Text(block['type']?.toString() ?? ''),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator_rounded),
                    ),
                    trailing: IconButton(
                      onPressed: () => controller.removeBlock(index),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Text(
                'JSON DSL',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => controller.restoreDraft(),
                child: const Text('恢复草稿'),
              ),
              TextButton(
                onPressed: () => controller.clearDraft(),
                child: const Text('清空草稿'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _sourceController,
              expands: true,
              maxLines: null,
              minLines: null,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFE2E8F0),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: '在这里直接编辑页面 JSON DSL',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.currentDocument == null
                  ? null
                  : () => controller.applySource(_sourceController.text),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
              ),
              child: const Text('应用 JSON 到预览'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
