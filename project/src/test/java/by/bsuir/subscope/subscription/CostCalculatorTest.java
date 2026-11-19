package by.bsuir.subscope.subscription;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.junit.jupiter.api.Test;

/** REQ-FUNC-009-3, REQ-FUNC-019: доля пользователя и стоимость в месяц и в год. */
class CostCalculatorTest {

    static String cents(BigDecimal v) {
        return v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    @Test
    void sharedSubscriptionCountsUserShare() {
        // «5,99 USD, ваша доля 1/4» → 1,50 в месяц
        assertEquals("1.50", cents(CostCalculator.monthlyShare(new BigDecimal("5.99"), BillingPeriod.MONTH, 4)));
    }

    @Test
    void singleParticipantIsPlainSubscription() {
        assertEquals("9.99", cents(CostCalculator.monthlyShare(new BigDecimal("9.99"), BillingPeriod.MONTH, 1)));
    }

    @Test
    void yearlyIsMonthlyTimesTwelve() {
        // годовая подписка 120 на 3 участников: 40 в год за долю → 3,33 в месяц → 40,00 в год
        assertEquals("3.33", cents(CostCalculator.monthlyShare(new BigDecimal("120"), BillingPeriod.YEAR, 3)));
        assertEquals("40.00", cents(CostCalculator.yearlyShare(new BigDecimal("120"), BillingPeriod.YEAR, 3)));
    }

    @Test
    void rejectsInvalidInput() {
        assertThrows(IllegalArgumentException.class, () -> CostCalculator.share(new BigDecimal("-1"), 1));
        assertThrows(IllegalArgumentException.class, () -> CostCalculator.share(BigDecimal.TEN, 0));
        assertThrows(IllegalArgumentException.class, () -> CostCalculator.share(BigDecimal.TEN, 11));
    }
}
