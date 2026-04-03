import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/models/page_models.dart';
import '../features/editor/studio_controller.dart';
import '../features/runtime/runtime_canvas.dart';

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  String _selectedPageType = 'dashboard';
  int _lastSourceRevision = -1;

  @override
  void dispose() {
    _sourceController.dispose();
    _promptController.dispose();
    _instructionController.dispose();
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
                onPressed:
                    controller.currentDocument == null || controller.isSaving
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
    final generation = controller.lastGeneration;
    final explanation = controller.lastExplanation;
    final update = controller.lastInstructionUpdate;
    final validation = controller.validationResult;
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
          // -- AI 生成摘要 --
          if (generation != null) _buildGenerationSummary(generation),
          if (explanation != null) _buildExplanationSummary(explanation),
          if (update != null) _buildInstructionSummary(update),
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
          // -- 校验结果展示 --
          if (validation != null) _buildValidationPanel(validation),
        ],
      ),
    );
  }

  Widget _buildInstructionSummary(PageUpdateResultModel update) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.auto_fix_high_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'AI 二次修改',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            update.summary,
            style: const TextStyle(
                color: Color(0xFF1E3A8A), fontSize: 12, height: 1.5),
          ),
          if (update.appliedChanges.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '已应用修改',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...update.appliedChanges.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('· $item',
                    style: const TextStyle(
                        color: Color(0xFF1E3A8A), fontSize: 11, height: 1.4)),
              ),
            ),
          ],
          if (update.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...update.warnings.map(
              (warning) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warning,
                  style:
                      const TextStyle(color: Color(0xFF92400E), fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSummary(PageExplanationResultModel explanation) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                '页面解释',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation.summary,
            style: const TextStyle(
              color: Color(0xFF78350F),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '页面类型：${explanation.pageType}',
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (explanation.structure.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '结构概览',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...explanation.structure.take(6).map(
              (item) => Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF78350F),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (explanation.actionSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '动作摘要',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...explanation.actionSummary.take(4).map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '· $item',
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerationSummary(GeneratedPageResultModel generation) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Text(
                'AI 生成 · ${generation.pageType}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            generation.summary,
            style: const TextStyle(
                color: Color(0xFF064E3B), fontSize: 12, height: 1.5),
          ),
          if (generation.assumptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'AI 假设',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...generation.assumptions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('· $a',
                    style: const TextStyle(
                        color: Color(0xFF064E3B), fontSize: 11, height: 1.4)),
              ),
            ),
          ],
          if (generation.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...generation.warnings.map(
              (w) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(w,
                    style: const TextStyle(
                        color: Color(0xFF92400E), fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationPanel(PageValidationResultModel validation) {
    if (validation.errors.isEmpty && validation.warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: const <Widget>[
            Icon(Icons.check_circle_outline,
                size: 16, color: Color(0xFF059669)),
            SizedBox(width: 6),
            Text(
              '页面结构校验通过',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: validation.valid
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validation.valid
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFECACA),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: <Widget>[
          ...validation.errors.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${e.path}: ${e.message}',
                          style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        if (e.suggestion != null)
                          Text(
                            e.suggestion!,
                            style: const TextStyle(
                                color: Color(0xFF92400E), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...validation.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${w.path}: ${w.message}',
                          style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        if (w.suggestion != null)
                          Text(
                            w.suggestion!,
                            style: const TextStyle(
                                color: Color(0xFF78716C), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
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
          // -- AI Prompt 面板 --
          if (controller.canUseAiTools) ...[
            _buildPromptPanel(controller),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
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
                  key:
                      ValueKey('${block['metaId'] ?? block['title'] ?? index}'),
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

  Widget _buildPromptPanel(StudioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            const Text(
              'AI 页面生成',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _promptController,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '描述你想要的页面，如：一个销售团队仪表盘，展示营收、转化率和签约管线',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPageType,
                  isDense: true,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                        value: 'dashboard', child: Text('Dashboard')),
                    DropdownMenuItem(value: 'form', child: Text('Form')),
                    DropdownMenuItem(
                        value: 'table-list', child: Text('Table / List')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPageType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: controller.isGenerating
                      ? null
                      : () {
                          controller.generatePageFromPrompt(
                            prompt: _promptController.text,
                            pageType: _selectedPageType,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  icon: controller.isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(controller.isGenerating ? '生成中…' : 'AI 生成页面'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'AI 二次修改',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: '基于当前页面继续修改，如：增加搜索筛选和操作按钮，并把标题改成客户运营看板',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton.icon(
            onPressed: controller.isApplyingInstruction ||
                    controller.currentDocument == null
                ? null
                : () {
                    controller.updateCurrentPageByInstruction(
                      instruction: _instructionController.text,
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            icon: controller.isApplyingInstruction
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: Text(controller.isApplyingInstruction ? '修改中…' : '应用 AI 修改'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed: controller.isExplaining || controller.currentDocument == null
                ? null
                : () {
                    controller.explainCurrentPage();
                  },
            icon: controller.isExplaining
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tips_and_updates_outlined, size: 16),
            label: Text(controller.isExplaining ? '解释中…' : '解释当前页'),
          ),
        ),
        if (controller.lastExplanation != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: _buildExplanationClipboardText(controller.lastExplanation!),
                  ),
                );
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('页面解释已复制到剪贴板')),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: const Text('复制解释'),
            ),
          ),
        ],
      ],
    );
  }

  String _buildExplanationClipboardText(PageExplanationResultModel explanation) {
    final buffer = StringBuffer()
      ..writeln('页面解释')
      ..writeln('页面类型：${explanation.pageType}')
      ..writeln('摘要：${explanation.summary}');
    if (explanation.structure.isNotEmpty) {
      buffer.writeln('结构：');
      for (final line in explanation.structure) {
        buffer.writeln(line);
      }
    }
    if (explanation.actionSummary.isNotEmpty) {
      buffer.writeln('动作：');
      for (final item in explanation.actionSummary) {
        buffer.writeln('- $item');
      }
    }
    if (explanation.bindingSummary.isNotEmpty) {
      buffer.writeln('绑定：');
      for (final item in explanation.bindingSummary) {
        buffer.writeln('- $item');
      }
    }
    if (explanation.warnings.isNotEmpty) {
      buffer.writeln('警告：');
      for (final item in explanation.warnings) {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString().trimRight();
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
