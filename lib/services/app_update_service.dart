import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/django_config.dart';
import '../constants/app_config.dart';

class AppVersionInfo {
  final int minVersionCode;
  final String latestVersion;
  final bool forceUpdate;
  final bool immediateUpdate;
  final String message;
  final String storeUrl;

  AppVersionInfo({
    required this.minVersionCode,
    required this.latestVersion,
    required this.forceUpdate,
    required this.immediateUpdate,
    required this.message,
    required this.storeUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      minVersionCode: (json['min_version_code'] as num?)?.toInt() ?? 0,
      latestVersion: json['latest_version']?.toString() ?? '',
      forceUpdate: json['force_update'] == true,
      immediateUpdate: json['immediate_update'] != false,
      message: json['message']?.toString() ??
          'Une nouvelle version est disponible.',
      storeUrl: json['store_url']?.toString() ?? AppConfig.playStoreUrl,
    );
  }
}

class AppUpdateService {
  Future<AppVersionInfo?> fetchVersionInfo() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await http.get(
        Uri.parse('${DjangoConfig.appVersionEndpoint}?platform=$platform'),
        headers: DjangoConfig.defaultHeaders,
      ).timeout(Duration(seconds: DjangoConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AppVersionInfo.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppUpdateService: $e');
      }
    }
    return null;
  }

  Future<int> getCurrentVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  Future<void> openStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Vérifie mise à jour forcée + In-App Update Android.
  /// Retourne true si l'app doit rester bloquée (MAJ obligatoire).
  Future<bool> handleStartupUpdate(BuildContext context) async {
    if (kIsWeb) return false;

    final versionInfo = await fetchVersionInfo();
    final currentCode = await getCurrentVersionCode();

    if (versionInfo != null &&
        versionInfo.forceUpdate &&
        currentCode < versionInfo.minVersionCode) {
      if (context.mounted) {
        await _showForceUpdateDialog(context, versionInfo);
      }
      return true;
    }

    if (Platform.isAndroid && !kDebugMode) {
      await _tryInAppUpdate(versionInfo);
    } else if (versionInfo != null &&
        currentCode < versionInfo.minVersionCode &&
        context.mounted) {
      await _showOptionalUpdateDialog(context, versionInfo);
    }

    return false;
  }

  Future<void> _tryInAppUpdate(AppVersionInfo? versionInfo) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability !=
          UpdateAvailability.updateAvailable) {
        return;
      }

      final immediate = versionInfo?.immediateUpdate ?? true;
      if (immediate && updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('InAppUpdate: $e');
    }
  }

  Future<void> _showForceUpdateDialog(
    BuildContext context,
    AppVersionInfo info,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Mise à jour requise'),
          content: Text(
            info.message.isNotEmpty
                ? info.message
                : 'Veuillez mettre à jour Mon univers AYA (v${info.latestVersion}) pour continuer.',
          ),
          actions: [
            FilledButton(
              onPressed: () => openStore(info.storeUrl),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOptionalUpdateDialog(
    BuildContext context,
    AppVersionInfo info,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text(
          info.message.isNotEmpty
              ? info.message
              : 'La version ${info.latestVersion} est disponible sur le Play Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openStore(info.storeUrl);
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
