package view;

import javax.swing.*;
import java.awt.*;
import java.time.DateTimeException;
import java.time.LocalDate;

public class InputDialog extends JDialog {

    private final JTextField dayField;
    private final JTextField monthField;
    private final JTextField yearField;

    private LocalDate result;

    public InputDialog(
            Window owner,
            LocalDate previousDate
    ) {
        super(owner, "Ввод данных", ModalityType.APPLICATION_MODAL);

        dayField = new JTextField(3);
        monthField = new JTextField(3);
        yearField = new JTextField(6);

        createInterface();

        if (previousDate != null) {
            dayField.setText(
                    String.valueOf(previousDate.getDayOfMonth())
            );

            monthField.setText(
                    String.valueOf(previousDate.getMonthValue())
            );

            yearField.setText(
                    String.valueOf(previousDate.getYear())
            );
        }

        setSize(430, 260);
        setLocationRelativeTo(owner);
        setResizable(false);
    }

    private void createInterface() {

        JPanel mainPanel = new JPanel(new BorderLayout(15, 15));
        mainPanel.setBorder(
                BorderFactory.createEmptyBorder(
                        20, 20, 20, 20
                )
        );

        JLabel title = new JLabel(
                "Введите дату рождения",
                SwingConstants.CENTER
        );

        title.setFont(
                new Font(
                        "SansSerif",
                        Font.BOLD,
                        20
                )
        );

        mainPanel.add(title, BorderLayout.NORTH);

        JPanel datePanel = new JPanel(
                new FlowLayout(
                        FlowLayout.CENTER,
                        10,
                        15
                )
        );

        datePanel.add(createDatePart(
                "День",
                dayField
        ));

        datePanel.add(createDatePart(
                "Месяц",
                monthField
        ));

        datePanel.add(createDatePart(
                "Год",
                yearField
        ));

        mainPanel.add(datePanel, BorderLayout.CENTER);

        JPanel buttonPanel = new JPanel(
                new FlowLayout(FlowLayout.CENTER, 10, 5)
        );

        JButton saveButton = new JButton("Сохранить");
        JButton cancelButton = new JButton("Отмена");

        saveButton.setPreferredSize(
                new Dimension(120, 35)
        );

        cancelButton.setPreferredSize(
                new Dimension(120, 35)
        );

        saveButton.addActionListener(e -> save());

        cancelButton.addActionListener(e -> {
            result = null;
            dispose();
        });

        buttonPanel.add(saveButton);
        buttonPanel.add(cancelButton);

        mainPanel.add(
                buttonPanel,
                BorderLayout.SOUTH
        );

        setContentPane(mainPanel);

        getRootPane().setDefaultButton(saveButton);
    }

    private JPanel createDatePart(
            String title,
            JTextField field
    ) {

        JPanel panel = new JPanel(
                new BorderLayout(3, 3)
        );

        JLabel label = new JLabel(
                title,
                SwingConstants.CENTER
        );

        label.setFont(
                new Font(
                        "SansSerif",
                        Font.PLAIN,
                        12
                )
        );

        field.setHorizontalAlignment(
                JTextField.CENTER
        );

        panel.add(
                label,
                BorderLayout.NORTH
        );

        panel.add(
                field,
                BorderLayout.CENTER
        );

        return panel;
    }

    private void save() {

        try {

            String dayText = dayField.getText().trim();
            String monthText = monthField.getText().trim();
            String yearText = yearField.getText().trim();

            if (dayText.isEmpty()
                    || monthText.isEmpty()
                    || yearText.isEmpty()) {

                showError(
                        "Необходимо заполнить все поля."
                );

                return;
            }

            int day = Integer.parseInt(dayText);
            int month = Integer.parseInt(monthText);
            int year = Integer.parseInt(yearText);

            if (year < 1900 || year > LocalDate.now().getYear()) {

                showError(
                        "Год должен находиться в диапазоне от 1900 до "
                                + LocalDate.now().getYear() + "."
                );

                return;
            }

            LocalDate date;

            try {
                date = LocalDate.of(
                        year,
                        month,
                        day
                );
            } catch (DateTimeException exception) {

                showError(
                        "Введена несуществующая дата."
                );

                return;
            }

            if (date.isAfter(LocalDate.now())) {

                showError(
                        "Дата рождения не может быть в будущем."
                );

                return;
            }

            result = date;
            dispose();

        } catch (NumberFormatException exception) {

            showError(
                    "День, месяц и год должны содержать только цифры."
            );
        }
    }

    private void showError(String message) {

        JOptionPane.showMessageDialog(
                this,
                message,
                "Ошибка",
                JOptionPane.ERROR_MESSAGE
        );
    }

    public LocalDate getResult() {
        return result;
    }
}
