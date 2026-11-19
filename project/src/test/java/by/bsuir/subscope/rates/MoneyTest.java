package by.bsuir.subscope.rates;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;

class MoneyTest {

    @Test
    void roundsToKopecksHalfUp() {
        assertEquals(new BigDecimal("17.68"), new Money(new BigDecimal("17.675"), "BYN").amount());
        assertEquals(new BigDecimal("17.67"), new Money(new BigDecimal("17.6749"), "BYN").amount());
    }

    @Test
    void addsAndComparesSameCurrency() {
        Money sum = Money.of("5.99", "USD").plus(Money.of("4.01", "USD"));
        assertEquals(Money.of("10.00", "USD"), sum);
        assertTrue(sum.isGreaterThan(Money.of("9.99", "USD")));
        assertEquals(Money.of("1.50", "BYN"), Money.of("3", "BYN").minus(Money.of("1.5", "BYN")));
    }

    @Test
    void rejectsDifferentCurrencies() {
        assertThrows(IllegalArgumentException.class, () -> Money.of("1", "USD").plus(Money.of("1", "EUR")));
    }

    @Test
    void rejectsInvalidCurrencyCode() {
        assertThrows(IllegalArgumentException.class, () -> Money.of("1", "usd"));
        assertThrows(IllegalArgumentException.class, () -> Money.of("1", "RUBL"));
    }

    @Test
    void printsPlainAmountWithCurrency() {
        assertEquals("5.90 USD", Money.of("5.9", "USD").toString());
    }
}
