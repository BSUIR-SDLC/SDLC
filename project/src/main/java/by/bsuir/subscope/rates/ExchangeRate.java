package by.bsuir.subscope.rates;

import java.math.BigDecimal;
import java.math.MathContext;
import java.time.LocalDate;
import java.util.Objects;

/**
 * Официальный курс НБ РБ на дату: {@code officialRate} белорусских рублей за {@code scale} единиц валюты
 * (поля {@code Cur_OfficialRate} и {@code Cur_Scale} API, REQ-INT-002-2). Строка таблицы {@code exchange_rate}.
 */
public record ExchangeRate(String currency, LocalDate date, int scale, BigDecimal officialRate) {

    /** Точность промежуточных вычислений (SDD, 007-algorithm, А1). */
    static final MathContext CALC = new MathContext(10);

    public ExchangeRate {
        Objects.requireNonNull(currency, "currency");
        Objects.requireNonNull(date, "date");
        Objects.requireNonNull(officialRate, "officialRate");
        if (scale <= 0) {
            throw new IllegalArgumentException("Масштаб курса должен быть положительным: " + scale);
        }
        if (officialRate.signum() <= 0) {
            throw new IllegalArgumentException("Курс должен быть положительным: " + officialRate);
        }
    }

    /** Стоимость одной единицы валюты в BYN: {@code Cur_OfficialRate / Cur_Scale}. */
    public BigDecimal bynPerUnit() {
        return officialRate.divide(BigDecimal.valueOf(scale), CALC);
    }
}
