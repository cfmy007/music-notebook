import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keybinder/keybinder.dart';

class NextIntent extends Intent {
  const NextIntent();
}

const nextShortcut = ShortcutDefinition(
  id: 'next',
  intent: NextIntent(),
  defaultActivator: SingleActivator(LogicalKeyboardKey.arrowRight),
);

class NextAction extends Action<NextIntent> {
  final BuildContext context;

  NextAction(this.context);

  @override
  void invoke(NextIntent intent) {
    final bloc = context.read<DocumentBloc>();
    final state = bloc.state;
    if (state is DocumentPresentationState) {
      state.handler.next(bloc, context);
      return;
    }
    if (state is DocumentLoadSuccess) {
      final pages = state.data.getPages(true);
      final i = state.data.getPageIndex(state.pageName);
      if (i != null && i < pages.length - 1) {
        bloc.add(PageChanged(pages[i + 1]));
      }
    }
  }
}
