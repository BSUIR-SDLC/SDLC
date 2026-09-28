package by.bsuir.procrastination;

import javax.swing.SwingUtilities;

public class App {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            ProcrastinationModel model = new ProcrastinationModel();
            MainView view = new MainView();
            ProcrastinationController controller = new ProcrastinationController(model, view);

            view.setController(controller);
            view.setVisible(true);
        });
    }
}