package by.bsuir.subscope.rates;

import java.time.LocalDate;
import java.util.List;

/**
 * Адаптер API официальных курсов НБ РБ (SDD, 010-patterns, Adapter; ADR-0004).
 * Интерфейс позволяет заменять обращение к сети заглушкой в тестах (SUP-SUPP-02).
 */
public interface NbrbClient {

    /**
     * Ежедневно устанавливаемые курсы на дату ({@code periodicity=0}).
     *
     * @throws NbrbUnavailableException при ошибке сети, тайм-ауте или некорректном ответе
     */
    List<ExchangeRate> dailyRates(LocalDate date);
}
