package controller;

import model.DateValidator;
import model.SinModel;
import view.InputDialog;
import view.MainFrame;

import java.time.format.DateTimeFormatter;

public class MainController {

    private final SinModel model;
    private final MainFrame view;

    public MainController(SinModel model, MainFrame view) {
        this.model = model;
        this.view = view;

        this.view.getCalculateButton().addActionListener(e -> onCalculateClicked());
    }

    private void onCalculateClicked() {
        String lastValueText = null;
        if (model.getLastBirthDate() != null) {
            lastValueText = model.getLastBirthDate().format(DateValidator.FORMAT);
        }

        InputDialog dialog = new InputDialog(view, lastValueText);
        dialog.setVisible(true);

        if (!dialog.isConfirmed()) {
            return;
        }

        String rawInput = dialog.getEnteredBirthDate();
        DateValidator.Result result = DateValidator.validate(rawInput);

        if (!result.isValid()) {
            view.showError(result.errorMessage);
            return;
        }
        model.setBirthDate(result.date);
    }
}
