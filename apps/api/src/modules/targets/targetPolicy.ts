// Реестр целей доставки (F08, UC-06, REQ-INT-003, REQ-INT-006).
// Действие правила ссылается на цель по имени, а не содержит URL: адреса,
// на которые RuleHook может отправлять POST, задаёт только администратор.
export type TargetInput = { name: string; baseUrl: string };
export type ValidationResult = { ok: true } | { ok: false; error: string };

const NAME_RE = /^[a-z][a-z0-9-]{1,31}$/;

export function validateTarget(t: TargetInput, allowedHosts: readonly string[]): ValidationResult {
  if (!NAME_RE.test(t.name)) return { ok: false, error: 'BAD_NAME' };
  let url: URL;
  try {
    url = new URL(t.baseUrl);
  } catch {
    return { ok: false, error: 'BAD_URL' };
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return { ok: false, error: 'BAD_PROTOCOL' };
  if (url.username || url.password) return { ok: false, error: 'CREDENTIALS_IN_URL' };
  if (!allowedHosts.includes(url.hostname)) return { ok: false, error: 'HOST_NOT_ALLOWED' };
  if (url.search || url.hash) return { ok: false, error: 'QUERY_NOT_ALLOWED' };
  return { ok: true };
}

/** Подстановка {{payload.a.b}} в путь действия с URL-кодированием значения. */
export function renderPath(template: string, event: Record<string, unknown>): string {
  if (!template.startsWith('/') || template.includes('..')) throw new Error('BAD_PATH');
  return template.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (_m, path: string) => {
    let v: any = event;
    for (const key of path.split('.')) v = v == null ? undefined : v[key];
    if (v === undefined || v === null || typeof v === 'object') throw new Error('MISSING_VALUE:' + path);
    return encodeURIComponent(String(v));
  });
}

export function joinUrl(baseUrl: string, path: string): string {
  return baseUrl.replace(/\/+$/, '') + path;
}
