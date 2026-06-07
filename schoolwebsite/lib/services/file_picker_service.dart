import 'package:file_picker/file_picker.dart';

/// Opens a native file picker restricted to images and PDF files.
/// Returns the selected file name, or null if the user cancelled.
Future<String?> pickResultsFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    allowMultiple: false,
  );
  return result?.files.first.name;
}
