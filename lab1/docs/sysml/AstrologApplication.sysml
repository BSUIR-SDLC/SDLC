package AstrologApplication {
    part def ZodiacModel;
    part def MainView;
    part def InputDialog;
    part def AstrologController;

    part application {
        part model : ZodiacModel;
        part view : MainView;
        part dialog : InputDialog;
        part controller : AstrologController;
        connect view to controller;
        connect controller to model;
        connect model to view;
    }
}
