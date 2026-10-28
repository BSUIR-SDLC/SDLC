package RepuTrust {
    part def Buyer;
    part def Seller;
    part def Moderator;
    part def PlatformModule;
    part def ReputationModule;

    requirement def BusinessGoal {
        attribute id : String;
        doc /* Бизнес-цель проекта */
    }

    requirement trust : BusinessGoal {
        attribute :>> id = "BG-1";
        doc /* Не менее 40 процентов покупателей оставляют отзыв после завершённой сделки */
    }
    requirement disputeSpeed : BusinessGoal {
        attribute :>> id = "BG-2";
        doc /* Не менее 90 процентов споров решаются за 5 рабочих дней */
    }
    requirement apiSpeed : BusinessGoal {
        attribute :>> id = "BG-3";
        doc /* API возвращает рейтинг за 300 мс или быстрее при 100 запросах в секунду */
    }
    requirement transparency : BusinessGoal {
        attribute :>> id = "BG-4";
        doc /* Каждое решение по спору сопровождается обоснованием */
    }

    use case def LeaveReview {
        subject module : ReputationModule;
        actor buyer : Buyer;
    }
    use case def ViewRatingAndHistory {
        subject module : ReputationModule;
        actor buyer : Buyer;
        actor seller : Seller;
    }
    use case def OpenDispute {
        subject module : ReputationModule;
        actor buyer : Buyer;
        actor seller : Seller;
    }
    use case def ResolveDispute {
        subject module : ReputationModule;
        actor moderator : Moderator;
    }
    use case def GetRatingByUserId {
        subject module : ReputationModule;
        actor platform : PlatformModule;
    }
}
