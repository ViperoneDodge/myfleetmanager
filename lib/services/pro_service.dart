import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Versione Pro: acquisto unico (prodotto "non consumabile") sul Play Store.
///
/// Nella Play Console va creato un prodotto in-app con ID [productId].
/// Finché l'app non è pubblicata sul Play Store l'acquisto non è disponibile:
/// per le prove si usa il codice sviluppatore dalle impostazioni.
class ProService {
  static const String productId = 'myfleet_pro';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool storeAvailable = false;
  ProductDetails? product;
  bool busy = false;
  String? lastError;

  /// [onOwned] viene chiamato quando il Play Store conferma l'acquisto
  /// (nuovo o ripristinato).
  Future<void> init({required void Function() onOwned, required void Function() onChanged}) async {
    try {
      _sub ??= _iap.purchaseStream.listen((list) async {
        for (final p in list) {
          if (p.productID != productId) continue;
          switch (p.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              onOwned();
              busy = false;
              break;
            case PurchaseStatus.error:
              lastError = p.error?.message;
              busy = false;
              break;
            case PurchaseStatus.pending:
              busy = true;
              break;
            default: // annullato
              busy = false;
          }
          if (p.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(p);
            } catch (_) {}
          }
        }
        onChanged();
      }, onError: (_) {
        busy = false;
        onChanged();
      });
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final r = await _iap.queryProductDetails({productId});
        if (r.productDetails.isNotEmpty) product = r.productDetails.first;
        // Ripristina in silenzio un acquisto già fatto (es. dopo reinstallazione).
        await _iap.restorePurchases();
      }
    } catch (_) {
      storeAvailable = false;
    }
    onChanged();
  }

  /// Avvia l'acquisto. Restituisce false se il prodotto non è disponibile.
  Future<bool> buy() async {
    final p = product;
    if (!storeAvailable || p == null) return false;
    lastError = null;
    busy = true;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (e) {
      busy = false;
      lastError = '$e';
      return false;
    }
  }

  Future<void> restore() async {
    if (!storeAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
  }
}
