import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  /// Générer un PDF de confirmation d'échange
  Future<File> generateExchangeConfirmationPDF({
    required String exchangeCode,
    required String userName,
    required String userEmail,
    required int pointsExchanged,
    required String exchangeDate,
    required String vendorName,
    required String vendorLocation,
  }) async {
    final pdf = pw.Document();

    // Charger la police personnalisée (optionnel)
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'AYA',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AYA HUILE',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Programme de Fidélité',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Titre du document
              pw.Center(
                child: pw.Text(
                  'CONFIRMATION D\'ÉCHANGE',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // Code d'échange
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Code d\'Échange',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      exchangeCode,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Informations de l'échange
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Détails de l\'Échange',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Informations client
                    _buildInfoRow('Client:', userName, ttf),
                    _buildInfoRow('Email:', userEmail, ttf),
                    _buildInfoRow(
                      'Points échangés:',
                      '$pointsExchanged points',
                      ttf,
                    ),
                    _buildInfoRow('Date d\'échange:', exchangeDate, ttf),
                    _buildInfoRow('Vendeur:', vendorName, ttf),
                    _buildInfoRow('Localisation:', vendorLocation, ttf),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Conditions et notes
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.yellow50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColors.yellow200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Conditions et Notes',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '• Cet échange est définitif et ne peut être annulé\n'
                      '• Les points échangés ne peuvent être récupérés\n'
                      '• Ce document sert de preuve d\'échange\n'
                      '• Conservez ce document pour vos archives',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Pied de page
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Merci de votre fidélité !',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Continuez à scanner nos QR codes pour gagner plus de points !',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature du Vendeur:',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature du Client:',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Sauvegarder le PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/confirmation_echange_$exchangeCode.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Construire une ligne d'information
  pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Partager le PDF généré
  Future<void> sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: 'Confirmation d\'échange Aya Huile');
    } catch (e) {
      print('Erreur lors du partage du PDF: $e');
    }
  }

  /// Générer un PDF de rapport d'activité utilisateur
  Future<File> generateUserActivityReport({
    required String userName,
    required String userEmail,
    required Map<String, dynamic> userStats,
    required List<Map<String, dynamic>> recentActivities,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Text(
                  'Rapport d\'Activité - $userName',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // Statistiques utilisateur
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Statistiques Générales',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    _buildInfoRow(
                      'Points disponibles:',
                      '${userStats['availablePoints'] ?? 0}',
                      ttf,
                    ),
                    _buildInfoRow(
                      'Points échangés:',
                      '${userStats['exchangedPoints'] ?? 0}',
                      ttf,
                    ),
                    _buildInfoRow(
                      'QR codes collectés:',
                      '${userStats['collectedQRCodes'] ?? 0}',
                      ttf,
                    ),
                    _buildInfoRow(
                      'Jeux joués:',
                      '${userStats['totalGames'] ?? 0}',
                      ttf,
                    ),
                    _buildInfoRow(
                      'Taux de réussite:',
                      '${userStats['winRate']?.toStringAsFixed(1) ?? 0}%',
                      ttf,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Activités récentes
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Activités Récentes',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    ...recentActivities
                        .take(10)
                        .map(
                          (activity) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            child: pw.Text(
                              '• ${activity['description']} - ${activity['date']}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/rapport_activite_$userName.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
