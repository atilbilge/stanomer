import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';

Future<FilePickerResult?> pickContractFile(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  
  String titleText = 'Select Contract Source';
  String pdfText = 'Select Document (PDF)';
  String imgText = 'Select Photo / Gallery';
  
  if (l.localeName == 'tr') {
    titleText = 'Sözleşme Kaynağı Seçin';
    pdfText = 'Belge Seç (PDF)';
    imgText = 'Fotoğraf Seç / Galeri';
  } else if (l.localeName.startsWith('sr')) {
    titleText = 'Izaberi izvor ugovora';
    pdfText = 'Izaberi dokument (PDF)';
    imgText = 'Izaberi sliku / Galerija';
  } else if (l.localeName == 'ru') {
    titleText = 'Выберите источник договора';
    pdfText = 'Выбрать документ (PDF)';
    imgText = 'Выбрать фото / Галерея';
  }

  final source = await showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return ResilientBottomSheetWrapper(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  titleText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: Text(pdfText),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: Text(imgText),
                onTap: () => Navigator.pop(ctx, 'image'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  return await (source == 'pdf'
      ? FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'PDF'],
          withData: true,
        )
      : FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        ));
}
