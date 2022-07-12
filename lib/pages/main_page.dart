import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:vector_icon_generator/change_notifiers/dark_mode_notifier.dart';
import 'package:vector_icon_generator/change_notifiers/download_progress_notifier.dart';
import 'package:vector_icon_generator/change_notifiers/icon_color_notifier.dart';
import 'package:vector_icon_generator/models/icon_model.dart';
import 'package:vector_icon_generator/utils.dart';
import 'package:vector_icon_generator/widgets/icon_list.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<IconSiteModel> _iconSites = [];

  IconSiteModel? _selected;
  var _iconsLoaded = false;
  var _search = "";

  @override
  void initState() {
    super.initState();
    IconStore.loadIcons().then((value) {
      setState(() {
        _iconsLoaded = true;
        _iconSites = IconStore.iconSites!;
        _selected = _iconSites[0];
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _download() async {
    for (final element in _iconSites) {
      await element.download((value) => Provider.of<DownloadProgressNotifier>(context, listen: false).setProgress(value));
    }
    await IconStore.loadIcons(force: true);
    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() {
      _iconSites = IconStore.iconSites!;
      _selected = _iconSites[0];
    });
  }

  void _reload() async {
    setState(() => _iconsLoaded = false);
    await IconStore.loadIcons(force: true);
    if (!mounted) return;
    setState(() {
      _iconsLoaded = true;
      _iconSites = IconStore.iconSites!;
      _selected = _iconSites[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_iconsLoaded) {
      final icons = _selected?.icons ?? [];
      final search = _search.toLowerCase();
      body = IconList(_search.isEmpty ? icons : (icons.where((element) => element.tag.contains(search))).toList());
    } else {
      body = const Center(child: Text("Loading...."));
    }
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: max(MediaQuery.of(context).size.width * 0.2, 240),
            child: ListView.builder(
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: TextField(
                      decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: 'Search', prefixIcon: Icon(Icons.search)),
                      onSubmitted: (value) => setState(() => _search = value),
                    ),
                  );
                } else {
                  final item = _iconSites[index - 1];
                  final isSelected = item == _selected;
                  return ListTile(
                    title: Text(item.name),
                    style: ListTileStyle.drawer,
                    selected: isSelected,
                    selectedColor: Theme.of(context).canvasColor,
                    selectedTileColor: Theme.of(context).primaryColor,
                    onTap: () => setState(() => _selected = item),
                  );
                }
              },
              itemCount: _iconSites.length + 1,
            ),
          ),
          Container(width: 1, color: Theme.of(context).dividerColor),
          Expanded(child: body),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  var c = Provider.of<IconColorNotifier>(context, listen: false).iconColor;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Color Picker"),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: c,
                          onColorChanged: (color) => c = color,
                          enableAlpha: false,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Provider.of<IconColorNotifier>(context, listen: false).resetColor();
                            Navigator.of(context).pop();
                          },
                          child: const Text("Reset Color"),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<IconColorNotifier>(context, listen: false).setColor(c);
                            Navigator.of(context).pop();
                          },
                          child: const Text("Select Color"),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.color_lens_outlined, color: Theme.of(context).primaryColor),
              ),
              IconButton(
                onPressed: () {
                  // download
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(value: Provider.of<DownloadProgressNotifier>(context).progress.progress),
                              Container(margin: const EdgeInsets.only(left: 24), child: Text(Provider.of<DownloadProgressNotifier>(context).progress.message)),
                            ],
                          ),
                        );
                      },
                      barrierDismissible: false);
                  _download();
                },
                icon: Icon(Icons.cloud_download_outlined, color: Theme.of(context).primaryColor),
              ),
              IconButton(onPressed: _reload, icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor)),
              IconButton(
                onPressed: () => Provider.of<DarkModeNotifier>(context, listen: false).toggle(),
                icon: Icon(Utils.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Theme.of(context).primaryColor),
              ),
            ],
          )
        ],
      ),
    );
  }
}
