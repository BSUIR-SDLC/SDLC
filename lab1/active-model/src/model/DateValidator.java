package model;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public final class DateValidator {

    public static final DateTimeFormatter FORMAT = DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final int MIN_YEAR = 1900;

    private DateValidator() {
    }

    public static class Result {
        public final LocalDate date;
        public final String errorMessage;

        private Result(LocalDate date, String errorMessage) {
            this.date = date;
            this.errorMessage = errorMessage;
        }

        public boolean isValid() {
            return errorMessage == null;
        }

        public static Result ok(LocalDate date) {
            return new Result(date, null);
        }

        public static Result error(String message) {
            return new Result(null, message);
        }
    }

    public static Result validate(String rawInput) {
        if (rawInput == null || rawInput.trim().isEmpty()) {
            return Result.error("Поле «Дата рождения» не заполнено.");
        }

        LocalDate parsed;
        try {
            parsed = LocalDate.parse(rawInput.trim(), FORMAT);
        } catch (DateTimeParseException e) {
            return Result.error("Некорректный формат даты.\nОжидается: дд.ММ.гггг (например, 05.09.1998)");
        }

        if (parsed.isAfter(LocalDate.now())) {
            return Result.error("Дата рождения не может быть в будущем.");
        }

        if (parsed.getYear() < MIN_YEAR) {
            return Result.error("Слишком ранняя дата рождения (раньше " + MIN_YEAR + " года).");
        }

        return Result.ok(parsed);
    }
}
