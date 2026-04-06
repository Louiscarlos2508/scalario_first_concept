import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/internal_request_card.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/internal_request_form.dart';

class InternalRequestsScreen extends ConsumerStatefulWidget {
  const InternalRequestsScreen({super.key});

  @override
  ConsumerState<InternalRequestsScreen> createState() =>
      _InternalRequestsScreenState();
}

class _InternalRequestsScreenState
    extends ConsumerState<InternalRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Toujours 2 onglets — le second est masqué pour commercial
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final canSeeToProcess = role == 'manager' || role == 'owner';

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Réapprovisionnement interne',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(internalRequestsProvider),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mes demandes'),
            Tab(key: Key('ir_tab_to_process'), text: 'À traiter'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ir_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openCreateForm(context),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestsList(key: const Key('ir_my_requests'), myRequestsOnly: true),
          canSeeToProcess
              ? _RequestsList(
                  key: const Key('ir_to_process'), myRequestsOnly: false)
              : const Center(
                  child: Text(
                    'Réservé aux gestionnaires et propriétaires',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
        ],
      ),
    );
  }

  void _openCreateForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const InternalRequestForm(),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final bool myRequestsOnly;

  const _RequestsList({super.key, required this.myRequestsOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final requestsAsync = ref.watch(internalRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Erreur : $err',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (allRequests) {
        List<Map<String, dynamic>> items;

        if (myRequestsOnly) {
          // Onglet "Mes demandes" — toutes les demandes visibles
          items = allRequests;
        } else {
          // Onglet "À traiter" — pending pour manager / prepared pour owner
          final watchedStatus =
              (role == 'owner') ? ['prepared', 'pending'] : ['pending'];
          items = allRequests
              .where((r) => watchedStatus.contains(r['status']))
              .toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  myRequestsOnly
                      ? 'Aucune demande'
                      : 'Aucune demande en attente',
                  style:
                      const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, i) => InternalRequestCard(request: items[i]),
        );
      },
    );
  }
}
