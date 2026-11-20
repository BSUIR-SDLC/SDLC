package model;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.time.Duration;
import java.time.LocalDate;
import java.time.Period;

public class LifeModel {

    private final PropertyChangeSupport propertyChangeSupport =
            new PropertyChangeSupport(this);

    private LifeData lifeData;

    public LifeModel() {
        this.lifeData = null;
    }

    public void addPropertyChangeListener(PropertyChangeListener listener) {
        propertyChangeSupport.addPropertyChangeListener(listener);
    }

    public void removePropertyChangeListener(PropertyChangeListener listener) {
        propertyChangeSupport.removePropertyChangeListener(listener);
    }

    public LifeData getLifeData() {
        return lifeData;
    }

    public void setLifeData(LifeData newData) {

        if (newData == null || !newData.isValid()) {
            throw new IllegalArgumentException(
                    "Некорректная дата рождения."
            );
        }

        LifeData oldData = this.lifeData;
        this.lifeData = newData;

        propertyChangeSupport.firePropertyChange(
                "lifeData",
                oldData,
                newData
        );
    }

    public boolean hasData() {
        return lifeData != null;
    }

    public LocalDate getBirthDate() {
        if (!hasData()) {
            return null;
        }

        return lifeData.getBirthDate();
    }

    public long getDaysLived() {

        if (!hasData()) {
            return 0;
        }

        return Duration.between(
                getBirthDate().atStartOfDay(),
                LocalDate.now().plusDays(1).atStartOfDay()
        ).toDays();
    }

    public long getHoursLived() {

        if (!hasData()) {
            return 0;
        }

        return Duration.between(
                getBirthDate().atStartOfDay(),
                LocalDate.now().atTime(23, 59)
        ).toHours();
    }

    public Period getAge() {

        if (!hasData()) {
            return Period.ZERO;
        }

        return Period.between(
                getBirthDate(),
                LocalDate.now()
        );
    }

    public double getSleepHours() {
        return getDaysLived()
                * LifeStatistics.SLEEP_HOURS_PER_DAY;
    }

    public double getSleepDays() {
        return getSleepHours() / 24.0;
    }

    public long getBlinks() {

        double result =
                getHoursLived()
                        * 60.0
                        * LifeStatistics.BLINKS_PER_MINUTE;

        return Math.round(result);
    }

    public long getHeartBeats() {

        double result =
                getHoursLived()
                        * 60.0
                        * LifeStatistics.HEART_BEATS_PER_MINUTE;

        return Math.round(result);
    }

    public double getBloodLiters() {

        return getDaysLived()
                * LifeStatistics.BLOOD_LITERS_PER_DAY;
    }

    public double getWaterLiters() {

        return getDaysLived()
                * LifeStatistics.WATER_LITERS_PER_DAY;
    }

    public long getLaughs() {

        return Math.round(
                getDaysLived()
                        * LifeStatistics.LAUGHS_PER_DAY
        );
    }
}
