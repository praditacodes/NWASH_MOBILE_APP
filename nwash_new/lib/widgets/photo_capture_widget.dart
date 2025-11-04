import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PhotoCaptureWidget extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onPhotosChanged;

  const PhotoCaptureWidget({required this.photos, required this.onPhotosChanged});

  Future<void> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      // Save the photo to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      final newPhotos = List<String>.from(photos)..add(savedImage.path);
      onPhotosChanged(newPhotos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photo Capture', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (i) {
            return Container(
              margin: EdgeInsets.all(4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: i < photos.length ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: i < photos.length
                    ? DecorationImage(
                        image: FileImage(File(photos[i])),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: i < photos.length
                  ? null
                  : Center(child: Text('${i + 1}')),
            );
          }),
        ),
        ElevatedButton.icon(
          onPressed: photos.length < 5
              ? () => _takePhoto(context)
              : null,
          icon: Icon(Icons.camera_alt),
          label: Text('Take Photo'),
        ),
      ],
    );
  }
}