part of 'handler.dart';

class MetronomeHandler extends Handler<MetronomeTool> {
  MetronomeHandler(super.data);

  @override
  FutureOr<SelectState> onSelected(
    BuildContext context, [
    bool wasAdded = true,
  ]) {
    showDialog(context: context, builder: (context) => const MetronomeDialog());
    return SelectState.none;
  }

  @override
  PhosphorIconData? getIcon(DocumentBloc bloc) =>
      PhosphorIconsRegular.metronome;

  @override
  ToolStatus getStatus(DocumentBloc bloc) => ToolStatus.normal;

  @override
  MouseCursor? get cursor => SystemMouseCursors.click;
}
