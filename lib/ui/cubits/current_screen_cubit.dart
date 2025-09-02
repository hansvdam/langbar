import 'package:flutter_bloc/flutter_bloc.dart';
import '../../send_to_llm.dart' show clearChatMessageMemory, preserveLastMessageAndClearHistory;

class CurrentScreenCubit extends Cubit<Cubit?> {
  CurrentScreenCubit() : super(null);

  List<Cubit> cubitsStack = [];

  void pushCurrentCubit(Cubit cubit) {
    // Check if we're switching to a different screen type
    Cubit? previousCubit = cubitsStack.isNotEmpty ? cubitsStack.last : null;
    
    if (previousCubit != null && previousCubit.runtimeType != cubit.runtimeType) {
      print('Screen type change detected: ${previousCubit.runtimeType} -> ${cubit.runtimeType}, clearing chat memory but preserving last message');
      preserveLastMessageAndClearHistory();
    }
    
    cubitsStack.add(cubit);
    emit(cubit);
  }

  void setActiveCubit(Cubit cubit) {
    // For tab navigation - switch to an existing cubit in the stack
    Cubit? previousCubit = state;
    
    if (previousCubit != null && previousCubit.runtimeType != cubit.runtimeType) {
      print('Tab navigation detected: ${previousCubit.runtimeType} -> ${cubit.runtimeType}, clearing chat memory but preserving last message');
      preserveLastMessageAndClearHistory();
    }
    
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
