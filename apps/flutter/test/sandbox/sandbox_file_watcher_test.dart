import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/sandbox/sandbox_file_watcher.dart';

void main() {
  test('PollingFileWatcher fires onChange when signature changes', () async {
    int signature = 0;
    int notifications = 0;
    final watcher = PollingFileWatcher(
      readSignature: () async => '${signature++}',
      pollInterval: const Duration(milliseconds: 30),
    );
    await watcher.start('/tmp/fake.json', () => notifications++);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await watcher.stop();
    expect(notifications, greaterThan(0));
  });

  test('NoopFileWatcher never fires', () async {
    const watcher = NoopFileWatcher();
    int notifications = 0;
    await watcher.start('/anything', () => notifications++);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await watcher.stop();
    expect(notifications, 0);
  });
}
