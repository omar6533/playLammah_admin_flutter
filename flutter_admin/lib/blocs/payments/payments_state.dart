import 'package:equatable/equatable.dart';
import '../../models/payment_model.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();
  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<PaymentModel> payments;
  const PaymentsLoaded(this.payments);
  @override
  List<Object?> get props => [payments];
}

class PaymentsError extends PaymentsState {
  final String message;
  const PaymentsError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentOperationSuccess extends PaymentsState {
  final String message;
  const PaymentOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
