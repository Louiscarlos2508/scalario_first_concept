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

export interface ScreenConfig {
  schema_version: string;
  screen: string;
  layout: Record<string, unknown>;
  zones: Record<string, unknown>;
  data?: Record<string, unknown>;
  rules?: unknown[];
  states?: Record<string, unknown>;
  i18n?: Record<string, unknown>;
  capabilities?: Record<string, unknown>;
  [key: string]: unknown;
}