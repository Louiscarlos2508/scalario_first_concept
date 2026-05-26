import { generateHandle } from '../handle-generator';
import { Repository } from 'typeorm';
import { Tenant } from '../../core/auth/entities/tenant.entity';

describe('handle-generator', () => {
  describe('generateHandle', () => {
    function mockRepo(existingHandles: string[]): Repository<Tenant> {
      return {
        findOne: jest.fn().mockImplementation((opts: { where: { handle: string } }) => {
          if (existingHandles.includes(opts.where.handle)) {
            return Promise.resolve({ id: 'existing' });
          }
          return Promise.resolve(null);
        }),
      } as any;
    }

    it('generates handle from name (simple)', async () => {
      const repo = mockRepo([]);
      const handle = await generateHandle('Blandine Shop', repo);
      expect(handle).toBe('blandine-shop');
    });

    it('slugifies accented names', async () => {
      const repo = mockRepo([]);
      const handle = await generateHandle('Pharmacie Kossyam', repo);
      expect(handle).toBe('pharmacie-kossyam');
    });

    it('truncates long names to 30 chars', async () => {
      const repo = mockRepo([]);
      const handle = await generateHandle(
        'Super Long Company Name That Exceeds Thirty Characters Limit',
        repo,
      );
      expect(handle.length).toBeLessThanOrEqual(30);
      expect(handle).toBe('super-long-company-name-that-e');
    });

    it('deduplicates with -2, -3 suffix', async () => {
      const repo = mockRepo(['blandine-shop']);
      const handle = await generateHandle('Blandine Shop', repo);
      expect(handle).toBe('blandine-shop-2');
    });

    it('increments deduplication counter', async () => {
      const repo = mockRepo(['blandine-shop', 'blandine-shop-2']);
      const handle = await generateHandle('Blandine Shop', repo);
      expect(handle).toBe('blandine-shop-3');
    });

    it('lowercases and replaces special chars', async () => {
      const repo = mockRepo([]);
      const handle = await generateHandle('Blandine! Shop & Co.', repo);
      expect(handle).toBe('blandine-shop-co');
    });
  });
});
