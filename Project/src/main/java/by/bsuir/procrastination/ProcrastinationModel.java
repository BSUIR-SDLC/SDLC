package by.bsuir.procrastination;

import java.util.ArrayList;
import java.util.List;

public class ProcrastinationModel {
    private int age;
    private long procrastinationCount;
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

    public void setAge(int age) throws IllegalArgumentException {
        if (age < 1 || age > 120) {
            throw new IllegalArgumentException("Возраст должен быть от 1 до 120 лет!");
        }
        this.age = age;
        calculateProcrastination();
        notifyListeners(); // Активная модель сама уведомляет View
    }

    private void calculateProcrastination() {
        // По усредненной статистике человек откладывает дела на потом ~3 раза в день
        int timesPerDay = 3;
        int daysInYear = 365;
        this.procrastinationCount = (long) age * daysInYear * timesPerDay;
    }

    public int getAge() { return age; }
    public long getProcrastinationCount() { return procrastinationCount; }
}