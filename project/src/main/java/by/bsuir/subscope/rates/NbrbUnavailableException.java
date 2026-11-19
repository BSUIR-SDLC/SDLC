package by.bsuir.subscope.rates;

/** API НБ РБ недоступно или вернуло некорректный ответ (UC-20, поток Е1). */
public class NbrbUnavailableException extends RuntimeException {

    public NbrbUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }

    public NbrbUnavailableException(String message) {
        super(message);
    }
}
