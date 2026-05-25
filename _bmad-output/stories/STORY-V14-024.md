# STORY-V14-024 : Scalario Sense — CapabilityRegistry Flutter (scan, GPS, camera, signature, NFC, print BT, biométrie)

**Epic :** EPIC-V14-016 — Scalario Sense
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-8 (Phase 2)
**Dépendances :** V14-006 (catalogue capabilities), STORY-012 v13 (Multi-plateforme)

---

## User Story

> **En tant qu'**utilisateur ERP qui scanne un code-barres, prend une photo, signe sur l'écran, lit un tag NFC, imprime un bon de livraison Bluetooth, ou s'authentifie biométriquement,
> **je veux** que toutes ces capacités hardware soient déclarées en JSON dans `catalog/capabilities/` et invokées de manière unifiée via `CapabilityRegistry.invoke(id, params)`,
> **so that** un pipeline Scalario Flow peut chaîner scan → datasource → calc → save → print **sans une ligne de code Dart spécifique au hardware**.

---

## Description

### Background

PRD v14 §9 + §11 — Scalario Sense est le 5ème engine. Catalogue de capabilities exposé en JSON :

```
catalog/capabilities/
├── input/  (barcode_scan, photo_capture, signature_capture, nfc_read, voice_input, document_scan)
├── output/ (printer_bluetooth, sms_send, share_file)
├── location/ (gps_position, gps_track)
├── auth/   (biometrie)
└── integration/ (webhook_send, http_call)
```

Chaque capability a une implémentation Flutter native (platform channels) avec mode dev (mocks) + mode prod (vrai hardware).

### Scope

**In scope :**
- `lib/core/sense/capability_registry.dart` — registry central
- 12 capabilities implémentées : barcode_scan, photo_capture, signature_capture, nfc_read, voice_input, document_scan, printer_bluetooth, sms_send, share_file, gps_position, gps_track, biometrie
- Mode dev (`kDebugMode`) : retourne mocks sans appeler hardware
- Mode prod : platform channels Android + iOS
- `CapabilityRegistry.invoke(id, params)` API unifiée
- `availability()` retourne map des capabilities disponibles → NestJS sait quoi proposer
- Tests widget + integration_test

**Out of scope :**
- Mobile Money (Wave/OM/MTN) — V14-025 (sous-story dédiée)
- Webhook send / http_call — V14-024 inclut juste l'interface, implémentation Phase 3 si besoin

---

## Acceptance Criteria

- [ ] **AC-01** — `CapabilityRegistry.invoke(id: 'barcode_scan', params)` → returns `ScanResult { raw, type, format }`.
- [ ] **AC-02** — `CapabilityRegistry.invoke(id: 'photo_capture', params)` → returns `{ image_base64, path }`.
- [ ] **AC-03** — `CapabilityRegistry.invoke(id: 'signature_capture', params: { label })` → returns `{ image_base64, timestamp, signed }`.
- [ ] **AC-04** — `CapabilityRegistry.invoke(id: 'nfc_read', params)` → returns `{ tag_id, data }`.
- [ ] **AC-05** — `CapabilityRegistry.invoke(id: 'printer_bluetooth', params: { template, data, copies })` → imprime via BT.
- [ ] **AC-06** — `CapabilityRegistry.invoke(id: 'gps_position', params)` → returns `{ lat, lng, accuracy }`.
- [ ] **AC-07** — `CapabilityRegistry.invoke(id: 'biometrie', params)` → returns `{ verified: bool }`.
- [ ] **AC-08** — Mode dev : retourne mock immédiat si `kDebugMode` (ex: scan retourne 'PROD-00123' QR).
- [ ] **AC-09** — Mode prod : permission Android/iOS demandée au runtime, erreur explicite si refusée.
- [ ] **AC-10** — `CapabilityRegistry.availability()` retourne `{ barcode_scan: true, biometrie: false, ... }` → NestJS lit pour adapter UI.
- [ ] **AC-11** — Tests : 12 capabilities testées en mode dev + 3 en mode prod (Android emulator + iOS simulator).

---

## Technical Notes

### Architecture 3 couches

```dart
// Couche 1 — Contrat abstrait
abstract class Capability<I, O> {
  String get id;
  bool get isAvailable;
  Future<O> execute(I input);
  O get mock;  // utilisé en dev/test
}

// Couche 2 — Implémentation concrète
class ScannerCapability extends Capability<void, ScanResult> {
  String get id => 'scanner';
  bool get isAvailable => Platform.isAndroid || Platform.isIOS;
  Future<ScanResult> execute(void _) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) throw CapabilityError('permission_denied');
    final result = await MobileScannerController().scan();
    return ScanResult(raw: result.rawValue, type: 'QR');
  }
  ScanResult get mock => ScanResult(raw: 'PROD-00123', type: 'QR');
}

// Couche 3 — Registre avec mode dev
class CapabilityRegistry {
  static bool devMode = kDebugMode;
  static Future<dynamic> invoke(String id, Map params) async {
    final cap = _capabilities[id];
    if (cap == null) throw CapabilityNotFound(id);
    if (devMode) return cap.mock;
    if (!cap.isAvailable) throw CapabilityUnavailable(id);
    return cap.execute(params);
  }
}
```

### Edge cases

- Permission refusée → `CapabilityError('permission_denied')` ; UI affiche dialog "Activer camera dans réglages"
- Bluetooth off → `CapabilityError('bluetooth_off')` ; pipeline `on_error: notify`
- Hardware absent (ex: NFC sur iPhone < 7) → `availability().nfc_read = false`, UI cache le bouton

---

## Dependencies

- **Prérequis :** V14-006 (catalog/capabilities/), STORY-012 v13 (multi-plateforme Flutter)
- **Stories bloquées :** V14-023 (Scalario Form utilise capabilities dans fields), V14-025 (Mobile Money)

---

## Definition of Done

- [ ] CapabilityRegistry + 12 capabilities Flutter
- [ ] Mode dev (mocks) + mode prod (platform channels)
- [ ] Tests widget + 3 integration tests devices
- [ ] Docs `docs/scalario-sense.md`
- [ ] sprint-status.yaml V14-024 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| CapabilityRegistry + abstract Capability | 1.0 |
| 12 capabilities implémentation (~30 min/capability) | 5.0 |
| Mode dev/prod toggle + availability map | 0.5 |
| Tests widget + integration | 1.0 |
| Docs + permissions Android/iOS manifest | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
