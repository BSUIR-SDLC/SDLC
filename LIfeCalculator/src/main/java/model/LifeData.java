package model;

import java.time.LocalDate;

public class LifeData {

    private LocalDate birthDate;

    public LifeData(LocalDate birthDate) {
        this.birthDate = birthDate;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(LocalDate birthDate) {
        this.birthDate = birthDate;
    }

    public boolean isValid() {
        return birthDate != null
                && !birthDate.isAfter(LocalDate.now());
    }
}
