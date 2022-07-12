import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vector_icon_generator/change_notifiers/icon_color_notifier.dart';
import 'package:vector_icon_generator/models/icon_model.dart';
import 'package:vector_icon_generator/widgets/check_box.dart';
import 'package:xml/xml.dart';

class VectorIcon extends StatelessWidget {
  VectorIcon(this.icon, {super.key});

  static String _fileLocation = "";
  static String _iconSize = "24";
  static bool _xmlTinted = false;

  final IconModel icon;

  final _fileLocationController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _iconSizeController = TextEditingController();

  Future _copyPngFile(String destPath, Color color) async {
    final content = await icon.svgIconFile.readAsString();
    final document = XmlDocument.parse(content);
    for (final p0 in document.findAllElements("path")) {
      p0.setAttribute("fill", "#${color.value.toRadixString(16).substring(2)}");
    }

    final svgString = document.toXmlString();
    final svgDrawableRoot = await svg.fromSvgString(svgString, icon.name);
    final iconSize = int.tryParse(_iconSize) ?? 256;
    final picture = svgDrawableRoot.toPicture(size: Size(iconSize.toDouble(), iconSize.toDouble()));
    final bytes = await (await picture.toImage(iconSize, iconSize)).toByteData(format: ImageByteFormat.png);
    if (bytes != null) {
      final dest = File(destPath);
      await dest.create(recursive: true);
      await dest.writeAsBytes(bytes.buffer.asInt8List());
    } else {
      throw Exception();
    }
  }

  Future _copySvgFile(String destPath, Color color) async {
    final dest = File(destPath);

    final content = await icon.svgIconFile.readAsString();
    final document = XmlDocument.parse(content);
    for (final p0 in document.findAllElements("path")) {
      p0.setAttribute("fill", "#${color.value.toRadixString(16).substring(2)}");
    }
    await dest.create();
    await dest.writeAsString(document.toXmlString());
  }

  Future _copyXmlFile(String destPath, Color color) async {
    final dest = File(destPath);

    final content = await icon.svgIconFile.readAsString();
    final document = XmlDocument.parse(content);
    final vector = XmlDocument.parse('<vector xmlns:android="http://schemas.android.com/apk/res/android"></vector>');
    vector.rootElement.children.addAll(document.findAllElements("path").map((p0) => XmlElement(XmlName("path"), [
          XmlAttribute(XmlName("pathData", "android"), p0.getAttribute("d") ?? ""),
          XmlAttribute(XmlName("fillColor", "android"), "@android:color/white"),
        ])));
    vector.rootElement.setAttribute("android:tint", _xmlTinted ? "#${color.value.toRadixString(16).substring(2)}" : "?attr/colorControlNormal");
    final viewBox = (document.rootElement.getAttribute("viewBox") ?? "0 0 24 24").split(" ");
    if (viewBox.length == 4) {
      vector.rootElement.setAttribute("android:viewportWidth", viewBox[2]);
      vector.rootElement.setAttribute("android:viewportHeight", viewBox[3]);
    } else {
      vector.rootElement.setAttribute("android:viewportWidth", "24dp");
      vector.rootElement.setAttribute("android:viewportHeight", "24dp");
    }
    vector.rootElement.setAttribute("android:width", "${_iconSize}dp");
    vector.rootElement.setAttribute("android:height", "${_iconSize}dp");

    await dest.create();
    await dest.writeAsString(vector.toXmlString());
  }

  @override
  Widget build(BuildContext context) {
    _fileNameController.text = icon.destFileName;

    return Tooltip(
      message: icon.name,
      textStyle: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(5))),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              final color = Provider.of<IconColorNotifier>(context, listen: false).iconColor;
              _fileLocationController.text = _fileLocation;
              _iconSizeController.text = _iconSize;
              return AlertDialog(
                title: Text(icon.name),
                content: SizedBox(
                  width: 400,
                  height: 400,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: SvgPicture.file(icon.svgIconFile, color: color),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(border: OutlineInputBorder(), label: Text("Destination")),
                        onChanged: (value) => _fileLocation = value,
                        controller: _fileLocationController,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(border: OutlineInputBorder(), label: Text("File Name")),
                        controller: _fileNameController,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(border: OutlineInputBorder(), label: Text("Icon Size")),
                              onChanged: (value) => _iconSize = value,
                              controller: _iconSizeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 20, right: 5), child: CheckBoxStateful(value: _xmlTinted, onChanged: (value) => _xmlTinted = value)),
                          const Text("Tinted XML"),
                        ],
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final fileName = _fileNameController.text;
                      final fileLocation = _fileLocationController.text;
                      if (fileLocation.isEmpty || fileName.isEmpty) return;
                      _copySvgFile("$fileLocation/$fileName.svg", color).catchError((e) {
                        debugPrint(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to copy, please try again.")));
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("SVG"),
                  ),
                  TextButton(
                    onPressed: () {
                      final fileName = _fileNameController.text;
                      final fileLocation = _fileLocationController.text;
                      if (fileLocation.isEmpty || fileName.isEmpty) return;
                      _copyPngFile("$fileLocation/$fileName.png", color).catchError((e) {
                        debugPrint(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to copy, please try again.")));
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("PNG"),
                  ),
                  TextButton(
                    onPressed: () {
                      final fileName = _fileNameController.text;
                      final fileLocation = _fileLocationController.text;
                      if (fileLocation.isEmpty || fileName.isEmpty) return;
                      _copyXmlFile("$fileLocation/$fileName.xml", color).catchError((e) {
                        debugPrint(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to copy, please try again.")));
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Android XML"),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor, width: 2), borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(10),
          child: Image.file(
            icon.iconFile,
            color: Provider.of<IconColorNotifier>(context).iconColor,
          ),
        ),
      ),
    );
  }
}
