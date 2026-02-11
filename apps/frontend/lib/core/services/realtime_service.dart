import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/sync_service.dart';

class RealtimeService {
  final SupabaseClient _supabase;
  final SyncService _syncService;
  bool _isInitialized = false;

  RealtimeService(this._supabase, this._syncService);

  void init() {
    if (_isInitialized) return;
    
    print('[RealtimeService] Initializing subscriptions...');

    // Use the official .on method with correct parameters to resolve both compile-time and runtime issues.
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
        
    _isInitialized = true;
    print('[RealtimeService] Subscriptions active.');
  }
}
