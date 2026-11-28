// Контроллер приёма вебхуков и интерфейс проверки подписи (F03, UC-02, UML class-services.puml).
import { activeSecrets, verify } from '../../../../../packages/webhook-signature/src/index.ts';
import type { SourceSecrets } from '../../../../../packages/webhook-signature/src/index.ts';
import { handleWebhook } from './receiveWebhook.ts';
import type { Deps, Reply } from './receiveWebhook.ts';

export interface SignatureVerifier {
  verifySource(source: SourceSecrets, rawBody: Buffer, header: string | undefined, now: number): boolean;
}

export class HmacSignatureVerifier implements SignatureVerifier {
  verifySource(source: SourceSecrets, rawBody: Buffer, header: string | undefined, now: number): boolean {
    return verify(activeSecrets(source, now), rawBody, header);
  }
}

export class WebhookController {
  private readonly deps: Deps;
  constructor(deps: Deps) {
    this.deps = deps;
  }

  ingest(sourceId: string, rawBody: Buffer, headers: Record<string, string | undefined>): Promise<Reply> {
    return handleWebhook(this.deps, sourceId, rawBody, headers);
  }
}
