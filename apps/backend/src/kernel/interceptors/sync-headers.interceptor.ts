import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

/**
 * Ajoute `X-Sync-Timestamp` (ISO-8601 UTC) à toutes les réponses HTTP des
 * endpoints de sync (produits, catégories, contacts).
 *
 * ## Pourquoi un header plutôt que le body ?
 * Le Flutter client peut lire le header avant de parser le JSON — utile pour
 * mettre à jour le curseur `lastSync` même si la liste d'items est vide
 * (aucun changement depuis le dernier sync → 0 items mais timestamp avancé).
 *
 * ## Usage
 * ```typescript
 * @UseInterceptors(SyncHeadersInterceptor)
 * @Get('products')
 * async getProducts(...) { ... }
 * ```
 *
 * ## Scalabilité
 * L'interceptor est stateless et synchrone (le `tap` s'exécute après que
 * le handler ait résolu). Zéro overhead DB, zéro allocation mémoire en plus.
 */
@Injectable()
export class SyncHeadersInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const response = context.switchToHttp().getResponse();

    return next.handle().pipe(
      tap(() => {
        // Timestamp serveur autoritaire — le client l'utilise comme curseur
        // `since` pour le prochain delta pull (Fix 2 Flutter).
        response.setHeader('X-Sync-Timestamp', new Date().toISOString());
      }),
    );
  }
}
