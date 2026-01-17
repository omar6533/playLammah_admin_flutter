import 'package:equatable/equatable.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentsEvent {}

class CreatePayment extends PaymentsEvent {
  final Map<String, dynamic> data;
  const CreatePayment(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdatePayment extends PaymentsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdatePayment(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeletePayment extends PaymentsEvent {
  final String id;
  const DeletePayment(this.id);
  @override
  List<Object?> get props => [id];
}
