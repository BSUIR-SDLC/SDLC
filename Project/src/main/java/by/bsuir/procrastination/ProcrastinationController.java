package by.bsuir.procrastination;

import javax.swing.*;

public class ProcrastinationController {
    private final ProcrastinationModel model;
    private final MainView view;
    private InputDialog inputDialog;

    public ProcrastinationController(ProcrastinationModel model, MainView view) {
        this.model = model;
        this.view = view;
        this.model.addListener(view); // Подписка View на обновления Модели
    }

    public ProcrastinationModel getModel() {
        return model;
    }

    public void openInputDialog(JFrame parent) {
        if (inputDialog == null || !inputDialog.isDisplayable()) {
            inputDialog = new InputDialog(parent, this);
        }
        // Восстановление последних данных из Модели
        inputDialog.setAge(model.getAge());
        inputDialog.setVisible(true);
    }

    public void processInput(String ageStr) {
        try {
            int age = Integer.parseInt(ageStr.trim());
            model.setAge(age); // Модель сама проверит валидность и обновит View
            if (inputDialog != null) {
                inputDialog.dispose();
            }
        } catch (NumberFormatException e) {
            showError("Ошибка: Пожалуйста, введите целое число!");
        } catch (IllegalArgumentException e) {
            showError("Ошибка: " + e.getMessage());
        }
    }

    private void showError(String msg) {
        JOptionPane.showMessageDialog(null, msg, "Ошибка ввода", JOptionPane.ERROR_MESSAGE);
    }
}