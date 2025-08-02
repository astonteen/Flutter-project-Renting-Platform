import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/reviews/data/models/review_model.dart';
import 'package:rent_ease/features/reviews/data/repositories/review_repository.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadReviews extends ReviewEvent {
  final String? reviewedId;
  final String? itemId;
  final ReviewType? reviewType;

  const LoadReviews({
    this.reviewedId,
    this.itemId,
    this.reviewType,
  });

  @override
  List<Object?> get props => [reviewedId, itemId, reviewType];
}

class CreateReview extends ReviewEvent {
  final String reviewedId;
  final double overallRating;
  final double? conditionAccuracyRating;
  final double? communicationRating;
  final double? deliveryExperienceRating;
  final String? comment;
  final List<String>? photoUrls;
  final String? rentalId;
  final String? itemId;
  final ReviewType reviewType;

  const CreateReview({
    required this.reviewedId,
    required this.overallRating,
    this.conditionAccuracyRating,
    this.communicationRating,
    this.deliveryExperienceRating,
    this.comment,
    this.photoUrls,
    this.rentalId,
    this.itemId,
    this.reviewType = ReviewType.item,
  });

  @override
  List<Object?> get props => [
        reviewedId,
        overallRating,
        conditionAccuracyRating,
        communicationRating,
        deliveryExperienceRating,
        comment,
        photoUrls,
        rentalId,
        itemId,
        reviewType,
      ];
}

class LoadReviewStatistics extends ReviewEvent {
  final String? reviewedId;
  final String? itemId;

  const LoadReviewStatistics({
    this.reviewedId,
    this.itemId,
  });

  @override
  List<Object?> get props => [reviewedId, itemId];
}

class LoadTrustScore extends ReviewEvent {
  final String userId;

  const LoadTrustScore(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddOwnerResponse extends ReviewEvent {
  final String reviewId;
  final String response;

  const AddOwnerResponse({
    required this.reviewId,
    required this.response,
  });

  @override
  List<Object?> get props => [reviewId, response];
}

class MarkReviewHelpful extends ReviewEvent {
  final String reviewId;

  const MarkReviewHelpful(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class ReportReview extends ReviewEvent {
  final String reviewId;
  final String reason;

  const ReportReview({
    required this.reviewId,
    required this.reason,
  });

  @override
  List<Object?> get props => [reviewId, reason];
}

class CheckReviewEligibility extends ReviewEvent {
  final String itemId;
  final String ownerId;

  const CheckReviewEligibility({
    required this.itemId,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [itemId, ownerId];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewActionLoading extends ReviewState {
  final String action;

  const ReviewActionLoading(this.action);

  @override
  List<Object?> get props => [action];
}

class ReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class ReviewCreated extends ReviewState {
  final ReviewModel review;

  const ReviewCreated(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewStatisticsLoaded extends ReviewState {
  final Map<String, dynamic> statistics;

  const ReviewStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class TrustScoreLoaded extends ReviewState {
  final TrustScore trustScore;

  const TrustScoreLoaded(this.trustScore);

  @override
  List<Object?> get props => [trustScore];
}

class OwnerResponseAdded extends ReviewState {
  final ReviewModel updatedReview;

  const OwnerResponseAdded(this.updatedReview);

  @override
  List<Object?> get props => [updatedReview];
}

class ReviewMarkedHelpful extends ReviewState {
  final String reviewId;

  const ReviewMarkedHelpful(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class ReviewReported extends ReviewState {
  final String reviewId;

  const ReviewReported(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class ReviewEligibilityChecked extends ReviewState {
  final bool canReview;
  final String itemId;

  const ReviewEligibilityChecked({
    required this.canReview,
    required this.itemId,
  });

  @override
  List<Object?> get props => [canReview, itemId];
}

class ReviewSuccess extends ReviewState {
  final String message;

  const ReviewSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReviewError extends ReviewState {
  final String message;
  final String? errorType;

  const ReviewError(this.message, {this.errorType});

  @override
  List<Object?> get props => [message, errorType];
}

// BLoC
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _repository;

  ReviewBloc({ReviewRepository? repository})
      : _repository = repository ?? ReviewRepository(),
        super(ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<CreateReview>(_onCreateReview);
    on<LoadReviewStatistics>(_onLoadReviewStatistics);
    on<LoadTrustScore>(_onLoadTrustScore);
    on<AddOwnerResponse>(_onAddOwnerResponse);
    on<MarkReviewHelpful>(_onMarkReviewHelpful);
    on<ReportReview>(_onReportReview);
    on<CheckReviewEligibility>(_onCheckReviewEligibility);
  }

  Future<void> _onLoadReviews(
    LoadReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    try {
      final reviews = await _repository.getReviews(
        reviewedId: event.reviewedId,
        itemId: event.itemId,
        reviewType: event.reviewType,
      );

      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewError('Failed to load reviews: ${e.toString()}'));
    }
  }

  Future<void> _onCreateReview(
    CreateReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('Creating review...'));

    try {
      final review = await _repository.createReview(
        reviewedId: event.reviewedId,
        overallRating: event.overallRating,
        conditionAccuracyRating: event.conditionAccuracyRating,
        communicationRating: event.communicationRating,
        deliveryExperienceRating: event.deliveryExperienceRating,
        comment: event.comment,
        photoUrls: event.photoUrls,
        rentalId: event.rentalId,
        itemId: event.itemId,
        reviewType: event.reviewType,
      );

      emit(ReviewCreated(review));
      emit(const ReviewSuccess('Review created successfully!'));
    } catch (e) {
      emit(ReviewError('Failed to create review: ${e.toString()}'));
    }
  }

  Future<void> _onLoadReviewStatistics(
    LoadReviewStatistics event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    try {
      final statistics = await _repository.getReviewStatistics(
        reviewedId: event.reviewedId,
        itemId: event.itemId,
      );

      emit(ReviewStatisticsLoaded(statistics));
    } catch (e) {
      emit(ReviewError('Failed to load review statistics: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTrustScore(
    LoadTrustScore event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    try {
      final trustScore = await _repository.calculateTrustScore(event.userId);
      emit(TrustScoreLoaded(trustScore));
    } catch (e) {
      emit(ReviewError('Failed to load trust score: ${e.toString()}'));
    }
  }

  Future<void> _onAddOwnerResponse(
    AddOwnerResponse event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('Adding response...'));

    try {
      final updatedReview = await _repository.addOwnerResponse(
        event.reviewId,
        event.response,
      );

      emit(OwnerResponseAdded(updatedReview));
      emit(const ReviewSuccess('Response added successfully!'));
    } catch (e) {
      emit(ReviewError('Failed to add response: ${e.toString()}'));
    }
  }

  Future<void> _onMarkReviewHelpful(
    MarkReviewHelpful event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('Marking as helpful...'));

    try {
      await _repository.markReviewHelpful(event.reviewId);
      emit(ReviewMarkedHelpful(event.reviewId));
      emit(const ReviewSuccess('Marked as helpful!'));
    } catch (e) {
      emit(ReviewError('Failed to mark review as helpful: ${e.toString()}'));
    }
  }

  Future<void> _onReportReview(
    ReportReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('Reporting review...'));

    try {
      await _repository.reportReview(event.reviewId, event.reason);
      emit(ReviewReported(event.reviewId));
      emit(const ReviewSuccess('Review reported successfully!'));
    } catch (e) {
      emit(ReviewError('Failed to report review: ${e.toString()}'));
    }
  }

  Future<void> _onCheckReviewEligibility(
    CheckReviewEligibility event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    try {
      final canReview = await _repository.canUserReview(
        event.itemId,
        event.ownerId,
      );

      emit(ReviewEligibilityChecked(
        canReview: canReview,
        itemId: event.itemId,
      ));
    } catch (e) {
      emit(ReviewError('Failed to check review eligibility: ${e.toString()}'));
    }
  }
}
