package controller;

import model.LifeData;
import model.LifeModel;
import view.InputDialog;
import view.MainFrame;

import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.time.LocalDate;
import java.util.prefs.Preferences;

public class LifeController {

    private final LifeModel model;
    private final MainFrame view;

    private final Preferences preferences;

    private static final String PREF_DAY = "birth_day";
    private static final String PREF_MONTH = "birth_month";
    private static final String PREF_YEAR = "birth_year";

    public LifeController(
            LifeModel model,
            MainFrame view
    ) {

        this.model = model;
        this.view = view;

        preferences = Preferences.userNodeForPackage(
                LifeController.class
        );

        configure();
    }

    private void configure() {

        view.getInputButton().addActionListener(
                event -> openInputDialog()
        );

        model.addPropertyChangeListener(
                event -> {

                    if ("lifeData".equals(
                            event.getPropertyName()
                    )) {

                        view.displayModel(model);
                        saveData();
                    }
                }
        );

        view.addWindowListener(
                new WindowAdapter() {

                    @Override
                    public void windowClosing(
                            WindowEvent e
                    ) {
                        saveData();
                    }
                }
        );
    }

    public void start() {

        loadData();

        view.displayModel(model);
    }

    private void openInputDialog() {

        LocalDate previousDate =
                model.getBirthDate();

        InputDialog dialog =
                new InputDialog(
                        view,
                        previousDate
                );

        dialog.setVisible(true);

        LocalDate result =
                dialog.getResult();

        if (result == null) {
            return;
        }

        try {

            LifeData data =
                    new LifeData(result);

            model.setLifeData(data);

        } catch (IllegalArgumentException exception) {

            view.showError(
                    exception.getMessage()
            );
        }
    }

    private void saveData() {

        if (!model.hasData()) {
            return;
        }

        LocalDate date =
                model.getBirthDate();

        preferences.putInt(
                PREF_DAY,
                date.getDayOfMonth()
        );

        preferences.putInt(
                PREF_MONTH,
                date.getMonthValue()
        );

        preferences.putInt(
                PREF_YEAR,
                date.getYear()
        );
    }

    private void loadData() {

        int day =
                preferences.getInt(
                        PREF_DAY,
                        -1
                );

        int month =
                preferences.getInt(
                        PREF_MONTH,
                        -1
                );

        int year =
                preferences.getInt(
                        PREF_YEAR,
                        -1
                );

        if (day == -1
                || month == -1
                || year == -1) {

            return;
        }

        try {

            LocalDate date =
                    LocalDate.of(
                            year,
                            month,
                            day
                    );

            if (date.isAfter(LocalDate.now())) {
                return;
            }

            model.setLifeData(
                    new LifeData(date)
            );

        } catch (Exception ignored) {
        }
    }
}
