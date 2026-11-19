package astrologia;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import java.awt.Font;
import java.awt.GridLayout;
import java.awt.event.ActionListener;

public class InputDialog extends JDialog {
    private final JTextField txtDay = new JTextField(5);
    private final JTextField txtMonth = new JTextField(5);
    private final JTextField txtYear = new JTextField(7);

    public InputDialog(JFrame parent, AstrologController controller) {
        super(parent, "Ввод даты рождения", true);
        setSize(420, 280);
        setLocationRelativeTo(parent);
        setLayout(new GridLayout(4, 2, 10, 10));

        ((JPanel) getContentPane()).setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        Font labelFont = new Font("Segoe UI", Font.PLAIN, 18);
        Font fieldFont = new Font("Segoe UI", Font.PLAIN, 20);
        Font buttonFont = new Font("Segoe UI", Font.BOLD, 18);

        JLabel lblDay = new JLabel(" День (1-31):");
        JLabel lblMonth = new JLabel(" Месяц (1-12):");
        JLabel lblYear = new JLabel(" Год (1900-текущий):");
        lblDay.setFont(labelFont);
        lblMonth.setFont(labelFont);
        lblYear.setFont(labelFont);

        txtDay.setFont(fieldFont);
        txtMonth.setFont(fieldFont);
        txtYear.setFont(fieldFont);

        add(lblDay);
        add(txtDay);
        add(lblMonth);
        add(txtMonth);
        add(lblYear);
        add(txtYear);

        JButton btnSubmit = new JButton("OK");
        btnSubmit.setFont(buttonFont);
        add(new JLabel());
        add(btnSubmit);

        ActionListener submitAction = e -> controller.processInput(
                txtDay.getText(), txtMonth.getText(), txtYear.getText()
        );

        btnSubmit.addActionListener(submitAction);
        txtDay.addActionListener(submitAction);
        txtMonth.addActionListener(submitAction);
        txtYear.addActionListener(submitAction);
    }

    public void setValues(int day, int month, int year) {
        if (year != 0) {
            txtDay.setText(String.valueOf(day));
            txtMonth.setText(String.valueOf(month));
            txtYear.setText(String.valueOf(year));
        }
    }
}
