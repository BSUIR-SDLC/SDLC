package by.bsuir.subscope.config;

import java.time.Clock;
import java.time.ZoneId;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Единый источник текущей даты (SDD, 003-logical; SUP-RULE-03).
 *
 * <p>Все расчёты берут «сегодня» из бина {@link Clock} в часовом поясе Europe/Minsk,
 * поэтому тесты задают любую текущую дату через {@link Clock#fixed}.
 */
@Configuration
public class ClockConfig {

    /** Часовой пояс системы: сроки списаний, границы месяцев, время фоновых задач. */
    public static final ZoneId ZONE = ZoneId.of("Europe/Minsk");

    @Bean
    public Clock clock() {
        return Clock.system(ZONE);
    }
}
