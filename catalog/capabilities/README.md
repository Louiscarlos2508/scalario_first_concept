# `catalog/capabilities/` — Hardware/système (Scalario Sense)

**Créé par STORY-V14-006.** Catalogue des **capabilities** matérielles et système accessibles aux modules ERP : scanner, GPS, imprimante BT, NFC, voix, biométrie, paiement Mobile Money, webhooks…

## Sous-dossiers (par catégorie)

| Dossier | Capabilities |
|---|---|
| `input/` | barcode_scan, photo_capture, signature_capture, nfc_read, voice_input, document_scan |
| `output/` | printer_bluetooth, sms_send, share_file |
| `location/` | gps_position, gps_track |
| `auth/` | biometrie |
| `integration/` | webhook_send, http_call |
| `payment/` | wave_pay, orange_money, mtn_momo *(Phase 2 — V14-025)* |

## Format

Chaque capability est validée par `catalog/schemas/capability.schema.json` + loader `apps/nestjs/src/catalog-loader/loaders/capability-loader.ts`.

Exemple :
```json
{
  "schema_version": "1.0.0",
  "capability_id": "barcode_scan",
  "category": "input",
  "platform_support": { "ios": true, "android": true, "web": false },
  "permissions_required": ["CAMERA"],
  "fallback_strategy": "manual_input",
  "examples": [
    { "use_case": "scan code-barres médicament en officine", "scope": "vente.create" }
  ]
}
```

## Fallback

Le champ `fallback_strategy` indique le comportement quand la capability est indisponible sur le device :
- `disable` — bouton masqué
- `manual_input` — fallback vers saisie manuelle
- `skip` — étape sautée
- `error` — bloquer le flow avec message

## Phase 1 vs Phase 2

- **Phase 1** : structure créée, dossiers vides. Loader stub fonctionnel.
- **Phase 2** (V14-024) : implémentation Flutter de chaque capability + déclarations JSON.

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-024.md`
- Schema : `catalog/schemas/capability.schema.json`
