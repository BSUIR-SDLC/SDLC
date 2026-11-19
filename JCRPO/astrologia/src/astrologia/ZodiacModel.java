package astrologia;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ZodiacModel {
    private int day;
    private int month;
    private int year;
    private String signName = "";
    private String signInfo = "";
    private boolean hasData;

    private final List<ModelListener> listeners = new ArrayList<>();

    public interface ModelListener {
        void onModelChanged();
    }

    public void addListener(ModelListener listener) {
        listeners.add(listener);
    }

    private void notifyListeners() {
        for (ModelListener listener : listeners) {
            listener.onModelChanged();
        }
    }

    public void setData(int day, int month, int year) {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("Месяц должен быть числом от 1 до 12");
        }
        if (year < 1900 || year > LocalDate.now().getYear()) {
            throw new IllegalArgumentException(
                    "Год рождения должен быть от 1900 до " + LocalDate.now().getYear());
        }
        if (day < 1 || day > 31) {
            throw new IllegalArgumentException("День должен быть числом от 1 до 31");
        }
        try {
            LocalDate.of(year, month, day);
        } catch (Exception e) {
            throw new IllegalArgumentException("Указанной даты не существует в григорианском календаре!");
        }

        this.day = day;
        this.month = month;
        this.year = year;

        ZodiacSign sign = ZodiacSign.fromDayAndMonth(day, month);
        this.signName = sign.getDisplayName();
        this.signInfo = sign.getDescription();
        this.hasData = true;

        notifyListeners();
    }

    public int getDay() {
        return day;
    }

    public int getMonth() {
        return month;
    }

    public int getYear() {
        return year;
    }

    public String getSignName() {
        return signName;
    }

    public String getSignInfo() {
        return signInfo;
    }

    public boolean hasData() {
        return hasData;
    }
}
