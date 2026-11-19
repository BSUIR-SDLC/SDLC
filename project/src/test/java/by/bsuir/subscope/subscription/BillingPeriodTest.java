package by.bsuir.subscope.subscription;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

import org.junit.jupiter.api.Test;

/** REQ-FUNC-009-3 (приведение к месяцу) и REQ-FUNC-017 (перенос даты списания). */
class BillingPeriodTest {

    static String cents(BigDecimal v) {
        return v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    @Test
    void monthlyFactors() {
        BigDecimal price = new BigDecimal("12.00");
        assertEquals("52.00", cents(BillingPeriod.WEEK.toMonthly(price)));   // 12 × 52 / 12
        assertEquals("12.00", cents(BillingPeriod.MONTH.toMonthly(price)));
        assertEquals("4.00", cents(BillingPeriod.QUARTER.toMonthly(price)));
        assertEquals("1.00", cents(BillingPeriod.YEAR.toMonthly(price)));
        assertEquals("8.33", cents(BillingPeriod.YEAR.toMonthly(new BigDecimal("99.99"))));
    }

    @Test
    void monthEndIsClampedAndRestored() {
        // пример REQ-FUNC-017: 31.01 → 28.02 → 31.03
        LocalDate feb = BillingPeriod.MONTH.next(LocalDate.of(2027, 1, 31), 31);
        assertEquals(LocalDate.of(2027, 2, 28), feb);
        assertEquals(LocalDate.of(2027, 3, 31), BillingPeriod.MONTH.next(feb, 31));
    }

    @Test
    void leapYearFebruary() {
        assertEquals(LocalDate.of(2028, 2, 29), BillingPeriod.MONTH.next(LocalDate.of(2028, 1, 31), 31));
        assertEquals(LocalDate.of(2029, 2, 28), BillingPeriod.YEAR.next(LocalDate.of(2028, 2, 29), 29));
    }

    @Test
    void otherPeriods() {
        assertEquals(LocalDate.of(2026, 11, 26), BillingPeriod.WEEK.next(LocalDate.of(2026, 11, 19), 19));
        assertEquals(LocalDate.of(2027, 2, 28), BillingPeriod.QUARTER.next(LocalDate.of(2026, 11, 30), 30));
        assertEquals(LocalDate.of(2027, 11, 19), BillingPeriod.YEAR.next(LocalDate.of(2026, 11, 19), 19));
    }

    @Test
    void catchesUpMissedPeriods() {
        // сервер не работал: дата 05.09, сегодня 19.11 → 05.12
        LocalDate today = LocalDate.of(2026, 11, 19);
        assertEquals(LocalDate.of(2026, 12, 5), BillingPeriod.MONTH.nextOnOrAfter(LocalDate.of(2026, 9, 5), 5, today));
        // дата сегодня — не переносится
        assertEquals(today, BillingPeriod.MONTH.nextOnOrAfter(today, 19, today));
    }

    @Test
    void rejectsInvalidAnchorDay() {
        assertThrows(IllegalArgumentException.class, () -> BillingPeriod.MONTH.next(LocalDate.of(2026, 1, 1), 32));
    }
}
