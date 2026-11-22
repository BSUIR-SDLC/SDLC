export interface PromoRule {
  code: string;
  kind: 'percent' | 'fixed';
  /** Для percent — целое число процентов (1..100), для fixed — сумма в минимальных единицах. */
  value: number;
  minSubtotalMinor?: number;
}

export const PROMO_RULES: PromoRule[] = [
  { code: 'WELCOME10', kind: 'percent', value: 10 },
  { code: 'SAVE5', kind: 'fixed', value: 500, minSubtotalMinor: 2000 },
];

export type PromoResult =
  | { ok: true; code: string; discountMinor: number; totalMinor: number }
  | { ok: false; reason: 'EMPTY_CODE' | 'UNKNOWN_CODE' | 'MIN_SUBTOTAL' | 'EMPTY_CART' };

/** Проверяет промокод и пересчитывает сумму; скидка не может превысить сумму корзины. */
export function applyPromo(codeInput: string, subtotalMinor: number, rules: PromoRule[] = PROMO_RULES): PromoResult {
  const code = codeInput.trim().toUpperCase();
  if (code === '') return { ok: false, reason: 'EMPTY_CODE' };
  if (subtotalMinor <= 0) return { ok: false, reason: 'EMPTY_CART' };
  const rule = rules.find((r) => r.code === code);
  if (!rule) return { ok: false, reason: 'UNKNOWN_CODE' };
  if (rule.minSubtotalMinor !== undefined && subtotalMinor < rule.minSubtotalMinor) {
    return { ok: false, reason: 'MIN_SUBTOTAL' };
  }
  const raw = rule.kind === 'percent' ? Math.floor((subtotalMinor * rule.value) / 100) : rule.value;
  const discountMinor = Math.min(raw, subtotalMinor);
  return { ok: true, code: rule.code, discountMinor, totalMinor: subtotalMinor - discountMinor };
}
