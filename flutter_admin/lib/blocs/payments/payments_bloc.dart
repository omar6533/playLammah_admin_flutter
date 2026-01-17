import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import '../../models/payment_model.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final FirestoreService _firestoreService;

  PaymentsBloc(this._firestoreService) : super(PaymentsInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<CreatePayment>(_onCreatePayment);
    on<UpdatePayment>(_onUpdatePayment);
    on<DeletePayment>(_onDeletePayment);
  }

  Future<void> _onLoadPayments(
      LoadPayments event, Emitter<PaymentsState> emit) async {
    emit(PaymentsLoading());
    try {
      await emit.forEach(
        _firestoreService.getPayments(),
        onData: (List<PaymentModel> payments) => PaymentsLoaded(payments),
        onError: (error, stackTrace) => PaymentsError(error.toString()),
      );
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onCreatePayment(
      CreatePayment event, Emitter<PaymentsState> emit) async {
    try {
      final payment = PaymentModel.fromFirestore(event.data, '');
      await _firestoreService.addPayment(payment);
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onUpdatePayment(
      UpdatePayment event, Emitter<PaymentsState> emit) async {
    try {
      final payment = PaymentModel.fromFirestore(event.data, event.id);
      await _firestoreService.updatePayment(event.id, payment);
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onDeletePayment(
      DeletePayment event, Emitter<PaymentsState> emit) async {
    try {
      await _firestoreService.deletePayment(event.id);
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }
}
