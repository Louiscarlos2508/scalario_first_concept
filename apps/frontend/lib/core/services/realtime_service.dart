import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';

class RealtimeService {
  final SupabaseClient _supabase;
  final SyncService _syncService;
  final Ref _ref;
  bool _isInitialized = false;

  RealtimeService(this._supabase, this._syncService, this._ref);

  void init() {
    if (_isInitialized) return;
    
    print('[RealtimeService] Initializing subscriptions...');

    // Synchronize local products and stock when database changes
    _supabase
        .channel('public:products')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'products',
          ),
          (payload, [ref]) {
            print('[Realtime] Product change detected');
            _syncService.forceSync();
          },
        )
        .subscribe();

    _supabase
        .channel('public:stock_movements')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'stock_movements',
          ),
          (payload, [ref]) {
            print('[Realtime] Stock movement detected');
            _syncService.forceSync();
          },
        )
        .subscribe();

    // Trigger Dashboard refreshes when new orders are created
    _supabase
        .channel('public:orders')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'orders',
          ),
          (payload, [ref]) {
            print('[Realtime] New order detected, refreshing dashboard...');
            // Invalidate/Refresh relevant providers
            _ref.invalidate(salesStatsProvider);
            _ref.invalidate(salesReportProvider);
          },
        )
        .subscribe();
        
    _isInitialized = true;
    print('[RealtimeService] Subscriptions active.');
  }
}
