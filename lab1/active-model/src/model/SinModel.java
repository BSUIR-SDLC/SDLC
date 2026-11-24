package model;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

public class SinModel {

    public static final String PROP_SINS_COUNT = "sinsCount";
    public static final String PROP_BIRTH_DATE = "birthDate";

    private final PropertyChangeSupport support = new PropertyChangeSupport(this);

    private LocalDate lastBirthDate;
    private int sinsCount;

    public void addPropertyChangeListener(PropertyChangeListener listener) {
        support.addPropertyChangeListener(listener);
    }

    public void removePropertyChangeListener(PropertyChangeListener listener) {
        support.removePropertyChangeListener(listener);
    }

    public void setBirthDate(LocalDate birthDate) {
        LocalDate oldDate = this.lastBirthDate;
        this.lastBirthDate = birthDate;

        int oldSins = this.sinsCount;
        this.sinsCount = calculateSins(birthDate);
        support.firePropertyChange(PROP_BIRTH_DATE, oldDate, this.lastBirthDate);
        support.firePropertyChange(PROP_SINS_COUNT, oldSins, this.sinsCount);
    }

    public LocalDate getLastBirthDate() {
        return lastBirthDate;
    }

    public int getSinsCount() {
        return sinsCount;
    }

    public static int calculateSins(LocalDate birthDate) {
        long daysLived = ChronoUnit.DAYS.between(birthDate, LocalDate.now());
        int base = (int) (daysLived % 666);
        int weekdayBonus = birthDate.getDayOfWeek().getValue() * 3;
        return base + weekdayBonus;
    }
}
