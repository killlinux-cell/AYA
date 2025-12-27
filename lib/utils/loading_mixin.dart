import 'package:flutter/material.dart';
import '../services/loading_service.dart';

/// Mixin pour faciliter l'utilisation du chargement dans les écrans
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  /// Afficher le chargement de navigation
  void showNavigationLoading({String? message}) {
    LoadingService.instance.showNavigationLoading(
      context: context,
      message: message,
    );
  }

  /// Afficher le chargement d'API
  void showApiLoading({String? message}) {
    LoadingService.instance.showApiLoading(context: context, message: message);
  }

  /// Masquer le chargement
  void hideLoading() {
    LoadingService.instance.hideLoading();
  }

  /// Exécuter une action avec chargement de navigation
  Future<R?> executeWithNavigationLoading<R>(
    Future<R> Function() action, {
    String? message,
  }) async {
    showNavigationLoading(message: message);
    try {
      final result = await action();
      return result;
    } finally {
      hideLoading();
    }
  }

  /// Exécuter une action avec chargement d'API
  Future<R?> executeWithApiLoading<R>(
    Future<R> Function() action, {
    String? message,
  }) async {
    showApiLoading(message: message);
    try {
      final result = await action();
      return result;
    } finally {
      hideLoading();
    }
  }

  /// Naviguer avec chargement
  Future<T?> navigateWithLoading<T extends Object?>(
    Widget destination, {
    String? message,
    bool replace = false,
  }) async {
    showNavigationLoading(message: message);

    await Future.delayed(const Duration(milliseconds: 500));

    hideLoading();

    if (replace) {
      return Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
    } else {
      return Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => destination));
    }
  }
}
