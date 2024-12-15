import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentScreenCubit extends Cubit<Cubit?> {
  CurrentScreenCubit() : super(null);

  List<Cubit> cubitsStack = [];

  void pushCurrentCubit(Cubit cubit) {
    cubitsStack.add(cubit);
    emit(cubit);
  }

  void removeCurrentCubit(Cubit cubit) {
    print('removing cubit: $cubit');
    cubitsStack.remove(cubit);
    if (cubitsStack.isEmpty) {
      emit(null);
    } else {
      emit(cubitsStack.last);
    }
  }
}
