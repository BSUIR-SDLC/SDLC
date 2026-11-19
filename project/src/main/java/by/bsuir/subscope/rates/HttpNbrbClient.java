package by.bsuir.subscope.rates;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Клиент API НБ РБ: {@code GET https://api.nbrb.by/exrates/rates?periodicity=0&ondate=ГГГГ-ММ-ДД}
 * (REQ-INT-002-2). Тайм-аут — 5 секунд; повторы выполняет вызывающая задача загрузки курсов (UC-20).
 *
 * <p>Проверено в POC 19.11.2026 (задача T-03.1, REQ-POC-001): на текущую дату и на 01.10.2026 API
 * возвращает 30 валют; используются поля {@code Cur_Abbreviation}, {@code Cur_Scale},
 * {@code Cur_OfficialRate}, {@code Date}. Образцы ответов — {@code src/test/resources/nbrb}.
 */
public class HttpNbrbClient implements NbrbClient {

    public static final URI DEFAULT_BASE = URI.create("https://api.nbrb.by/exrates/rates");
    static final Duration TIMEOUT = Duration.ofSeconds(5);

    private final HttpClient http;
    private final ObjectMapper json;
    private final URI base;

    public HttpNbrbClient(HttpClient http, ObjectMapper json, URI base) {
        this.http = http;
        this.json = json;
        this.base = base;
    }

    public HttpNbrbClient(ObjectMapper json) {
        this(HttpClient.newBuilder().connectTimeout(TIMEOUT).build(), json, DEFAULT_BASE);
    }

    @Override
    public List<ExchangeRate> dailyRates(LocalDate date) {
        URI uri = URI.create(base + "?periodicity=0&ondate=" + date);
        HttpRequest request = HttpRequest.newBuilder(uri).timeout(TIMEOUT)
                .header("Accept", "application/json").GET().build();
        try {
            HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw new NbrbUnavailableException("API НБ РБ вернуло код " + response.statusCode());
            }
            return parse(response.body());
        } catch (IOException e) {
            throw new NbrbUnavailableException("API НБ РБ недоступно: " + e.getMessage(), e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new NbrbUnavailableException("Запрос к API НБ РБ прерван", e);
        }
    }

    /** Разбор ответа API в список курсов; пустой или некорректный ответ — ошибка. */
    List<ExchangeRate> parse(String body) {
        try {
            NbrbRate[] items = json.readValue(body, NbrbRate[].class);
            if (items.length == 0) {
                throw new NbrbUnavailableException("API НБ РБ вернуло пустой перечень курсов");
            }
            return Arrays.stream(items).map(NbrbRate::toExchangeRate).toList();
        } catch (NbrbUnavailableException e) {
            throw e;
        } catch (IOException | RuntimeException e) {
            // ошибка JSON, отсутствующее поле, неверная дата или курс — ответ некорректен
            throw new NbrbUnavailableException("Некорректный ответ API НБ РБ: " + e.getMessage(), e);
        }
    }

    /** Элемент ответа API; лишние поля ({@code Cur_ID}, {@code Cur_Name}, …) игнорируются. */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record NbrbRate(
            @JsonProperty("Date") String date,
            @JsonProperty("Cur_Abbreviation") String abbreviation,
            @JsonProperty("Cur_Scale") int scale,
            @JsonProperty("Cur_OfficialRate") BigDecimal officialRate) {

        ExchangeRate toExchangeRate() {
            return new ExchangeRate(abbreviation, LocalDateTime.parse(date).toLocalDate(), scale, officialRate);
        }
    }
}
