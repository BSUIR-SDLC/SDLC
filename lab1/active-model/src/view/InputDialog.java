package view;

import javax.swing.*;
import java.awt.*;

public class InputDialog extends JDialog {

    private final JTextField birthDateField = new JTextField(15);
    private boolean confirmed = false;

    public InputDialog(Frame owner, String lastValue) {
        super(owner, "Введите данные", true); // модальное окно

        setLayout(new BorderLayout(10, 10));

        JPanel formPanel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.anchor = GridBagConstraints.WEST;

        gbc.gridx = 0;
        gbc.gridy = 0;
        formPanel.add(new JLabel("Дата рождения (дд.ММ.гггг):"), gbc);

        gbc.gridx = 1;
        if (lastValue != null) {
            birthDateField.setText(lastValue); // восстановление последних введённых данных
        }
        formPanel.add(birthDateField, gbc);

        JButton okButton = new JButton("OK");
        JButton cancelButton = new JButton("Отмена");

        okButton.addActionListener(e -> {
            confirmed = true;
            setVisible(false);
        });
        cancelButton.addActionListener(e -> {
            confirmed = false;
            setVisible(false);
        });

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.add(okButton);
        buttonPanel.add(cancelButton);

        add(formPanel, BorderLayout.CENTER);
        add(buttonPanel, BorderLayout.SOUTH);

        getRootPane().setDefaultButton(okButton);
        pack();
        setResizable(false);
        setLocationRelativeTo(owner);
    }

    public boolean isConfirmed() {
        return confirmed;
    }

    public String getEnteredBirthDate() {
        return birthDateField.getText();
    }
}
