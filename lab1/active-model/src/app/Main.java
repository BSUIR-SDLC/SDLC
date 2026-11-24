package app;

import controller.MainController;
import model.SinModel;
import view.MainFrame;
import javax.swing.*;

public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            SinModel model = new SinModel();
            MainFrame view = new MainFrame(model);
            new MainController(model, view);
            view.setVisible(true);
        });
    }
}
