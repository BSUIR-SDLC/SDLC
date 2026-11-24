package view;

import model.SinModel;

import javax.swing.*;
import java.awt.*;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.time.format.DateTimeFormatter;

public class MainFrame extends JFrame implements PropertyChangeListener {

    private final JButton calculateButton = new JButton("Рассчитать");
    private final JLabel resultLabel = new JLabel("Количество грехов: —", SwingConstants.CENTER);
    private final JLabel lastDateLabel = new JLabel(" ", SwingConstants.CENTER);

    public MainFrame(SinModel model) {
        super("Утилита расчёта количества совершённых грехов");

        model.addPropertyChangeListener(this);

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLayout(new BorderLayout(15, 15));
        ((JComponent) getContentPane()).setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        resultLabel.setFont(resultLabel.getFont().deriveFont(Font.BOLD, 18f));

        JPanel centerPanel = new JPanel(new GridLayout(2, 1, 5, 5));
        centerPanel.add(resultLabel);
        centerPanel.add(lastDateLabel);

        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        bottomPanel.add(calculateButton);

        add(centerPanel, BorderLayout.CENTER);
        add(bottomPanel, BorderLayout.SOUTH);

        setSize(420, 220);
        setLocationRelativeTo(null);
    }

    public JButton getCalculateButton() {
        return calculateButton;
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        switch (evt.getPropertyName()) {
            case SinModel.PROP_SINS_COUNT -> {
                int sins = (int) evt.getNewValue();
                resultLabel.setText("Количество грехов: " + sins);
            }
            case SinModel.PROP_BIRTH_DATE -> {
                Object newVal = evt.getNewValue();
                if (newVal != null) {
                    var date = (java.time.LocalDate) newVal;
                    lastDateLabel.setText("Дата рождения: " + date.format(DateTimeFormatter.ofPattern("dd.MM.yyyy")));
                }
            }
        }
    }

    public void showError(String message) {
        JOptionPane.showMessageDialog(this, message, "Некорректные данные", JOptionPane.ERROR_MESSAGE);
    }
}
