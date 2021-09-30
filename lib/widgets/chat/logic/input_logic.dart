import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:masterme_chat/helpers/dialogs.dart';

class InputWidgetLogic {
  BuildContext context;
  Function onPickVideo;
  Function onPickFile;
  Function onPickImage;
  Function onPickAudio;

  InputWidgetLogic({
    this.context,
    this.onPickFile,
    this.onPickImage,
    this.onPickVideo,
    this.onPickAudio,
  });

  /* Отправка голосового сообщения */
  void handleAudioSelection(String path) async {
    File result = File(path);
    final fileName = result.path.split('/').last;
    final bytes = await result.readAsBytes();
    final size = bytes.length;
    JabberConn.fileUploadManager.queryRequestSlot(fileName, size);
    await onPickAudio(result.path);
  }

  /* Загрузка изображения */
  void handleImageSelection({ImageSource source = ImageSource.gallery}) async {
    PickedFile result;
    try {
      result = await ImagePicker().getImage(
        source: source,
      );
    } catch (err) {
      permissionsErrorDialog('фото', context);
      return;
    }

    if (result != null) {
      final imageName = result.path.split('/').last;
      final bytes = await result.readAsBytes();
      final size = bytes.length;
      /*
      final image = await decodeImageFromList(bytes);
      final uri = result.path;
      final width = image.width.toDouble();
      final height = image.height.toDouble();
       */
      JabberConn.fileUploadManager.queryRequestSlot(imageName, size);
      await onPickImage(result.path);
    } else {
      // User canceled the picker
    }
  }

  /* Отправка файла */
  void handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final fileName = result.files.single.name;
      final size = result.files.single.size;
      final path = result.files.single.path ?? '';

      JabberConn.fileUploadManager.queryRequestSlot(fileName, size);
      await onPickFile(path);
    } else {
      // User canceled the picker
    }
  }

  /* Загрузка видео файла */
  void handleVideoSelection({ImageSource source = ImageSource.gallery}) async {
    PickedFile result;
    try {
      result = await ImagePicker().getVideo(
        source: source,
      );
    } catch (err) {
      permissionsErrorDialog('видео', context);
      return;
    }

    if (result != null) {
      final videoName = result.path.split('/').last;
      final bytes = await result.readAsBytes();
      final size = bytes.length;

      JabberConn.fileUploadManager.queryRequestSlot(videoName, size);
      await onPickVideo(result.path);
    } else {
      // User canceled the picker
    }
  }
}
