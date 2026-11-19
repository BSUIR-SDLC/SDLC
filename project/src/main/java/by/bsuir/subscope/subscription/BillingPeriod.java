package by.bsuir.subscope.subscription;

import java.math.BigDecimal;
import java.math.MathContext;
import java.time.LocalDate;
import java.util.Objects;

/**
 * Период списания подписки (REQ-FUNC-004-3) и правила, которые от него зависят:
 * приведение цены к месяцу (REQ-FUNC-009-3, SUP-RULE-01) и перенос даты списания (REQ-FUNC-017, SUP-RULE-04).
 */
public enum BillingPeriod {

    WEEK(0) {
        @Override
        public BigDecimal toMonthly(BigDecimal price) {
            return price.multiply(BigDecimal.valueOf(52)).divide(BigDecimal.valueOf(12), CALC);
        }

        @Override
        public LocalDate next(LocalDate chargeDate, int anchorDay) {
            return chargeDate.plusWeeks(1);
        }
    },
    MONTH(1),
    QUARTER(3),
    YEAR(12);

    static final MathContext CALC = new MathContext(10);

    private final int months;

    BillingPeriod(int months) {
        this.months = months;
    }

    /** Цена за период, приведённая к месяцу: неделя × 52/12, месяц × 1, квартал / 3, год / 12. */
    public BigDecimal toMonthly(BigDecimal price) {
        Objects.requireNonNull(price, "price");
        return price.divide(BigDecimal.valueOf(months), CALC);
    }

    /**
     * Следующая дата списания после {@code chargeDate}.
     *
     * <p>Для периодов в месяцах берётся число {@code anchorDay} (исходное число списания), а если в целевом
     * месяце его нет — последний день месяца: 31.01 → 28.02 → 31.03.
     *
     * @param anchorDay исходное число месяца списания, 1…31
     */
    public LocalDate next(LocalDate chargeDate, int anchorDay) {
        Objects.requireNonNull(chargeDate, "chargeDate");
        if (anchorDay < 1 || anchorDay > 31) {
            throw new IllegalArgumentException("Число месяца должно быть от 1 до 31: " + anchorDay);
        }
        LocalDate month = chargeDate.withDayOfMonth(1).plusMonths(months);
        return month.withDayOfMonth(Math.min(anchorDay, month.lengthOfMonth()));
    }

    /**
     * Переносит дату вперёд на нужное число периодов, пока она не станет не раньше {@code today}
     * (ежедневная задача UC-22 после простоя сервера переносит дату за несколько пропущенных периодов).
     */
    public LocalDate nextOnOrAfter(LocalDate chargeDate, int anchorDay, LocalDate today) {
        LocalDate date = chargeDate;
        while (date.isBefore(today)) {
            date = next(date, anchorDay);
        }
        return date;
    }
}
