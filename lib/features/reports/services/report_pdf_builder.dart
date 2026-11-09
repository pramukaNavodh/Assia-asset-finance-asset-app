//pdf generator class

//libraries
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

//internal resource files
import '../../../core/utils/formatters.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/report_models.dart';
import '../../dashboard/models/asset_model.dart';

// generates the A4 PDF for a report. Uses the built-in PDF font, so names in
// Sinhala/Tamil would need an extra font added later.
Future<Uint8List> buildReportPdf({
  required ReportType type,
  required ReportData data,
  required String branchLabel,
  required String categoryLabel,
  required String rangeLabel,
}) async {
  final navy = PdfColor.fromInt(0xFF0F3D6E);
  final doc = pw.Document(title: '${type.label} report', author: 'Asia Asset Finance PLC');
  final generated = Formatters.shortDate(DateTime.now());

  pw.Widget box(String label, String value) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ),
  );

  pw.Widget table(List<String> headers, List<List<String>> rows,
      {Map<int, pw.Alignment>? align}) {
    if (rows.isEmpty) return pw.Text('No records match the selected filters.');
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
          fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: pw.TextStyle(fontSize: 8.5),
      headerDecoration: pw.BoxDecoration(color: navy),
      oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: align,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    );
  }

  String branchName(String id) => Branches.byId(id)?.name ?? '-';

  List<pw.Widget> summary() {
    if (type == ReportType.expiries) {
      final e = data.expiries;
      return [
        pw.Row(children: [
          box('Expired', '${e.where((i) => i.daysLeft < 0).length}'),
          box('Due in 30 days', '${e.where((i) => i.daysLeft >= 0 && i.daysLeft <= 30).length}'),
          box('Due in 90 days', '${e.where((i) => i.daysLeft > 30).length}'),
          box('Total items', '${e.length}'),
        ]),
      ];
    }
    return [
      pw.Row(children: [
        box('Assets', Formatters.number(data.assets.length)),
        box('Purchase value', Formatters.currencyFull(data.totalPurchase)),
        box('Current value', Formatters.currencyFull(data.totalCurrent)),
        box('Depreciation', Formatters.currencyFull(data.totalDepreciation)),
      ]),
    ];
  }

  List<pw.Widget> body() {
    switch (type) {
      case ReportType.register:
        return [
          table(
            ['#', 'Asset', 'Category', 'Branch', 'Acquired', 'Price', 'Current value'],
            [
              for (var i = 0; i < data.assets.length; i++)
                [
                  '${i + 1}',
                  data.assets[i].title,
                  data.assets[i].category.label,
                  branchName(data.assets[i].branchId),
                  Formatters.shortDate(data.assets[i].dateObtained),
                  Formatters.number(data.assets[i].price),
                  Formatters.number(data.assets[i].currentValue),
                ],
            ],
            align: {5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight},
          ),
        ];
      case ReportType.valuation:
        final rows = data.valuation;
        return [
          table(
            ['Category', 'Assets', 'Purchase value', 'Current value', 'Depreciation', 'Remaining'],
            [
              for (final v in rows)
                [
                  v.category.label,
                  '${v.count}',
                  Formatters.number(v.purchase),
                  Formatters.number(v.current),
                  Formatters.number(v.depreciation),
                  '${v.remainingPercent.toStringAsFixed(0)}%',
                ],
              if (rows.isNotEmpty)
                [
                  'TOTAL',
                  '${data.assets.length}',
                  Formatters.number(data.totalPurchase),
                  Formatters.number(data.totalCurrent),
                  Formatters.number(data.totalDepreciation),
                  '',
                ],
            ],
            align: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
        ];
      case ReportType.expiries:
        return [
          table(
            ['Asset', 'Branch', 'Type', 'Expiry date', 'Status'],
            [
              for (final e in data.expiries)
                [
                  e.asset.title,
                  branchName(e.asset.branchId),
                  e.kind,
                  Formatters.shortDate(e.date),
                  e.daysLeft < 0
                      ? 'Expired ${-e.daysLeft} days ago'
                      : 'In ${e.daysLeft} days',
                ],
            ],
          ),
        ];
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Asia Asset Finance PLC',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navy)),
          pw.Text('${type.label} report', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text('Branch: $branchLabel  |  Category: $categoryLabel  |  Acquired: $rangeLabel',
              style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          pw.Divider(color: PdfColors.grey400),
        ],
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated $generated', style: pw.TextStyle(fontSize: 8)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8)),
        ],
      ),
      build: (_) => [...summary(), pw.SizedBox(height: 14), ...body()],
    ),
  );

  return doc.save();
}