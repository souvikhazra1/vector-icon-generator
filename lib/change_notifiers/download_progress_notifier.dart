import 'package:flutter/material.dart';
import 'package:vector_icon_generator/models/download_progress_model.dart';

class DownloadProgressNotifier extends ChangeNotifier {
  DownloadProgressModel _progress = DownloadProgressModel(null, "");

  DownloadProgressModel get progress => _progress;

  void setProgress(DownloadProgressModel progress) {
    _progress = progress;
    notifyListeners();
  }
}