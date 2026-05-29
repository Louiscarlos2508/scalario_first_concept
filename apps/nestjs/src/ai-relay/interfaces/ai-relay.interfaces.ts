export interface AiRelayRequest {
  tenantId: string;
  userId: string;
  surfaceId: string;
  intent: string;
  context?: {
    screen?: string;
    data?: Record<string, unknown>;
    previousMessages?: string[];
  };
}

export interface AiRelayResponse {
  surfaceId: string;
  messages: A2uiMessage[];
  model: string;
  degraded: boolean;
}

export interface A2uiMessage {
  version: string;
  [key: string]: unknown;
}

export interface A2uiCreateSurface {
  createSurface: {
    surfaceId: string;
    catalogId: string;
    theme?: Record<string, unknown>;
  };
}

export interface A2uiUpdateComponents {
  updateComponents: {
    surfaceId: string;
    components: A2uiComponent[];
  };
}

export interface A2uiUpdateDataModel {
  updateDataModel: {
    surfaceId: string;
    path?: string;
    value: unknown;
  };
}

export interface A2uiComponent {
  id: string;
  component: string;
  variant?: string;
  text?: string;
  value?: unknown;
  children?: string[];
  action?: Record<string, unknown>;
  [key: string]: unknown;
}
