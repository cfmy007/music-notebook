part of 'handler.dart';

class TunerHandler extends Handler<TunerTool> {
  TunerHandler(super.data);

  @override
  FutureOr<SelectState> onSelected(BuildContext context, [bool wasAdded = true]) {
    showDialog(
      context: context,
      builder: (context) => const TunerDialog(),
    );
    return SelectState.none;
  }

  @override
  PhosphorIconData? getIcon(DocumentBloc bloc) => PhosphorIconsRegular.musicNote;

  @override
  ToolStatus getStatus(DocumentBloc bloc) => ToolStatus.normal;

  @override
  MouseCursor? get cursor => SystemMouseCursors.click;
}
