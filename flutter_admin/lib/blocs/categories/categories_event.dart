import 'package:equatable/equatable.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {
  final String? selectedMainCategoryId;

  const LoadCategories({this.selectedMainCategoryId});

  @override
  List<Object?> get props => [selectedMainCategoryId];
}

class CreateMainCategory extends CategoriesEvent {
  final Map<String, dynamic> data;

  const CreateMainCategory(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateMainCategory extends CategoriesEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateMainCategory(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class ToggleMainCategoryStatus extends CategoriesEvent {
  final String id;
  final bool isActive;

  const ToggleMainCategoryStatus(this.id, this.isActive);

  @override
  List<Object?> get props => [id, isActive];
}

class CreateSubCategory extends CategoriesEvent {
  final Map<String, dynamic> data;

  const CreateSubCategory(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateSubCategory extends CategoriesEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateSubCategory(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class ToggleSubCategoryStatus extends CategoriesEvent {
  final String id;
  final bool isActive;

  const ToggleSubCategoryStatus(this.id, this.isActive);

  @override
  List<Object?> get props => [id, isActive];
}
