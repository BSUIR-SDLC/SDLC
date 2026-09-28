package by.bsuir.procrastination;

import javax.swing.*;
import java.awt.*;

public class MainView extends JFrame implements ProcrastinationModel.ModelListener {
    private ProcrastinationController controller;
    private final JLabel lblAge = new JLabel("Возраст: не задан");
    private final JLabel lblResult = new JLabel("Количество \"потом\": 0");

    public MainView() {
        setTitle("Сколько раз ты сказал \"потом\" (MVC Active Model)");
        setSize(450, 220);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(15, 15));

        JPanel panelInfo = new JPanel(new GridLayout(2, 1, 10, 10));
        panelInfo.setBorder(BorderFactory.createEmptyBorder(30, 30, 20, 30));
        lblAge.setFont(new Font("Segoe UI", Font.PLAIN, 16));
        lblResult.setFont(new Font("Segoe UI", Font.BOLD, 18));
        lblResult.setForeground(new Color(204, 0, 0));
        panelInfo.add(lblAge);
        panelInfo.add(lblResult);
        add(panelInfo, BorderLayout.CENTER);

        JButton btnOpenInput = new JButton("Ввести данные");
        btnOpenInput.setPreferredSize(new Dimension(150, 40));
        btnOpenInput.setFont(new Font("Segoe UI", Font.BOLD, 14));

        JPanel panelButton = new JPanel();
        panelButton.setBorder(BorderFactory.createEmptyBorder(0, 0, 30, 0));
        panelButton.add(btnOpenInput);
        add(panelButton, BorderLayout.SOUTH);

        btnOpenInput.addActionListener(e -> {
            if (controller != null) controller.openInputDialog(this);
        });
    }

    public void setController(ProcrastinationController controller) {
        this.controller = controller;
    }

    @Override
    public void onModelChanged() {
        // Метод вызывается моделью автоматически
        ProcrastinationModel model = controller.getModel();
        lblAge.setText(String.format("Ваш возраст: %d лет", model.getAge()));
        lblResult.setText(String.format("Вы сказали \"потом\": %,d раз", model.getProcrastinationCount()));
    }
}