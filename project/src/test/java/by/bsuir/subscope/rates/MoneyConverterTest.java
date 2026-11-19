package by.bsuir.subscope.rates;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

/** Алгоритм А1 SDD; курсы — из ответа API НБ РБ на 19.11.2026 (POC). */
class MoneyConverterTest {

    static final LocalDate NOV_19 = LocalDate.of(2026, 11, 19);

    /** Таблица курсов в памяти вместо базы данных. */
    static class InMemoryRates implements RateTable {
        final List<ExchangeRate> rows = new ArrayList<>();

        InMemoryRates add(String currency, LocalDate date, int scale, String rate) {
            rows.add(new ExchangeRate(currency, date, scale, new BigDecimal(rate)));
            return this;
        }

        @Override
        public Optional<ExchangeRate> latestOnOrBefore(String currency, LocalDate date) {
            return rows.stream()
                    .filter(r -> r.currency().equals(currency) && !r.date().isAfter(date))
                    .max(Comparator.comparing(ExchangeRate::date));
        }
    }

    final InMemoryRates rates = new InMemoryRates()
            .add("USD", NOV_19, 1, "2.9950")
            .add("EUR", NOV_19, 1, "3.2876")
            .add("PLN", NOV_19, 10, "7.4538")
            .add("RUB", NOV_19, 100, "3.6533")
            .add("USD", LocalDate.of(2026, 10, 1), 1, "3.0207");
    final MoneyConverter converter = new MoneyConverter(rates);

    @Test
    void sameCurrencyIsReturnedUnchanged() {
        MoneyConverter.Converted c = converter.convert(Money.of("5.99", "USD"), "USD", NOV_19);
        assertEquals(Money.of("5.99", "USD"), c.money());
        assertNull(c.rateDate());
    }

    @Test
    void foreignToByn() {
        // 5,99 × 2,9950 = 17,94005 → 17,94
        MoneyConverter.Converted c = converter.convert(Money.of("5.99", "USD"), "BYN", NOV_19);
        assertEquals(Money.of("17.94", "BYN"), c.money());
        assertEquals(NOV_19, c.rateDate());
        assertFalse(c.stale());
    }

    @Test
    void exampleFromSdd() {
        // SDD, 007-algorithm: 5,99 USD при курсе 2,9512 → 17,68 BYN
        InMemoryRates t = new InMemoryRates().add("USD", NOV_19, 1, "2.9512");
        assertEquals(Money.of("17.68", "BYN"),
                new MoneyConverter(t).convert(Money.of("5.99", "USD"), "BYN", NOV_19).money());
    }

    @Test
    void takesScaleIntoAccount() {
        // 100 PLN × (7,4538 / 10) = 74,538 → 74,54 BYN; 1000 RUB × (3,6533 / 100) = 36,533 → 36,53 BYN
        assertEquals(Money.of("74.54", "BYN"), converter.convert(Money.of("100", "PLN"), "BYN", NOV_19).money());
        assertEquals(Money.of("36.53", "BYN"), converter.convert(Money.of("1000", "RUB"), "BYN", NOV_19).money());
    }

    @Test
    void bynToForeign() {
        // 100 / 2,9950 = 33,388… → 33,39 USD
        assertEquals(Money.of("33.39", "USD"), converter.convert(Money.of("100", "BYN"), "USD", NOV_19).money());
    }

    @Test
    void crossRateGoesThroughByn() {
        // 10 EUR → 32,876 BYN → / 2,9950 = 10,9769… → 10,98 USD (REQ-FUNC-013)
        assertEquals(Money.of("10.98", "USD"), converter.convert(Money.of("10", "EUR"), "USD", NOV_19).money());
        // 499 RUB → 18,229967 BYN → / 3,2876 = 5,5450… → 5,55 EUR
        assertEquals(Money.of("5.55", "EUR"), converter.convert(Money.of("499", "RUB"), "EUR", NOV_19).money());
    }

    @Test
    void usesRateOnPastDate() {
        // на 15.10.2026 есть только курс от 01.10.2026: 5,99 × 3,0207 = 18,093993 → 18,09
        MoneyConverter.Converted c = converter.convert(Money.of("5.99", "USD"), "BYN", LocalDate.of(2026, 10, 15));
        assertEquals(Money.of("18.09", "BYN"), c.money());
        assertEquals(LocalDate.of(2026, 10, 1), c.rateDate());
        assertTrue(c.stale(), "курс старше 3 дней помечается как устаревший (REQ-REL-001)");
    }

    @Test
    void reportsOlderOfTwoRateDates() {
        InMemoryRates t = new InMemoryRates()
                .add("USD", NOV_19, 1, "2.9950")
                .add("EUR", LocalDate.of(2026, 11, 17), 1, "3.2800");
        MoneyConverter.Converted c = new MoneyConverter(t).convert(Money.of("1", "USD"), "EUR", NOV_19);
        assertEquals(LocalDate.of(2026, 11, 17), c.rateDate());
        assertFalse(c.stale(), "2 дня — ещё не устаревший курс");
    }

    @Test
    void failsWhenNoRateAtAll() {
        RateUnavailableException e = assertThrows(RateUnavailableException.class,
                () -> converter.convert(Money.of("1", "GBP"), "BYN", NOV_19));
        assertEquals("GBP", e.currency());
    }

    @Test
    void failsWhenOnlyFutureRateExists() {
        assertThrows(RateUnavailableException.class,
                () -> converter.convert(Money.of("1", "EUR"), "BYN", LocalDate.of(2026, 11, 1)));
    }
}
