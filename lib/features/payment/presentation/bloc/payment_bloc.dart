import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/rental/data/repositories/booking_repository.dart';
import 'package:rent_ease/core/services/supabase_service.dart';

// Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPayment extends PaymentEvent {
  final String itemId;
  final double amount;
  final String paymentMethod;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final bool needsDelivery;
  final String? deliveryAddress;
  final String? deliveryInstructions;

  const ProcessPayment({
    required this.itemId,
    required this.amount,
    required this.paymentMethod,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.needsDelivery = false,
    this.deliveryAddress,
    this.deliveryInstructions,
  });

  @override
  List<Object?> get props => [
        itemId,
        amount,
        paymentMethod,
        startDate,
        endDate,
        notes,
        needsDelivery,
        deliveryAddress,
        deliveryInstructions,
      ];
}

class ResetPayment extends PaymentEvent {}

// States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentProcessing extends PaymentState {
  final String paymentMethod;
  final String stage; // 'validating', 'processing', 'creating_booking'

  const PaymentProcessing({
    required this.paymentMethod,
    required this.stage,
  });

  @override
  List<Object?> get props => [paymentMethod, stage];
}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final String bookingId;
  final double amount;
  final String paymentMethod;

  const PaymentSuccess({
    required this.transactionId,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [transactionId, bookingId, amount, paymentMethod];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final BookingRepository _bookingRepository;

  PaymentBloc({BookingRepository? bookingRepository})
      : _bookingRepository = bookingRepository ?? BookingRepository(),
        super(PaymentInitial()) {
    on<ProcessPayment>(_onProcessPayment);
    on<ResetPayment>(_onResetPayment);
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    try {
      // Stage 1: Validation
      emit(PaymentProcessing(
          paymentMethod: event.paymentMethod, stage: 'validating'));

      // Validate user authentication first
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        emit(const PaymentError('Please log in to complete your booking'));
        return;
      }

      // Validate payment amount
      if (event.amount <= 0) {
        emit(const PaymentError('Invalid payment amount'));
        return;
      }

      // Get item details and validate availability
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('security_deposit, owner_id, available, name, location')
          .eq('id', event.itemId)
          .single();

      // Check if item is available
      if (itemResponse['available'] == false) {
        emit(const PaymentError('Item is no longer available'));
        return;
      }

      // Check if user is trying to rent their own item
      if (itemResponse['owner_id'] == userId) {
        emit(const PaymentError('You cannot rent your own item'));
        return;
      }

      final securityDeposit =
          (itemResponse['security_deposit'] as num?)?.toDouble() ?? 0.0;

      // Stage 2: Processing Payment
      emit(PaymentProcessing(
          paymentMethod: event.paymentMethod, stage: 'processing'));

      // Simulate realistic payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Enhanced payment simulation with better success rates per method
      final random = Random();
      double successRate;

      switch (event.paymentMethod) {
        case 'apple_pay':
          successRate = 0.98; // 98% success rate
          break;
        case 'card':
          successRate = 0.95; // 95% success rate
          break;
        case 'paypal':
          successRate = 0.96; // 96% success rate
          break;
        default:
          successRate = 0.90; // 90% success rate for others
      }

      final isSuccess = random.nextDouble() < successRate;

      if (isSuccess) {
        // Stage 3: Creating Booking
        emit(PaymentProcessing(
            paymentMethod: event.paymentMethod, stage: 'creating_booking'));

        // Generate realistic transaction ID
        final transactionId =
            'txn_${event.paymentMethod}_${DateTime.now().millisecondsSinceEpoch}';

        // Create booking in database
        final booking = await _bookingRepository.createBooking(
          itemId: event.itemId,
          renterId: userId,
          startDate: event.startDate,
          endDate: event.endDate,
          totalAmount: event.amount,
          securityDeposit: securityDeposit,
          deliveryRequired: event.needsDelivery,
          deliveryAddress: event.needsDelivery ? event.deliveryAddress : null,
          deliveryInstructions:
              event.needsDelivery ? event.deliveryInstructions : null,
        );

        // Delivery address is now handled in createBooking method

        // Simulate realistic processing times per payment method
        switch (event.paymentMethod) {
          case 'apple_pay':
            await Future.delayed(const Duration(milliseconds: 300));
            break;
          case 'card':
            await Future.delayed(const Duration(milliseconds: 800));
            break;
          case 'paypal':
            await Future.delayed(const Duration(milliseconds: 1200));
            break;
        }

        // Create transaction record with detailed metadata
        await _bookingRepository.createTransaction(
          rentalId: booking.id,
          transactionId: transactionId,
          amount: event.amount,
          paymentMethod: event.paymentMethod,
          paymentStatus: 'completed',
          gatewayResponse: {
            'gateway': 'simulation',
            'method': event.paymentMethod,
            'processing_time_ms': 1000,
            'success': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Update booking payment status
        await _bookingRepository.updatePaymentStatus(booking.id, 'paid');
        await _bookingRepository.updateBookingStatus(booking.id, 'confirmed');

        emit(PaymentSuccess(
          transactionId: transactionId,
          bookingId: booking.id,
          amount: event.amount,
          paymentMethod: event.paymentMethod,
        ));
      } else {
        // Payment failed - simulate realistic error messages
        final errorMessages = [
          'Your card was declined. Please try another payment method.',
          'Payment processing failed. Please check your payment details.',
          'Transaction timeout. Please try again.',
          'Insufficient funds. Please use a different payment method.',
        ];
        final errorMessage =
            errorMessages[random.nextInt(errorMessages.length)];
        emit(PaymentError(errorMessage));
      }
    } catch (e) {
      emit(PaymentError('Payment failed: ${e.toString()}'));
    }
  }

  Future<void> _onResetPayment(
    ResetPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentInitial());
  }
}
