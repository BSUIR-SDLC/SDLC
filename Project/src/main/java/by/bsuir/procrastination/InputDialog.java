package by.bsuir.procrastination;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class InputDialog extends JDialog {
    private final JTextField txtAge = new JTextField(10);

    public InputDialog(JFrame parent, ProcrastinationController controller) {
        super(parent, "Ввод возраста", true);
        setSize(300, 150);
        setLocationRelativeTo(parent);
        setLayout(new GridLayout(2, 2, 10, 10));
        ((JPanel) getContentPane()).setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        add(new JLabel("Ваш возраст (1-120):"));
        add(txtAge);

        JButton btnSubmit = new JButton("OK");
        add(new JLabel());
        add(btnSubmit);

        ActionListener submitAction = (ActionEvent e) -> controller.processInput(txtAge.getText());
        btnSubmit.addActionListener(submitAction);
        txtAge.addActionListener(submitAction); // Поддержка Enter
    }

    public void setAge(int age) {
        if (age > 0) {
            txtAge.setText(String.valueOf(age));
        } else {
            txtAge.setText("");
        }
    }
}