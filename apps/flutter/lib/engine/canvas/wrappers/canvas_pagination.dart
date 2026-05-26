import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasPagination extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasPagination({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasPagination(config: config, ctx: ctx);
  }

  @override
  State<CanvasPagination> createState() => _CanvasPaginationState();
}

class _CanvasPaginationState extends State<CanvasPagination> {
  final _scrollController = ScrollController();
  int _page = 1;
  final _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        setState(() => _page++);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();
    final items = widget.config.children ?? [];
    final paginated = items.take(_page * _pageSize).toList();
    return ListView.builder(
      controller: _scrollController,
      itemCount: paginated.length + (paginated.length < items.length ? 1 : 0),
      itemBuilder: (ctx, i) => i < paginated.length ? r.build(paginated[i], widget.ctx) : const Center(child: CircularProgressIndicator()),
    );
  }
}
