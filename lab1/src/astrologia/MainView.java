package astrologia;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.SwingConstants;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;

public class MainView extends JFrame implements ZodiacModel.ModelListener {
    private final AstrologController controller;
    private final ZodiacModel model;

    private final JLabel lblDate = new JLabel("Дата рождения: —");
    private final JLabel lblSign = new JLabel("Знак зодиака: —", SwingConstants.CENTER);
    private final JTextArea txtInfo = new JTextArea();

    public MainView(AstrologController controller, ZodiacModel model) {
        this.controller = controller;
        this.model = model;
        this.model.addListener(this);
        initView();
    }

    private void initView() {
        setTitle("Астролог (MVC Active Model)");
        setMinimumSize(new Dimension(780, 620));
        setPreferredSize(new Dimension(860, 700));
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        Font titleFont = new Font(Font.SANS_SERIF, Font.BOLD, 40);
        Font buttonFont = new Font(Font.SANS_SERIF, Font.BOLD, 24);
        Font labelFont = new Font(Font.SANS_SERIF, Font.PLAIN, 22);
        Font signFont = new Font(Font.SANS_SERIF, Font.BOLD, 28);
        Font infoFont = new Font(Font.SANS_SERIF, Font.PLAIN, 20);
        Font borderFont = new Font(Font.SANS_SERIF, Font.BOLD, 18);

        JPanel root = new JPanel(new BorderLayout(16, 16));
        root.setBorder(BorderFactory.createEmptyBorder(20, 24, 20, 24));

        JLabel title = new JLabel("Астролог", SwingConstants.CENTER);
        title.setFont(titleFont);

        JButton btnOpenInput = new JButton("Узнать свой знак Зодиака");
        btnOpenInput.setFont(buttonFont);
        btnOpenInput.setPreferredSize(new Dimension(0, 56));
        btnOpenInput.addActionListener(e -> controller.openInputDialog(this));

        lblDate.setFont(labelFont);
        lblSign.setFont(signFont);

        txtInfo.setEditable(false);
        txtInfo.setLineWrap(true);
        txtInfo.setWrapStyleWord(true);
        txtInfo.setRows(10);
        txtInfo.setFont(infoFont);
        txtInfo.setText("Введите дату рождения, чтобы узнать свой знак зодиака "
                + "и астрологическую информацию.");

        JScrollPane scroll = new JScrollPane(txtInfo);
        var infoBorder = BorderFactory.createTitledBorder("Астрологическая информация");
        infoBorder.setTitleFont(borderFont);
        scroll.setBorder(infoBorder);

        JPanel center = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.weightx = 1;
        gbc.insets = new Insets(10, 0, 10, 0);

        gbc.gridy = 0;
        center.add(btnOpenInput, gbc);
        gbc.gridy = 1;
        center.add(lblDate, gbc);
        gbc.gridy = 2;
        center.add(lblSign, gbc);
        gbc.gridy = 3;
        gbc.weighty = 1;
        gbc.fill = GridBagConstraints.BOTH;
        center.add(scroll, gbc);

        root.add(title, BorderLayout.NORTH);
        root.add(center, BorderLayout.CENTER);
        setContentPane(root);
        pack();
        setLocationRelativeTo(null);
    }

    @Override
    public void onModelChanged() {
        lblDate.setText(String.format("Дата рождения: %02d.%02d.%d",
                model.getDay(), model.getMonth(), model.getYear()));
        lblSign.setText("Знак зодиака: " + model.getSignName());
        txtInfo.setText(model.getSignInfo());
        txtInfo.setCaretPosition(0);
    }
}
