package by.bsuir.subscope.rates;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Денежная сумма в валюте — неизменяемый объект-значение (SDD, 010-patterns, Value Object).
 *
 * <p>Для денег используется только {@link BigDecimal}; сумма хранится с точностью до копеек
 * (2 знака, округление «половина вверх» — SUP-RULE-02). Сложение сумм в разных валютах запрещено.
 *
 * @param amount   сумма, не {@code null}
 * @param currency трёхбуквенный код валюты ISO 4217 в верхнем регистре (BYN, USD, …)
 */
public record Money(BigDecimal amount, String currency) {

    /** Число знаков после запятой у денежных сумм. */
    public static final int SCALE = 2;
    /** Режим округления денежных сумм. */
    public static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private static final Pattern CODE = Pattern.compile("[A-Z]{3}");

    public Money {
        Objects.requireNonNull(amount, "amount");
        Objects.requireNonNull(currency, "currency");
        if (!CODE.matcher(currency).matches()) {
            throw new IllegalArgumentException("Код валюты должен состоять из трёх латинских букв: " + currency);
        }
        amount = amount.setScale(SCALE, ROUNDING);
    }

    public static Money of(String amount, String currency) {
        return new Money(new BigDecimal(amount), currency);
    }

    public static Money zero(String currency) {
        return new Money(BigDecimal.ZERO, currency);
    }

    public Money plus(Money other) {
        requireSameCurrency(other);
        return new Money(amount.add(other.amount), currency);
    }

    public Money minus(Money other) {
        requireSameCurrency(other);
        return new Money(amount.subtract(other.amount), currency);
    }

    public boolean isGreaterThan(Money other) {
        requireSameCurrency(other);
        return amount.compareTo(other.amount) > 0;
    }

    private void requireSameCurrency(Money other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException("Суммы в разных валютах: " + currency + " и " + other.currency);
        }
    }

    @Override
    public String toString() {
        return amount.toPlainString() + " " + currency;
    }
}
