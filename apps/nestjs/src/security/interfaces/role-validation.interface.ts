export interface RoleValidationResult {
  valid: string[];
  invalid: string[];
}

export interface RoleConflictUser {
  id: string;
  email: string;
}
