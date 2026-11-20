import controller.LifeController;
import model.LifeModel;
import view.MainFrame;

import javax.swing.*;

public class Main {

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {

            try {
                UIManager.setLookAndFeel(
                        UIManager.getSystemLookAndFeelClassName()
                );
            } catch (Exception ignored) {
            }

            LifeModel model = new LifeModel();
            MainFrame view = new MainFrame();
            LifeController controller = new LifeController(model, view);

            controller.start();

            view.setVisible(true);
        });
    }
}
