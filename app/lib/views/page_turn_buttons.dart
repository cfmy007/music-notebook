import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PageTurnButtons extends StatelessWidget {
  const PageTurnButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentBloc, DocumentState>(
      builder: (context, state) {
        if (state is! DocumentLoadSuccess) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBtn(context, state, PhosphorIconsLight.caretLeft, -1),
                const SizedBox(width: 8),
                _buildBtn(context, state, PhosphorIconsLight.caretRight, 1),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBtn(
    BuildContext context,
    DocumentLoadSuccess s,
    IconData icon,
    int delta,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _turn(context, s, delta),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _turn(BuildContext context, DocumentLoadSuccess s, int delta) {
    final pages = s.data.getPages(true);
    final i = s.data.getPageIndex(s.pageName);
    if (i != null && i + delta >= 0 && i + delta < pages.length) {
      context.read<DocumentBloc>().add(PageChanged(pages[i + delta]));
    }
  }
}
