import { z } from 'zod';

export const ValidateTemplateSchema = z.object({
  content: z.unknown({
    required_error: 'Le champ content est requis',
    invalid_type_error: 'content doit être un objet JSON',
  }),
  type: z.enum(['domain', 'module', 'fusion', 'screen', 'workflow'], {
    required_error: 'Le champ type est requis',
    invalid_type_error:
      "type doit être l'une des valeurs : domain, module, fusion, screen, workflow",
  }),
});

export type ValidateTemplateDto = z.infer<typeof ValidateTemplateSchema>;
