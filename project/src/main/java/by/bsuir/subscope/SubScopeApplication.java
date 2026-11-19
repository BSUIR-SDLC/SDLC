package by.bsuir.subscope;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Точка входа SubScope — модульного монолита на Spring Boot (ADR-0001).
 *
 * <p>Модули верхнего уровня — пакеты {@code by.bsuir.subscope.<модуль>} (SDD, 002-composition).
 * В итерации 1 реализуются каркас, курсы валют ({@code rates}) и расчётное ядро подписок
 * ({@code subscription}); веб-интерфейс, учётные записи и напоминания — в следующих задачах плана v3.
 */
@SpringBootApplication
@EnableScheduling
public class SubScopeApplication {

    public static void main(String[] args) {
        SpringApplication.run(SubScopeApplication.class, args);
    }
}
