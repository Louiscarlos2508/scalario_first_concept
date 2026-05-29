import { Injectable, Logger } from '@nestjs/common';
import { MindEngineService } from '../../engines/mind/mind-engine.service';
import type { ScreenConfig, ComponentConfig } from '../interfaces';

interface A2uiComponent {
  id: string;
  component: string;
  variant?: string;
  text?: string;
  value?: unknown;
  children?: string[];
  action?: Record<string, unknown>;
  [key: string]: unknown;
}

interface A2uiUpdateComponents {
  surfaceId: string;
  components: A2uiComponent[];
}

@Injectable()
export class A2uiToScreenConfigService {
  private readonly logger = new Logger(A2uiToScreenConfigService.name);

  constructor(private readonly mind: MindEngineService) {}

  async generateScreenConfig(
    tenantId: string,
    screenId: string,
  ): Promise<ScreenConfig | null> {
    const result = await this.mind.generate({
      surfaceId: screenId,
      intent: `Générer l'écran "${screenId}" pour le tenant "${tenantId}" avec une disposition claire (KPIs en haut, contenu principal au centre, actions en bas). Utilise des composants business adaptés.`,
      engine: 'ui',
    });

    if (result.degraded || !result.text) {
      this.logger.warn(`MindEngine degraded for screen=${screenId}`);
      return null;
    }

    return this.parseA2uiToScreenConfig(result.text, screenId);
  }

  parseA2uiToScreenConfig(raw: string, screenId: string): ScreenConfig | null {
    try {
      const jsonMatch = raw.match(/\{[\s\S]*\}/);
      if (!jsonMatch) return null;

      const parsed = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
      const updateComponents = parsed.updateComponents as A2uiUpdateComponents | undefined;

      if (!updateComponents?.components) {
        this.logger.warn(`No updateComponents found in MindEngine output for screen=${screenId}`);
        return null;
      }

      const components = updateComponents.components;
      const componentMap = new Map(components.map((c) => [c.id, c]));

      const kpis: ComponentConfig[] = [];
      const main: ComponentConfig[] = [];
      const actions: ComponentConfig[] = [];

      for (const comp of components) {
        if (this.isKpiComponent(comp.component)) {
          kpis.push(this.toComponentConfig(comp, componentMap));
        } else if (this.isActionComponent(comp.component)) {
          actions.push(this.toComponentConfig(comp, componentMap));
        } else if (comp.id !== 'root' && !comp.children) {
          main.push(this.toComponentConfig(comp, componentMap));
        }
      }

      const rootComponent = components.find((c) => c.id === 'root');
      if (rootComponent?.children) {
        for (const childId of rootComponent.children) {
          const child = componentMap.get(childId);
          if (child && child.id !== 'root') {
            const alreadyInZone =
              kpis.some((c) => c.id === child.id) ||
              main.some((c) => c.id === child.id) ||
              actions.some((c) => c.id === child.id);
            if (!alreadyInZone) {
              if (this.isKpiComponent(child.component)) {
                kpis.push(this.toComponentConfig(child, componentMap));
              } else if (this.isActionComponent(child.component)) {
                actions.push(this.toComponentConfig(child, componentMap));
              } else {
                main.push(this.toComponentConfig(child, componentMap));
              }
            }
          }
        }
      }

      return {
        schema_version: '1.0.0',
        screen: screenId,
        zones: {
          kpis,
          main,
          aside: [],
          actions,
        },
      };
    } catch (err) {
      this.logger.error(`Failed to parse MindEngine output: ${(err as Error).message}`);
      return null;
    }
  }

  private toComponentConfig(
    comp: A2uiComponent,
    componentMap: Map<string, A2uiComponent>,
  ): ComponentConfig {
    const props: Record<string, unknown> & { children?: ComponentConfig[] } = {};

    for (const [key, value] of Object.entries(comp)) {
      if (key === 'id' || key === 'component' || key === 'children') continue;
      props[key] = value;
    }

    if (comp.children) {
      props.children = comp.children
        .map((childId) => componentMap.get(childId))
        .filter((c): c is A2uiComponent => !!c && c.id !== 'root')
        .map((c) => this.toComponentConfig(c, componentMap));
    }

    return {
      id: comp.id,
      type: comp.component,
      props: Object.keys(props).length > 0 ? props : undefined,
    };
  }

  private isKpiComponent(type: string): boolean {
    return ['KPICard', 'StatCard', 'ChartBar', 'ChartPie', 'ChartLine'].includes(type);
  }

  private isActionComponent(type: string): boolean {
    return ['Button', 'ButtonRow', 'FloatingActionButton'].includes(type);
  }
}
