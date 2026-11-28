// Сервис управления источниками вебхуков и ротации секретов (F14, UC-05, BR-01).
import { randomBytes } from 'node:crypto';
import type { Source } from '../webhooks/receiveWebhook.ts';

export type StoredSource = Source & {
  name: string;
  allowedTypes: string[];
  rateLimitRps: number;
};

export interface SourceRepository {
  getSource(id: string): Promise<StoredSource | null>;
  listSources(): Promise<StoredSource[]>;
  saveSource(source: StoredSource): Promise<void>;
}

const SOURCE_ID_RE = /^[a-z][a-z0-9-]{1,31}$/;

export class SourceService {
  private readonly repo: SourceRepository;
  constructor(repo: SourceRepository) {
    this.repo = repo;
  }

  async createSource(input: { id: string; name: string; allowedTypes?: string[]; rateLimitRps?: number }): Promise<{ source: StoredSource; plainSecret: string }> {
    if (!SOURCE_ID_RE.test(input.id)) throw new Error('BAD_SOURCE_ID');
    const existing = await this.repo.getSource(input.id);
    if (existing) throw new Error('SOURCE_EXISTS');
    const plainSecret = randomBytes(24).toString('hex');
    const source: StoredSource = {
      id: input.id,
      name: input.name,
      secret: plainSecret,
      previousSecret: null,
      rotatedAt: null,
      allowedTypes: input.allowedTypes ?? ['*'],
      rateLimitRps: input.rateLimitRps ?? 50,
      enabled: true,
    };
    await this.repo.saveSource(source);
    return { source, plainSecret };
  }

  async rotateSecret(id: string, now: number): Promise<{ id: string; plainSecret: string; graceEndsAt: number }> {
    const src = await this.repo.getSource(id);
    if (!src) throw new Error('SOURCE_NOT_FOUND');
    const plainSecret = randomBytes(24).toString('hex');
    src.previousSecret = src.secret;
    src.secret = plainSecret;
    src.rotatedAt = now;
    await this.repo.saveSource(src);
    return { id, plainSecret, graceEndsAt: now + 24 * 60 * 60 * 1000 };
  }

  async setEnabled(id: string, enabled: boolean): Promise<StoredSource> {
    const src = await this.repo.getSource(id);
    if (!src) throw new Error('SOURCE_NOT_FOUND');
    src.enabled = enabled;
    await this.repo.saveSource(src);
    return src;
  }

  listSources(): Promise<StoredSource[]> {
    return this.repo.listSources();
  }
}
