package by.bsuir.subscope.rates;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.junit.jupiter.api.Test;

class ExchangeRateTest {

    static final LocalDate DAY = LocalDate.of(2026, 11, 19);

    @Test
    void unitPriceDividesByScale() {
        assertEquals(0, new BigDecimal("0.74538")
                .compareTo(new ExchangeRate("PLN", DAY, 10, new BigDecimal("7.4538")).bynPerUnit()));
        assertEquals(0, new BigDecimal("0.018806")
                .compareTo(new ExchangeRate("JPY", DAY, 100, new BigDecimal("1.8806")).bynPerUnit()));
    }

    @Test
    void rejectsInvalidScaleAndRate() {
        assertThrows(IllegalArgumentException.class, () -> new ExchangeRate("USD", DAY, 0, BigDecimal.ONE));
        assertThrows(IllegalArgumentException.class, () -> new ExchangeRate("USD", DAY, 1, BigDecimal.ZERO));
    }
}
