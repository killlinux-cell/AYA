import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PDFReceiptService {
  static final PDFReceiptService _instance = PDFReceiptService._internal();
  factory PDFReceiptService() => _instance;
  PDFReceiptService._internal();

  /// Générer les bytes du reçu PDF pour un échange
  Future<Uint8List> buildExchangeReceiptBytes({
    required Map<String, dynamic> exchangeRequest,
    required Map<String, dynamic> vendorInfo,
    required String clientName,
    required String clientEmail,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildReceiptContent(
            exchangeRequest: exchangeRequest,
            vendorInfo: vendorInfo,
            clientName: clientName,
            clientEmail: clientEmail,
          );
        },
      ),
    );
    return pdf.save();
  }

  String _receiptFileName(Map<String, dynamic> exchangeRequest) {
    final id = exchangeRequest['id']?.toString() ?? 'N/A';
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    return 'Facture_Echange_$shortId.pdf';
  }

  /// Générer un reçu PDF pour un échange (aperçu / impression)
  Future<void> generateExchangeReceipt({
    required Map<String, dynamic> exchangeRequest,
    required Map<String, dynamic> vendorInfo,
    required String clientName,
    required String clientEmail,
  }) async {
    try {
      final pdfBytes = await buildExchangeReceiptBytes(
        exchangeRequest: exchangeRequest,
        vendorInfo: vendorInfo,
        clientName: clientName,
        clientEmail: clientEmail,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: _receiptFileName(exchangeRequest),
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du reçu PDF: $e');
    }
  }

  /// Enregistrer la facture localement sur l'appareil
  Future<String> saveExchangeReceipt({
    required Map<String, dynamic> exchangeRequest,
    required Map<String, dynamic> vendorInfo,
    required String clientName,
    required String clientEmail,
  }) async {
    final pdfBytes = await buildExchangeReceiptBytes(
      exchangeRequest: exchangeRequest,
      vendorInfo: vendorInfo,
      clientName: clientName,
      clientEmail: clientEmail,
    );
    return savePDFLocally(pdfBytes, _receiptFileName(exchangeRequest));
  }

  /// Partager la facture (WhatsApp, email, etc.)
  Future<void> shareExchangeReceipt({
    required Map<String, dynamic> exchangeRequest,
    required Map<String, dynamic> vendorInfo,
    required String clientName,
    required String clientEmail,
  }) async {
    final pdfBytes = await buildExchangeReceiptBytes(
      exchangeRequest: exchangeRequest,
      vendorInfo: vendorInfo,
      clientName: clientName,
      clientEmail: clientEmail,
    );
    await sharePDF(pdfBytes, _receiptFileName(exchangeRequest));
  }

  /// Construire le contenu du reçu
  pw.Widget _buildReceiptContent({
    required Map<String, dynamic> exchangeRequest,
    required Map<String, dynamic> vendorInfo,
    required String clientName,
    required String clientEmail,
  }) {
    print('📄 PDF: _buildReceiptContent - Début');
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final exchangeId = exchangeRequest['id']?.toString() ?? 'N/A';
    final points = exchangeRequest['points']?.toString() ?? '0';
    final completedAt = exchangeRequest['completed_at'] != null
        ? DateTime.parse(exchangeRequest['completed_at'])
        : now;

    print('📄 PDF: _buildReceiptContent - Données extraites');
    print('📄 PDF: exchangeId: $exchangeId, points: $points');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec logo et informations
        _buildHeader(vendorInfo, dateFormat.format(now)),

        pw.SizedBox(height: 30),

        // Titre du reçu
        pw.Center(
          child: pw.Text(
            'REÇU D\'ÉCHANGE DE POINTS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),

        pw.SizedBox(height: 30),

        // Informations de la transaction
        _buildTransactionInfo(
          exchangeId,
          points,
          dateFormat.format(completedAt),
        ),

        pw.SizedBox(height: 30),

        // Informations client
        _buildClientInfo(clientName, clientEmail),

        pw.SizedBox(height: 30),

        // Informations vendeur
        _buildVendorInfo(vendorInfo),

        pw.SizedBox(height: 40),

        // Signature et mentions légales
        _buildFooter(),

        pw.SizedBox(height: 20),

        // Code QR du reçu (optionnel)
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              'Code QR du reçu: $exchangeId',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Construire l'en-tête du reçu
  pw.Widget _buildHeader(Map<String, dynamic> vendorInfo, String date) {
    print('📄 PDF: _buildHeader - Début');
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green.shade(0.1),
        border: pw.Border.all(color: PdfColors.green),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AYA+',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
              pw.Text(
                'Système de Points Fidélité',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Reçu généré le:',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire les informations de transaction
  pw.Widget _buildTransactionInfo(
    String exchangeId,
    String points,
    String completedAt,
  ) {
    print('📄 PDF: _buildTransactionInfo - Début');
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DE LA TRANSACTION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('ID Transaction:', exchangeId),
          _buildInfoRow('Points échangés:', '$points points'),
          _buildInfoRow('Date de validation:', completedAt),
          _buildInfoRow('Statut:', 'Complété'),
        ],
      ),
    );
  }

  /// Construire les informations client
  pw.Widget _buildClientInfo(String clientName, String clientEmail) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue.shade(0.1),
        border: pw.Border.all(color: PdfColors.blue),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS CLIENT',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('Nom:', clientName.isNotEmpty ? clientName : 'N/A'),
          _buildInfoRow('Email:', clientEmail.isNotEmpty ? clientEmail : 'N/A'),
        ],
      ),
    );
  }

  /// Construire les informations vendeur
  pw.Widget _buildVendorInfo(Map<String, dynamic> vendorInfo) {
    print('📄 PDF: _buildVendorInfo - Début');
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange.shade(0.1),
        border: pw.Border.all(color: PdfColors.orange),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS VENDEUR',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow(
            'Nom de l\'entreprise:',
            vendorInfo['business_name']?.toString() ?? 'N/A',
          ),
          _buildInfoRow(
            'Code vendeur:',
            vendorInfo['vendor_code']?.toString() ?? 'N/A',
          ),
          _buildInfoRow(
            'Adresse:',
            vendorInfo['business_address']?.toString() ?? 'N/A',
          ),
          _buildInfoRow(
            'Téléphone:',
            vendorInfo['phone_number']?.toString() ?? 'N/A',
          ),
          _buildInfoRow(
            'Email:',
            vendorInfo['user_email']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  /// Construire le pied de page
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey.shade(0.1),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'MERCI POUR VOTRE FIDÉLITÉ !',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Ce reçu confirme l\'échange de vos points de fidélité. '
            'Conservez-le pour vos archives.',
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Signature vendeur:',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Container(width: 100, height: 2, color: PdfColors.black),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire une ligne d'information
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Sauvegarder le PDF localement
  Future<String> savePDFLocally(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }

  /// Partager le PDF
  Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Reçu d\'échange de points Aya+');
    } catch (e) {
      throw Exception('Erreur lors du partage du PDF: $e');
    }
  }

  /// Générer un PDF de l'historique des échanges
  Future<void> generateExchangeHistoryPDF({
    required List<dynamic> exchanges,
    required Map<String, dynamic> stats,
    required Map<String, dynamic> vendorInfo,
  }) async {
    try {
      // Créer le document PDF
      final pdf = pw.Document();

      // Ajouter la page de l'historique
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHistoryHeader(vendorInfo),
              pw.SizedBox(height: 20),
              _buildHistoryStats(stats),
              pw.SizedBox(height: 20),
              _buildHistoryTable(exchanges),
              pw.SizedBox(height: 20),
              _buildHistoryFooter(),
            ];
          },
        ),
      );

      // Générer les bytes du PDF
      final pdfBytes = await pdf.save();

      // Afficher le PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'Historique_Échanges_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF d\'historique: $e');
    }
  }

  /// Construire l'en-tête de l'historique
  pw.Widget _buildHistoryHeader(Map<String, dynamic> vendorInfo) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green.shade(0.1),
        border: pw.Border.all(color: PdfColors.green),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AYA+',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.Text(
                    'Historique des Échanges',
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Généré le:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    dateFormat.format(now),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Vendeur: ${vendorInfo['business_name'] ?? 'N/A'}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Construire les statistiques de l'historique
  pw.Widget _buildHistoryStats(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue.shade(0.1),
        border: pw.Border.all(color: PdfColors.blue),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total Échanges', '${stats['totalExchanges'] ?? 0}'),
          _buildStatColumn('Points Totaux', '${stats['totalPoints'] ?? 0}'),
          _buildStatColumn('Aujourd\'hui', '${stats['todayExchanges'] ?? 0}'),
          _buildStatColumn(
            'Cette Semaine',
            '${stats['thisWeekExchanges'] ?? 0}',
          ),
        ],
      ),
    );
  }

  /// Construire une colonne de statistique
  pw.Widget _buildStatColumn(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Construire le tableau de l'historique
  pw.Widget _buildHistoryTable(List<dynamic> exchanges) {
    if (exchanges.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Center(
          child: pw.Text(
            'Aucun échange trouvé',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Client', isHeader: true),
            _buildTableCell('Points', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Statut', isHeader: true),
          ],
        ),
        // Lignes des échanges
        ...exchanges.map(
          (exchange) => pw.TableRow(
            children: [
              _buildTableCell(exchange.userName ?? 'N/A'),
              _buildTableCell('${exchange.points ?? 0}'),
              _buildTableCell(exchange.formattedDate ?? 'N/A'),
              _buildTableCell('Complété'),
            ],
          ),
        ),
      ],
    );
  }

  /// Construire une cellule de tableau
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Construire le pied de page de l'historique
  pw.Widget _buildHistoryFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey.shade(0.1),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'RAPPORT D\'HISTORIQUE DES ÉCHANGES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Ce document contient l\'historique complet des échanges de points de fidélité.',
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Généré automatiquement par le système AYA+',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
