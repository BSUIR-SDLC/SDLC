package by.bsuir.subscope.rates;

import java.time.LocalDate;
import java.util.Optional;

/**
 * Источник сохранённых курсов (таблица {@code exchange_rate}, ADR-0004).
 * В тестах подменяется заполненной в памяти реализацией.
 */
public interface RateTable {

    /** Курс валюты на последнюю дату, не позже {@code date}; пусто, если курсов этой валюты нет. */
    Optional<ExchangeRate> latestOnOrBefore(String currency, LocalDate date);
}
