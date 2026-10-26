package astrologia;

import javax.swing.JFrame;
import javax.swing.JOptionPane;

public class AstrologController {
    private final ZodiacModel model;
    private InputDialog inputDialog;

    public AstrologController(ZodiacModel model) {
        this.model = model;
    }

    public void openInputDialog(JFrame parent) {
        if (inputDialog == null || !inputDialog.isDisplayable()) {
            inputDialog = new InputDialog(parent, this);
        }
        inputDialog.setValues(model.getDay(), model.getMonth(), model.getYear());
        inputDialog.setVisible(true);
    }

    public void processInput(String dayStr, String monthStr, String yearStr) {
        try {
            int d = Integer.parseInt(dayStr.trim());
            int m = Integer.parseInt(monthStr.trim());
            int y = Integer.parseInt(yearStr.trim());

            model.setData(d, m, y);

            if (inputDialog != null) {
                inputDialog.dispose();
                inputDialog = null;
            }
        } catch (NumberFormatException e) {
            showError("Ошибка: Пожалуйста, введите целые числа!");
        } catch (IllegalArgumentException e) {
            showError("Ошибка: " + e.getMessage());
        }
    }

    private void showError(String msg) {
        JOptionPane.showMessageDialog(
                inputDialog,
                msg,
                "Ошибка ввода",
                JOptionPane.ERROR_MESSAGE);
    }
}
