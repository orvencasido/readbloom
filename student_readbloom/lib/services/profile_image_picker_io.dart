import 'package:image_picker/image_picker.dart';

import 'picked_profile_image.dart';

Future<PickedProfileImage?> pickPlatformProfileImage() async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 85,
  );
  if (image == null) return null;

  final bytes = await image.readAsBytes();
  if (bytes.isEmpty) return null;

  return PickedProfileImage(bytes: bytes, fileName: image.name);
}
