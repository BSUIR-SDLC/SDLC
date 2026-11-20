package view;

import model.LifeModel;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.time.Period;

public class MainFrame extends JFrame {

    private final JButton inputButton;

    private final JLabel birthDateLabel;
    private final JLabel ageLabel;

    private final JLabel sleepLabel;
    private final JLabel blinksLabel;
    private final JLabel heartLabel;
    private final JLabel bloodLabel;
    private final JLabel waterLabel;
    private final JLabel laughsLabel;

    public MainFrame() {

        setTitle("Калькулятор Жизни");

        setDefaultCloseOperation(
                JFrame.EXIT_ON_CLOSE
        );

        setSize(650, 600);

        setMinimumSize(
                new Dimension(600, 550)
        );

        setLocationRelativeTo(null);

        inputButton = new JButton(
                "Ввести данные"
        );

        inputButton.setFont(
                new Font(
                        "SansSerif",
                        Font.BOLD,
                        16
                )
        );

        inputButton.setPreferredSize(
                new Dimension(220, 45)
        );

        birthDateLabel = new JLabel(
                "Дата рождения: не введена"
        );

        ageLabel = new JLabel(
                "Возраст: —"
        );

        sleepLabel = createValueLabel();
        blinksLabel = createValueLabel();
        heartLabel = createValueLabel();
        bloodLabel = createValueLabel();
        waterLabel = createValueLabel();
        laughsLabel = createValueLabel();

        createInterface();
    }

    private void createInterface() {

        JPanel root = new JPanel(
                new BorderLayout(15, 15)
        );

        root.setBorder(
                new EmptyBorder(
                        20, 25, 20, 25
                )
        );

        JLabel title = new JLabel(
                "КАЛЬКУЛЯТОР ЖИЗНИ",
                SwingConstants.CENTER
        );

        title.setFont(
                new Font(
                        "SansSerif",
                        Font.BOLD,
                        26
                )
        );

        root.add(
                title,
                BorderLayout.NORTH
        );

        JPanel center = new JPanel(
                new BorderLayout(10, 15)
        );

        JPanel personPanel = new JPanel(
                new GridLayout(2, 1, 5, 5)
        );

        personPanel.setBorder(
                BorderFactory.createTitledBorder(
                        "Данные"
                )
        );

        birthDateLabel.setFont(
                new Font(
                        "SansSerif",
                        Font.PLAIN,
                        15
                )
        );

        ageLabel.setFont(
                new Font(
                        "SansSerif",
                        Font.PLAIN,
                        15
                )
        );

        personPanel.add(birthDateLabel);
        personPanel.add(ageLabel);

        center.add(
                personPanel,
                BorderLayout.NORTH
        );

        JPanel resultsPanel = new JPanel(
                new GridLayout(6, 1, 5, 5)
        );

        resultsPanel.setBorder(
                BorderFactory.createTitledBorder(
                        "Результаты"
                )
        );

        resultsPanel.add(
                createResultRow(
                        "😴 Сон:",
                        sleepLabel
                )
        );

        resultsPanel.add(
                createResultRow(
                        "👁 Моргания:",
                        blinksLabel
                )
        );

        resultsPanel.add(
                createResultRow(
                        "❤ Сердцебиения:",
                        heartLabel
                )
        );

        resultsPanel.add(
                createResultRow(
                        "🩸 Перекачано крови:",
                        bloodLabel
                )
        );

        resultsPanel.add(
                createResultRow(
                        "💧 Выпито воды:",
                        waterLabel
                )
        );

        resultsPanel.add(
                createResultRow(
                        "😄 Смех:",
                        laughsLabel
                )
        );

        center.add(
                resultsPanel,
                BorderLayout.CENTER
        );

        root.add(
                center,
                BorderLayout.CENTER
        );

        JPanel bottom = new JPanel(
                new FlowLayout(
                        FlowLayout.CENTER
                )
        );

        bottom.add(inputButton);

        root.add(
                bottom,
                BorderLayout.SOUTH
        );

        setContentPane(root);
    }

    private JLabel createValueLabel() {

        JLabel label = new JLabel("—");

        label.setFont(
                new Font(
                        "SansSerif",
                        Font.BOLD,
                        14
                )
        );

        return label;
    }

    private JPanel createResultRow(
            String name,
            JLabel value
    ) {

        JPanel panel = new JPanel(
                new BorderLayout(10, 0)
        );

        JLabel nameLabel = new JLabel(name);

        nameLabel.setFont(
                new Font(
                        "SansSerif",
                        Font.PLAIN,
                        14
                )
        );

        panel.add(
                nameLabel,
                BorderLayout.WEST
        );

        panel.add(
                value,
                BorderLayout.CENTER
        );

        return panel;
    }

    public JButton getInputButton() {
        return inputButton;
    }

    public void displayModel(LifeModel model) {

        if (!model.hasData()) {

            birthDateLabel.setText(
                    "Дата рождения: не введена"
            );

            ageLabel.setText(
                    "Возраст: —"
            );

            sleepLabel.setText("—");
            blinksLabel.setText("—");
            heartLabel.setText("—");
            bloodLabel.setText("—");
            waterLabel.setText("—");
            laughsLabel.setText("—");

            return;
        }

        birthDateLabel.setText(
                "Дата рождения: "
                        + model.getBirthDate()
        );

        Period age = model.getAge();

        ageLabel.setText(
                String.format(
                        "Возраст: %d лет, %d месяцев, %d дней",
                        age.getYears(),
                        age.getMonths(),
                        age.getDays()
                )
        );

        sleepLabel.setText(
                String.format(
                        "%.1f часов (%.1f суток)",
                        model.getSleepHours(),
                        model.getSleepDays()
                )
        );

        blinksLabel.setText(
                String.format(
                        "%,d раз",
                        model.getBlinks()
                )
        );

        heartLabel.setText(
                String.format(
                        "%,d ударов",
                        model.getHeartBeats()
                )
        );

        bloodLabel.setText(
                String.format(
                        "%,.0f литров",
                        model.getBloodLiters()
                )
        );

        waterLabel.setText(
                String.format(
                        "%,.1f литров",
                        model.getWaterLiters()
                )
        );

        laughsLabel.setText(
                String.format(
                        "%,d раз",
                        model.getLaughs()
                )
        );
    }

    public void showError(String message) {

        JOptionPane.showMessageDialog(
                this,
                message,
                "Ошибка",
                JOptionPane.ERROR_MESSAGE
        );
    }
}
