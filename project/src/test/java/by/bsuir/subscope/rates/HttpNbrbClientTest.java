package by.bsuir.subscope.rates;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

/** Разбор ответов API НБ РБ, сохранённых при POC (без обращения к сети). */
class HttpNbrbClientTest {

    final HttpNbrbClient client = new HttpNbrbClient(new ObjectMapper());

    static String resource(String name) throws IOException {
        try (InputStream in = HttpNbrbClientTest.class.getResourceAsStream("/nbrb/" + name)) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @Test
    void parsesCurrentRates() throws IOException {
        List<ExchangeRate> rates = client.parse(resource("rates-2026-11-19.json"));
        assertEquals(5, rates.size());
        ExchangeRate pln = rates.stream().filter(r -> r.currency().equals("PLN")).findFirst().orElseThrow();
        assertEquals(LocalDate.of(2026, 11, 19), pln.date());
        assertEquals(10, pln.scale());
        assertEquals(0, new BigDecimal("7.4538").compareTo(pln.officialRate()));
    }

    @Test
    void parsesRatesOnPastDate() throws IOException {
        List<ExchangeRate> rates = client.parse(resource("rates-2026-10-01.json"));
        assertEquals(LocalDate.of(2026, 10, 1), rates.get(0).date());
        assertEquals("USD", rates.get(0).currency());
        assertEquals(0, new BigDecimal("3.0207").compareTo(rates.get(0).officialRate()));
    }

    @Test
    void rejectsEmptyOrBrokenResponse() {
        assertThrows(NbrbUnavailableException.class, () -> client.parse("[]"));
        assertThrows(NbrbUnavailableException.class, () -> client.parse("<html>502 Bad Gateway</html>"));
    }
}
