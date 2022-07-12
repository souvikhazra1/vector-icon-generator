import 'package:flutter/material.dart';
import 'package:vector_icon_generator/constants.dart';
import 'package:vector_icon_generator/models/icon_model.dart';
import 'package:vector_icon_generator/widgets/vector_icon.dart';

class IconList extends StatelessWidget {
  IconList(this.icons, {super.key});

  final List<IconModel> icons;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: Constants.iconSize + 20,
          childAspectRatio: 1,
          crossAxisSpacing: Constants.iconSpacing,
          mainAxisSpacing: Constants.iconSpacing,
        ),
        itemBuilder: (context, idx) => VectorIcon(icons[idx]),
        itemCount: icons.length,
        padding: const EdgeInsets.all(16),
        controller: _scrollController,
      ),
    );
  }
}