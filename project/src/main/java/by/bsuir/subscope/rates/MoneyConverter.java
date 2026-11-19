package by.bsuir.subscope.rates;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Objects;

/**
 * Пересчёт сумм между валютами по курсу НБ РБ — алгоритм А1 SDD, прецедент UC-24.
 *
 * <p>Перевод всегда выполняется через BYN (REQ-FUNC-013): {@code сумма × r(from) / r(to)}, где
 * {@code r(c)} — стоимость единицы валюты в BYN на последнюю дату, не позже даты расчёта; {@code r(BYN) = 1}.
 * Промежуточные вычисления — с точностью 10 значащих цифр, округление до копеек — только в результате.
 */
public class MoneyConverter {

    /** Национальная валюта: курс к ней всегда равен 1. */
    public static final String BYN = "BYN";
    /** Курс старше этого числа дней сопровождается предупреждением (REQ-REL-001). */
    public static final int STALE_AFTER_DAYS = 3;

    private final RateTable rates;

    public MoneyConverter(RateTable rates) {
        this.rates = Objects.requireNonNull(rates, "rates");
    }

    /**
     * Результат пересчёта.
     *
     * @param money    сумма в целевой валюте, округлённая до копеек
     * @param rateDate дата использованного курса (более старого из двух); {@code null}, если курс не нужен
     * @param stale    курс старше {@value #STALE_AFTER_DAYS} дней относительно даты расчёта
     */
    public record Converted(Money money, LocalDate rateDate, boolean stale) {
    }

    /**
     * @throws RateUnavailableException если для одной из валют нет курса ни на одну дату не позже {@code onDate}
     */
    public Converted convert(Money amount, String target, LocalDate onDate) {
        Objects.requireNonNull(amount, "amount");
        Objects.requireNonNull(target, "target");
        Objects.requireNonNull(onDate, "onDate");
        if (amount.currency().equals(target)) {
            return new Converted(amount, null, false);
        }
        ExchangeRate from = rateOf(amount.currency(), onDate);
        ExchangeRate to = rateOf(target, onDate);

        BigDecimal byn = amount.amount();
        if (from != null) {
            byn = byn.multiply(from.bynPerUnit(), ExchangeRate.CALC);
        }
        BigDecimal result = byn;
        if (to != null) {
            result = byn.divide(to.bynPerUnit(), ExchangeRate.CALC);
        }

        LocalDate rateDate = olderOf(from, to);
        boolean stale = ChronoUnit.DAYS.between(rateDate, onDate) > STALE_AFTER_DAYS;
        return new Converted(new Money(result, target), rateDate, stale);
    }

    /** Курс валюты или {@code null} для BYN. */
    private ExchangeRate rateOf(String currency, LocalDate onDate) {
        if (BYN.equals(currency)) {
            return null;
        }
        return rates.latestOnOrBefore(currency, onDate)
                .orElseThrow(() -> new RateUnavailableException(currency));
    }

    private static LocalDate olderOf(ExchangeRate a, ExchangeRate b) {
        if (a == null) {
            return b.date();
        }
        if (b == null) {
            return a.date();
        }
        return a.date().isBefore(b.date()) ? a.date() : b.date();
    }
}
