package astrologia;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception ignored) {
            }

            ZodiacModel model = new ZodiacModel();
            AstrologController controller = new AstrologController(model);
            MainView view = new MainView(controller, model);
            view.setVisible(true);
        });
    }
}
