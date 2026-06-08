import { Injectable, Logger } from '@nestjs/common';
import { DynamicObjectSchema } from './entities/dynamic-object-schema.entity';

@Injectable()
export class BduiGeneratorService {
  private readonly logger = new Logger(BduiGeneratorService.name);

  /**
   * Génère l'écran BDUI de type "list" (Data Grid) pour un objet dynamique.
   */
  generateListScreen(schema: DynamicObjectSchema): Record<string, any> {
    const columns = Object.keys(schema.schema || {}).map((key) => ({
      key,
      title: key.charAt(0).toUpperCase() + key.slice(1),
    }));

    return {
      schema_version: '1.0.0',
      screen: `${schema.name.toLowerCase()}_list`,
      layout: 'list',
      title: schema.plural_name,
      zones: {
        main: [
          {
            type: 'ScaDataGrid',
            props: {
              columns,
            },
            source: {
              type: 'module_data',
              module_id: `dynamic_${schema.name.toLowerCase()}`,
            },
            actions: [
              {
                registry: 'canvas',
                fn: 'navigate',
                inputs: {
                  screen: `${schema.name.toLowerCase()}_form`,
                  params: { id: '$row.id' },
                },
              },
            ],
          },
        ],
        actions: [
          {
            type: 'FAB',
            props: {
              label: `Nouveau ${schema.name}`,
              icon_code_point: 57669,
            },
            actions: [
              {
                registry: 'canvas',
                fn: 'navigate',
                inputs: {
                  screen: `${schema.name.toLowerCase()}_form`,
                },
              },
            ],
          },
        ],
      },
    };
  }

  /**
   * Génère l'écran BDUI de type "form" pour créer ou éditer un objet dynamique.
   */
  generateFormScreen(schema: DynamicObjectSchema): Record<string, any> {
    const formFields = Object.entries(schema.schema || {}).map(([key, def]) => {
      // Mapping simple du type JSONB vers un composant ScaInput
      const isNumber = def.type === 'number';
      return {
        type: 'ScaInput',
        props: {
          name: key,
          label: key.charAt(0).toUpperCase() + key.slice(1),
          type: isNumber ? 'number' : 'text',
          required: def.required === true,
        },
      };
    });

    return {
      schema_version: '1.0.0',
      screen: `${schema.name.toLowerCase()}_form`,
      layout: 'form',
      title: `Éditer ${schema.name}`,
      zones: {
        main: [
          {
            type: 'ScaRecordSplitView',
            props: {},
            children: [
              {
                type: 'FormSection',
                props: {
                  title: 'Informations Générales',
                },
                children: formFields,
              }
            ],
          },
        ],
        actions: [
          {
            type: 'ScaButton',
            props: {
              label: 'Enregistrer',
              variant: 'solid',
            },
            actions: [
              {
                registry: 'form',
                fn: 'submit',
                inputs: {
                  target: `dynamic_${schema.name.toLowerCase()}`,
                },
              },
            ],
          },
        ],
      },
    };
  }

  /**
   * Génère l'écran BDUI de type "kanban" pour un objet dynamique.
   */
  generateKanbanScreen(schema: DynamicObjectSchema): Record<string, any> {
    return {
      schema_version: '1.0.0',
      screen: `${schema.name.toLowerCase()}_kanban`,
      layout: 'board',
      title: `${schema.plural_name} (Kanban)`,
      zones: {
        main: [
          {
            type: 'ScaKanbanBoard',
            props: {
              group_by: 'status', // Par défaut, on suppose qu'il y a un champ status
            },
            source: {
              type: 'module_data',
              module_id: `dynamic_${schema.name.toLowerCase()}`,
            },
          },
        ],
      },
    };
  }
}
