package by.bsuir.subscope.subscription;

import java.math.BigDecimal;
import java.util.Objects;

/**
 * Стоимость подписки для пользователя (алгоритм А2 SDD, SUP-RULE-01).
 *
 * <p>Доля пользователя в совместной подписке — цена, делённая на число участников (REQ-FUNC-019);
 * стоимость в месяц — доля, приведённая к месяцу по периоду списания. Результат не округляется:
 * округление до копеек выполняется один раз, при пересчёте в базовую валюту ({@code MoneyConverter}).
 */
public final class CostCalculator {

    public static final int MIN_PARTICIPANTS = 1;
    public static final int MAX_PARTICIPANTS = 10;

    private CostCalculator() {
    }

    /** Доля пользователя в цене за период. */
    public static BigDecimal share(BigDecimal price, int participants) {
        Objects.requireNonNull(price, "price");
        if (price.signum() < 0) {
            throw new IllegalArgumentException("Цена не может быть отрицательной: " + price);
        }
        if (participants < MIN_PARTICIPANTS || participants > MAX_PARTICIPANTS) {
            throw new IllegalArgumentException("Число участников должно быть от 1 до 10: " + participants);
        }
        return price.divide(BigDecimal.valueOf(participants), BillingPeriod.CALC);
    }

    /** Стоимость доли пользователя в месяц. */
    public static BigDecimal monthlyShare(BigDecimal price, BillingPeriod period, int participants) {
        Objects.requireNonNull(period, "period");
        return period.toMonthly(share(price, participants));
    }

    /** Стоимость доли пользователя в год: стоимость в месяц × 12 (REQ-FUNC-009-3). */
    public static BigDecimal yearlyShare(BigDecimal price, BillingPeriod period, int participants) {
        return monthlyShare(price, period, participants).multiply(BigDecimal.valueOf(12));
    }
}
