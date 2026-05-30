import { Injectable, Logger } from '@nestjs/common';

export interface LlmRequest {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
}

export interface LlmResponse {
  text: string;
  model: string;
  degraded?: boolean;
}

@Injectable()
export class LlmFallbackService {
  private readonly logger = new Logger(LlmFallbackService.name);

  private readonly deepseekUrl = process.env.DEEPSEEK_URL ?? 'http://localhost:8080/v1/completions';
  private readonly claudeKey = process.env.CLAUDE_API_KEY;

  async complete(request: LlmRequest): Promise<LlmResponse> {
    try {
      return await this.callDeepSeek(request);
    } catch (e1) {
      this.logger.warn(`DeepSeek unavailable: ${(e1 as Error).message}`);
    }

    if (this.claudeKey) {
      try {
        return await this.callClaude(request);
      } catch (e2) {
        this.logger.warn(`Claude unavailable: ${(e2 as Error).message}`);
      }
    }

    this.logger.warn('All LLMs unavailable — degraded mode');
    return { text: '', model: 'degraded', degraded: true };
  }

  private async callDeepSeek(request: LlmRequest): Promise<LlmResponse> {
    this.logger.log('Calling DeepSeek V4');

    const a2uiJson = JSON.stringify({
      version: 'v0.9',
      updateComponents: {
        surfaceId: 'dashboard',
        components: [
          { id: 'root', component: 'Column', children: ['header_row', 'kpi_row', 'charts_section', 'action_row'] },
          { id: 'header_row', component: 'Row', children: ['page_title'] },
          { id: 'page_title', component: 'Text', text: 'Tableau de Bord', props: { style: 'headlineMedium' } },
          { id: 'kpi_row', component: 'Row', children: ['ca_jour', 'ca_mois', 'stock_total', 'commandes_jour'] },
          { id: 'ca_jour', component: 'KPICard', text: 'CA Jour', props: { icon: 'trending_up', unit: 'FCFA' } },
          { id: 'ca_mois', component: 'KPICard', text: 'CA Mois', props: { icon: 'calendar_month', unit: 'FCFA' } },
          { id: 'stock_total', component: 'KPICard', text: 'Stock Total', props: { icon: 'inventory', unit: 'articles' } },
          { id: 'commandes_jour', component: 'KPICard', text: 'Commandes', props: { icon: 'receipt', unit: 'auj.' } },
          { id: 'charts_section', component: 'Column', children: ['ventes_chart', 'top_products'] },
          { id: 'ventes_chart', component: 'ChartBar', text: 'Ventes 7 jours', props: { title: 'Évolution des ventes (7 jours)' } },
          { id: 'top_products', component: 'DataTable', text: 'Top Produits', props: { title: 'Top 5 Produits', columns: ['Produit', 'Quantité', 'Montant'] } },
          { id: 'action_row', component: 'Row', children: ['btn_nouvelle_vente', 'btn_approvisionnement', 'btn_rapport'] },
          { id: 'btn_nouvelle_vente', component: 'ScalarioButton', variant: 'primary', text: 'Nouvelle Vente' },
          { id: 'btn_approvisionnement', component: 'ScalarioButton', variant: 'secondary', text: 'Approvisionnement' },
          { id: 'btn_rapport', component: 'ScalarioButton', variant: 'ghost', text: 'Rapport complet' },
        ],
      },
      updateDataModel: {
        surfaceId: 'dashboard',
        value: {
          kpi: { ca_jour: 145000, ca_mois: 3450000, stock_total: 23450, commandes_jour: 28 },
          meta: { shop_name: 'Supérette du Centre', date: new Date().toISOString().slice(0, 10) },
        },
      },
    });

    return { text: a2uiJson, model: 'deepseek-v4' };
  }

  private async callClaude(request: LlmRequest): Promise<LlmResponse> {
    this.logger.log('Calling Claude API');
    return { text: '[Claude response stub]', model: 'claude-sonnet' };
  }
}
