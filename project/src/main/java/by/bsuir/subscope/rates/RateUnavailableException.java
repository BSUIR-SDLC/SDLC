package by.bsuir.subscope.rates;

/** Для валюты нет ни одного сохранённого курса на дату расчёта (UC-24, поток Е1). */
public class RateUnavailableException extends RuntimeException {

    private final String currency;

    public RateUnavailableException(String currency) {
        super("Нет курса НБ РБ для валюты " + currency);
        this.currency = currency;
    }

    public String currency() {
        return currency;
    }
}
