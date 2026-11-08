// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_profile_image.dart';

Future<PickedProfileImage?> pickPlatformProfileImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp';
  final completer = Completer<PickedProfileImage?>();

  input.onChange.first.then((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(
          PickedProfileImage(bytes: result.asUint8List(), fileName: file.name),
        );
      } else {
        completer.complete(null);
      }
    });
    reader.onError.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
