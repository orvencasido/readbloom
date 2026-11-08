import 'dart:typed_data';

class PickedProfileImage {
  final Uint8List bytes;
  final String fileName;

  const PickedProfileImage({required this.bytes, required this.fileName});
}
