export interface VisibleIf {
  operator: string;
  value?: unknown;
}

export interface ComponentConfig {
  id?: string;
  type: string;
  props?: Record<string, unknown> & { children?: ComponentConfig[] };
  visible_if?: VisibleIf;
}

export interface ZoneConfig {
  kpis?: ComponentConfig[];
  main?: ComponentConfig[];
  aside?: ComponentConfig[];
  actions?: ComponentConfig[];
}

export interface ScreenConfig {
  schema_version: string;
  screen: string;
  zones: ZoneConfig;
  [key: string]: unknown;
}
