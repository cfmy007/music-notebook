import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keybinder/keybinder.dart';

class PreviousIntent extends Intent {
  const PreviousIntent();
}

const previousShortcut = ShortcutDefinition(
  id: 'previous',
  intent: PreviousIntent(),
  defaultActivator: SingleActivator(LogicalKeyboardKey.arrowLeft),
);

class PreviousAction extends Action<PreviousIntent> {
  final BuildContext context;

  PreviousAction(this.context);

  @override
  void invoke(PreviousIntent intent) {
    final bloc = context.read<DocumentBloc>();
    final state = bloc.state;
    if (state is DocumentPresentationState) {
      state.handler.previous(bloc, context);
      return;
    }
    if (state is DocumentLoadSuccess) {
      final pages = state.data.getPages(true);
      final i = state.data.getPageIndex(state.pageName);
      if (i != null && i > 0) {
        bloc.add(PageChanged(pages[i - 1]));
      }
    }
  }
}
