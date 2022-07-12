import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vector_icon_generator/constants.dart';
import 'package:vector_icon_generator/models/download_progress_model.dart';

class IconModel {
  IconModel({
    required this.name,
    required this.iconFile,
    required this.svgIconFile,
    required this.destFileName,
    required this.tag,
  });

  final String name;
  final File iconFile;
  final File svgIconFile;
  final String destFileName;
  final String tag;
}

class IconSiteModel {
  final String name;
  final String key;
  final String downloadLink;
  final String? githubRepo;
  final String svgPath;
  final String rootPath;
  late List<IconModel> icons;

  IconSiteModel({required this.name, required this.key, required this.downloadLink, required this.svgPath, required this.rootPath, this.githubRepo});

  Future loadIcons() async {
    if (rootPath.isNotEmpty) {
      try {
        Map<String, String> tags = {};
        if (key == "cmd") {
          List<dynamic> metas = jsonDecode(await File("$rootPath/meta.json").readAsString());
          for (Map<String, dynamic> meta in metas) {
            tags[meta["name"]] = ((meta["name"] + "-" + (List<String>.from(meta["tags"])).join("-") + "-" + (List<String>.from(meta["aliases"])).join("-")) as String).toLowerCase();
          }
        }
        icons = await Directory("$rootPath/png").list().map((entity) {
          final fileName = entity.path.split("/").last.toLowerCase();
          final fileNameWithoutExt = fileName.substring(fileName.indexOf("-") + 1, fileName.length - 4); // remove .svg
          return IconModel(
            name: "$key-$fileNameWithoutExt",
            iconFile: File(entity.path),
            svgIconFile: File(entity.path.replaceFirst("/png", "/svg").replaceFirst(".png", ".svg")),
            destFileName: "ic_${key}_${fileNameWithoutExt.replaceAll("-", "_")}",
            tag: tags[fileNameWithoutExt] ?? fileNameWithoutExt,
          );
        }).toList();
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
        icons = [];
      }
    }
  }

  Future<Uri> _getDownloadLink() async {
    if (githubRepo != null && githubRepo!.isNotEmpty) {
      try {
        var response = await http.read(Uri.parse("https://api.github.com/repos/$githubRepo"));
        Map<String, dynamic> respJson = jsonDecode(response);
        String? branch = respJson["default_branch"];
        if (branch != null && branch.isNotEmpty) {
          return Uri.parse("https://codeload.github.com/$githubRepo/zip/refs/heads/$branch");
        }
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
      }
      return Uri.parse(downloadLink);
    } else {
      return Uri.parse(downloadLink);
    }
  }

  Future download(ValueChanged<DownloadProgressModel> onProgress) async {
    if (downloadLink.isNotEmpty) {
      try {
        onProgress(DownloadProgressModel(null, "Downloading $name"));
        try {
          await File(rootPath).delete(recursive: true);
        } catch (_) {}
        final Uri url = await _getDownloadLink();
        final response = await http.readBytes(url);
        final zip = ZipDecoder().decodeBytes(response);
        var idx = 1;
        final totalFiles = zip.where((element) => (svgPath.isEmpty || element.name.contains("$svgPath/")) && element.name.endsWith(".svg")).length;
        for (final entry in zip) {
          final fileName = entry.name;
          if (key == "cmd" && fileName.endsWith("meta.json")) {
            // store meta file for community material
            final file = File("$rootPath/meta.json");
            await file.create(recursive: true);
            await file.writeAsBytes(entry.content);
          } else if ((svgPath.isEmpty || fileName.contains("$svgPath/")) && fileName.endsWith(".svg")) {
            onProgress(DownloadProgressModel((idx + 1) / totalFiles, "Processing $name icons: ${idx + 1}/$totalFiles"));
            try {
              // extract only svg files for zip
              final svgFileName = "$idx-${fileName.split("/").last}";
              // covert svg to png
              final svgDrawableRoot = await svg.fromSvgBytes(entry.content, svgFileName);
              final picture = svgDrawableRoot.toPicture(size: const Size(Constants.iconSize, Constants.iconSize));
              final size = Constants.iconSize.toInt();
              final bytes = await (await picture.toImage(size, size)).toByteData(format: ImageByteFormat.png);
              if (bytes != null) {
                final pngFile = File("$rootPath/png/${svgFileName.replaceFirst(".svg", ".png")}");
                await pngFile.create(recursive: true);
                await pngFile.writeAsBytes(bytes.buffer.asInt8List());

                // save svg file if png is generated
                final file = File("$rootPath/svg/$svgFileName");
                await file.create(recursive: true);
                await file.writeAsBytes(entry.content);

                idx++;
              }
            } catch (e, s) {
              debugPrint(e.toString());
              debugPrintStack(stackTrace: s);
            }
          }
        }
      } catch (e, s) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
      }
    }
  }
}

class IconStore {
  static List<IconSiteModel>? iconSites;

  static Future<void> loadIcons({bool force = false}) async {
    final appPath = (await getApplicationSupportDirectory()).path;
    if (force || iconSites == null) {
      iconSites = [
        IconSiteModel(name: "Material Design", key: "cmd", downloadLink: "https://codeload.github.com/Templarian/MaterialDesign/zip/refs/heads/master", rootPath: "$appPath/cmd", svgPath: "svg", githubRepo: "Templarian/MaterialDesign"),
        IconSiteModel(name: "Ionicons", key: "ic", downloadLink: "https://codeload.github.com/ionic-team/ionicons/zip/refs/heads/main", rootPath: "$appPath/ionicons", svgPath: "src/svg", githubRepo: "ionic-team/ionicons"),
        IconSiteModel(name: "Line Awesome", key: "la", downloadLink: "https://codeload.github.com/icons8/line-awesome/zip/refs/heads/master", rootPath: "$appPath/la", svgPath: "svg", githubRepo: "icons8/line-awesome"),
        IconSiteModel(name: "Font Awesome", key: "fa", downloadLink: "https://codeload.github.com/FortAwesome/Font-Awesome/zip/refs/heads/6.x", rootPath: "$appPath/fa", svgPath: "svgs", githubRepo: "FortAwesome/Font-Awesome"),
        IconSiteModel(name: "Octicons", key: "oi", downloadLink: "https://github.com/primer/octicons/archive/refs/heads/main.zip", rootPath: "$appPath/octicons", svgPath: "icons", githubRepo: "primer/octicons"),
        IconSiteModel(name: "Typicons", key: "ti", downloadLink: "https://github.com/stephenhutchings/typicons.font/archive/refs/heads/master.zip", rootPath: "$appPath/typicons", svgPath: "src/svg", githubRepo: "stephenhutchings/typicons.font"),
        IconSiteModel(name: "Devicons", key: "di", downloadLink: "https://github.com/vorillaz/devicons/archive/refs/heads/master.zip", rootPath: "$appPath/devicons", svgPath: "!SVG", githubRepo: "vorillaz/devicons"),
        IconSiteModel(name: "Zondicons", key: "zi", downloadLink: "http://www.zondicons.com/zondicons.zip", rootPath: "$appPath/zondicons", svgPath: ""),
      ];
      final allSites = IconSiteModel(
        name: "All",
        key: "all",
        downloadLink: "",
        rootPath: "",
        svgPath: "",
      );
      allSites.icons = [];
      for (final site in iconSites!) {
        await site.loadIcons();
        allSites.icons.addAll(site.icons);
      }

      iconSites!.insert(0, allSites);
    }
  }
}
