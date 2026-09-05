import 'package:ai_workbench/shared/platform/script_picker_service.dart';
import 'package:file_picker/file_picker.dart';

class FileScriptPickerService implements ScriptPickerService {
  const FileScriptPickerService();

  @override
  Future<String?> pickScript() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择启动脚本',
      type: FileType.custom,
      allowedExtensions: const ['sh', 'command'],
    );
    return result?.files.single.path;
  }
}
