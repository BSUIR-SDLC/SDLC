package TourReviewArchitecture {

    part def JavaFxUi;
    part def ReviewService;
    part def ModerationService;
    part def AuthService;
    part def LocalDatabase;
    part def PhotoStorage;

    part ui : JavaFxUi;
    part reviews : ReviewService;
    part moderation : ModerationService;
    part auth : AuthService;
    part database : LocalDatabase;
    part photos : PhotoStorage;

    connect ui to reviews;
    connect reviews to database;
    connect moderation to database;
    connect auth to database;
    connect reviews to photos;
}