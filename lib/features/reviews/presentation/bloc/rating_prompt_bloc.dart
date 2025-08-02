import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/core/services/app_rating_service.dart';
import 'package:rent_ease/features/reviews/data/repositories/review_repository.dart';

// Events
abstract class RatingPromptBlocEvent extends Equatable {
  const RatingPromptBlocEvent();

  @override
  List<Object?> get props => [];
}

class StartListeningForRatingPrompts extends RatingPromptBlocEvent {
  const StartListeningForRatingPrompts();
}

class ShowRatingPrompt extends RatingPromptBlocEvent {
  final RatingPromptEvent promptData;

  const ShowRatingPrompt(this.promptData);

  @override
  List<Object?> get props => [promptData];
}

class SubmitRating extends RatingPromptBlocEvent {
  final String rentalId;
  final String counterPartyId;
  final String itemId;
  final double rating;
  final String? comment;
  final bool isRenterRating;

  const SubmitRating({
    required this.rentalId,
    required this.counterPartyId,
    required this.itemId,
    required this.rating,
    this.comment,
    required this.isRenterRating,
  });

  @override
  List<Object?> get props =>
      [rentalId, counterPartyId, itemId, rating, comment, isRenterRating];
}

class DismissRatingPrompt extends RatingPromptBlocEvent {
  const DismissRatingPrompt();
}

class RatingSubmissionCompleted extends RatingPromptBlocEvent {
  final bool success;
  final String? error;

  const RatingSubmissionCompleted({required this.success, this.error});

  @override
  List<Object?> get props => [success, error];
}

// States
abstract class RatingPromptState extends Equatable {
  const RatingPromptState();

  @override
  List<Object?> get props => [];
}

class RatingPromptInitial extends RatingPromptState {
  const RatingPromptInitial();
}

class RatingPromptListening extends RatingPromptState {
  const RatingPromptListening();
}

class RatingPromptVisible extends RatingPromptState {
  final RatingPromptEvent promptData;

  const RatingPromptVisible(this.promptData);

  @override
  List<Object?> get props => [promptData];
}

class RatingSubmissionInProgress extends RatingPromptState {
  final RatingPromptEvent promptData;

  const RatingSubmissionInProgress(this.promptData);

  @override
  List<Object?> get props => [promptData];
}

class RatingSubmissionSuccess extends RatingPromptState {
  const RatingSubmissionSuccess();
}

class RatingSubmissionError extends RatingPromptState {
  final String error;

  const RatingSubmissionError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class RatingPromptBloc extends Bloc<RatingPromptBlocEvent, RatingPromptState> {
  final ReviewRepository _reviewRepository;
  StreamSubscription<RatingPromptEvent>? _ratingPromptSubscription;

  RatingPromptBloc({
    ReviewRepository? reviewRepository,
  })  : _reviewRepository = reviewRepository ?? ReviewRepository(),
        super(const RatingPromptInitial()) {
    on<StartListeningForRatingPrompts>(_onStartListening);
    on<ShowRatingPrompt>(_onShowRatingPrompt);
    on<SubmitRating>(_onSubmitRating);
    on<DismissRatingPrompt>(_onDismissRatingPrompt);
    on<RatingSubmissionCompleted>(_onRatingSubmissionCompleted);
  }

  Future<void> _onStartListening(
    StartListeningForRatingPrompts event,
    Emitter<RatingPromptState> emit,
  ) async {
    emit(const RatingPromptListening());

    // Cancel existing subscription
    await _ratingPromptSubscription?.cancel();

    // Listen to rating prompt events
    _ratingPromptSubscription = AppRatingService.instance.ratingPrompts.listen(
      (promptEvent) {
        add(ShowRatingPrompt(promptEvent));
      },
    );
  }

  void _onShowRatingPrompt(
    ShowRatingPrompt event,
    Emitter<RatingPromptState> emit,
  ) {
    emit(RatingPromptVisible(event.promptData));
  }

  Future<void> _onSubmitRating(
    SubmitRating event,
    Emitter<RatingPromptState> emit,
  ) async {
    // Find the current prompt data
    if (state is! RatingPromptVisible) return;

    final promptData = (state as RatingPromptVisible).promptData;
    emit(RatingSubmissionInProgress(promptData));

    try {
      // Submit the review
      await _reviewRepository.createReview(
        reviewedId: event.counterPartyId,
        overallRating: event.rating,
        comment: event.comment,
        rentalId: event.rentalId,
        itemId: event.itemId,
      );

      add(const RatingSubmissionCompleted(success: true));
    } catch (e) {
      add(RatingSubmissionCompleted(success: false, error: e.toString()));
    }
  }

  void _onDismissRatingPrompt(
    DismissRatingPrompt event,
    Emitter<RatingPromptState> emit,
  ) {
    emit(const RatingPromptListening());
  }

  void _onRatingSubmissionCompleted(
    RatingSubmissionCompleted event,
    Emitter<RatingPromptState> emit,
  ) {
    if (event.success) {
      emit(const RatingSubmissionSuccess());
      // Auto-dismiss after success
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          add(const DismissRatingPrompt());
        }
      });
    } else {
      emit(RatingSubmissionError(event.error ?? 'Failed to submit rating'));
    }
  }

  @override
  Future<void> close() {
    _ratingPromptSubscription?.cancel();
    return super.close();
  }
}
