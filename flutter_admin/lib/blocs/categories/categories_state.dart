import 'package:equatable/equatable.dart';
import '../../models/main_category_model.dart';
import '../../models/sub_category_model.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<MainCategoryModel> mainCategories;
  final List<SubCategoryModel> subCategories;
  final String? selectedMainCategoryId;

  const CategoriesLoaded({
    required this.mainCategories,
    required this.subCategories,
    this.selectedMainCategoryId,
  });

  @override
  List<Object?> get props =>
      [mainCategories, subCategories, selectedMainCategoryId];
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryOperationSuccess extends CategoriesState {
  final String message;

  const CategoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
