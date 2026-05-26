import { Repository } from 'typeorm';
import { Tenant } from '../core/auth/entities/tenant.entity';

/**
 * Normalise un nom de tenant en handle valide (lowercase, alphanumeric + dashes).
 * Supprime les accents, les caracteres speciaux, et tronque a max 30 chars
 * pour laisser la place a la deduplication (`-2`, `-3`, ...).
 */
function slugify(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 30);
}

/**
 * Genere un handle unique pour un tenant.
 * Si le handle de base est deja pris, ajoute `-2`, `-3`, etc. jusqu'a trouver un libre.
 * Retry max 100 pour eviter boucle infinie.
 */
export async function generateHandle(
  name: string,
  repo: Repository<Tenant>,
): Promise<string> {
  const base = slugify(name);
  let candidate = base;
  let n = 2;

  while (n < 100) {
    const existing = await repo.findOne({
      where: { handle: candidate },
      select: ['id'],
    });
    if (!existing) return candidate;
    candidate = `${base}-${n}`;
    n++;
  }

  throw new Error(`Failed to generate unique handle for name after 100 attempts: ${name}`);
}
