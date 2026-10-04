import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/sales/domain/entities/sale_entity.dart';
import '../../features/settings/domain/entities/settings_entity.dart';

class PdfInvoiceHelper {
  static Future<void> printReceipt({
    required SaleEntity sale,
    required ShopSettingsEntity settings,
  }) async {
    final doc = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      boldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                settings.shopName,
                style: pw.TextStyle(font: boldFont, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              if (settings.shopPhone.isNotEmpty)
                pw.Text(
                  'هاتف: ${settings.shopPhone}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (settings.shopAddress.isNotEmpty)
                pw.Text(
                  settings.shopAddress,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Invoice Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('فاتورة: #${sale.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '${sale.createdAt.year}/${sale.createdAt.month}/${sale.createdAt.day}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (sale.customerName != null)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('العميل: ${sale.customerName}', style: const pw.TextStyle(fontSize: 10)),
                ),
              pw.Divider(thickness: 1),

              // Items Table Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('الصنف', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                  pw.Expanded(flex: 1, child: pw.Text('كمية', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                  pw.Expanded(flex: 1, child: pw.Text('سعر', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                  pw.Expanded(flex: 1, child: pw.Text('إجمالي', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text(item.unitPrice.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text(item.totalPrice.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 1),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المجموع الفرعي:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${sale.subtotal.toStringAsFixed(2)} ${settings.currency}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الخصم:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('- ${sale.discountAmount.toStringAsFixed(2)} ${settings.currency}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي النهائي:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.Text('${sale.totalAmount.toStringAsFixed(2)} ${settings.currency}', style: pw.TextStyle(font: boldFont, fontSize: 13)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المدفوع نقداً:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${sale.paidAmount.toStringAsFixed(2)} ${settings.currency}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (sale.remainingAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المتبقي على الحساب:', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.Text('${sale.remainingAmount.toStringAsFixed(2)} ${settings.currency}', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                  ],
                ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Footer
              pw.SizedBox(height: 4),
              pw.Text(
                settings.invoiceFooter,
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'receipt_${sale.invoiceNumber}.pdf',
    );
  }
}
