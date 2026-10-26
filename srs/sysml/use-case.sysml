package TourReviewUseCase {
    part def Tourist;
    part def Landlord;
    part def Moderator;
    part def Administrator;

    use case LeaveReview { actor tourist : Tourist; }
    use case RatePlace { actor tourist : Tourist; }
    use case AttachPhoto { actor tourist : Tourist; }
    use case SubmitComplaint { actor tourist : Tourist; }

    use case ReplyToReview { actor landlord : Landlord; }

    use case ReviewComplaints { actor moderator : Moderator; }
    use case HideContent { actor moderator : Moderator; }

    use case ManageUsers { actor admin : Administrator; }
}