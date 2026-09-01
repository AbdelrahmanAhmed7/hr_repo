import 'package:flutter/material.dart';

import '../models/organization_models.dart';

class ExportService {
  static Future<void> exportAsImage({
    required OrganizationData organizationData,
    required BuildContext context,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تصدير كصورة: تحتاج إضافة package screenshot أو widget_to_image',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Export organization chart as PDF
  /// Note: Requires pdf package for actual implementation
  static Future<void> exportAsPDF({
    required OrganizationData organizationData,
    required BuildContext context,
  }) async {
    // TODO: Implement with pdf package
    // Example:
    // final pdf = pdf.Document();
    // pdf.addPage(pdf.Page(
    //   build: (pdf.Context context) {
    //     return pdf.Table(...);
    //   },
    // ));
    // final bytes = await pdf.save();
    // final directory = await getApplicationDocumentsDirectory();
    // final pdfPath = '${directory.path}/org_chart_${DateTime.now().millisecondsSinceEpoch}.pdf';
    // final pdfFile = File(pdfPath);
    // await pdfFile.writeAsBytes(bytes);
    // await Share.shareFiles([pdfPath]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تصدير كـ PDF: تحتاج إضافة package pdf'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Export organization chart as Excel
  /// Note: Requires excel package for actual implementation
  static Future<void> exportAsExcel({
    required OrganizationData organizationData,
    required BuildContext context,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تصدير كـ Excel: تحتاج إضافة package excel'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show export options dialog
  static Future<void> showExportDialog({
    required BuildContext context,
    required OrganizationData organizationData,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'تصدير الهيكل التنظيمي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Export options
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Colors.green),
                title: const Text('تصدير كصورة'),
                subtitle: const Text('PNG أو JPG'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  exportAsImage(
                    organizationData: organizationData,
                    context: context,
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.red,
                ),
                title: const Text('تصدير كـ PDF'),
                subtitle: const Text('ملف PDF قابل للطباعة'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  exportAsPDF(
                    organizationData: organizationData,
                    context: context,
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.table_chart_outlined,
                  color: Colors.blue,
                ),
                title: const Text('تصدير كـ Excel'),
                subtitle: const Text('ملف Excel قابل للتعديل'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  exportAsExcel(
                    organizationData: organizationData,
                    context: context,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
