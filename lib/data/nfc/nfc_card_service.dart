import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

/// Result of a successful NFC card read.
class NfcCardResult {
  const NfcCardResult({
    required this.cardId,
    required this.balance,
    required this.scannedAt,
  });

  final String cardId;
  final double balance;
  final DateTime scannedAt;
}

/// Error types for NFC card reading.
enum NfcCardError {
  unsupported,
  notMifareClassic,
  authFailed,
  readFailed,
  tagLost,
  unknown,
}

class NfcCardException implements Exception {
  const NfcCardException(this.error, [this.message]);

  final NfcCardError error;
  final String? message;

  String get displayMessage {
    switch (error) {
      case NfcCardError.unsupported:
        return 'NFC no disponible en este dispositivo';
      case NfcCardError.notMifareClassic:
        return 'Esta tarjeta no es compatible';
      case NfcCardError.authFailed:
        return 'No se pudo autenticar la tarjeta';
      case NfcCardError.readFailed:
        return 'Error al leer la tarjeta';
      case NfcCardError.tagLost:
        return 'Tarjeta retirada demasiado pronto';
      case NfcCardError.unknown:
        return message ?? 'Error desconocido';
    }
  }
}

/// Service for reading Consorcio de Transportes de Andalucia transit cards
/// via NFC Mifare Classic protocol.
///
/// Protocol reverse-engineered from the saldotarjetas Android app.
class NfcCardService {
  // Authentication keys extracted from decompiled APK
  static final _keySector9 =
      Uint8List.fromList([0x99, 0x10, 0x02, 0x25, 0xD8, 0x3B]);
  static final _keySector0 =
      Uint8List.fromList([0x18, 0x48, 0xA8, 0xD1, 0xE4, 0xC5]);

  // Block addresses
  static const _balanceBlock = 37; // Sector 9, block 1
  static const _idBlock = 0; // Sector 0, block 0

  // Retry config
  static const _maxRetries = 3;
  static const _initialBackoffMs = 80;
  static const _backoffMultiplier = 1.6;
  static const _maxBackoffMs = 400;

  /// Check if NFC hardware is available on this device.
  Future<bool> isNfcAvailable() async {
    if (kIsWeb) return false;
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Start an NFC scan session. Calls [onResult] on success or
  /// [onError] on failure.
  Future<void> startScan({
    required void Function(NfcCardResult result) onResult,
    required void Function(NfcCardException error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final result = await _readCard(tag);
            onResult(result);
          } on NfcCardException catch (e) {
            onError(e);
          } catch (e) {
            final isTagLost = e.toString().contains('TagLost') ||
                e.toString().contains('tag was lost');
            if (isTagLost) {
              onError(const NfcCardException(NfcCardError.tagLost));
            } else {
              onError(NfcCardException(NfcCardError.unknown, e.toString()));
            }
          } finally {
            try {
              await NfcManager.instance.stopSession();
            } catch (_) {}
          }
        },
        onError: (NfcError error) async {
          onError(NfcCardException(NfcCardError.unknown, error.message));
        },
      );
    } catch (e) {
      onError(NfcCardException(NfcCardError.unknown, e.toString()));
    }
  }

  /// Stop any active NFC scan session.
  Future<void> stopScan() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Read card data from a discovered NFC tag.
  Future<NfcCardResult> _readCard(NfcTag tag) async {
    final mifare = MifareClassic.from(tag);
    if (mifare == null) {
      throw const NfcCardException(NfcCardError.notMifareClassic);
    }

    // 1. Authenticate and read balance (sector 9, block 37)
    final authSector9 = await _authenticateWithRetry(
      mifare,
      sectorIndex: 9,
      key: _keySector9,
    );
    if (!authSector9) {
      throw const NfcCardException(NfcCardError.authFailed);
    }

    final balanceBytes = await _readBlockSafe(mifare, _balanceBlock);
    if (balanceBytes == null || balanceBytes.length < 2) {
      throw const NfcCardException(NfcCardError.readFailed);
    }

    // 2. Authenticate and read card ID (sector 0, block 0)
    final authSector0 = await _authenticateWithRetry(
      mifare,
      sectorIndex: 0,
      key: _keySector0,
    );
    if (!authSector0) {
      throw const NfcCardException(NfcCardError.authFailed);
    }

    final idBytes = await _readBlockSafe(mifare, _idBlock);
    if (idBytes == null) {
      throw const NfcCardException(NfcCardError.readFailed);
    }

    // 3. Parse results
    final balance = _parseBalance(balanceBytes);
    final cardId = _bytesToHex(idBytes);

    return NfcCardResult(
      cardId: cardId,
      balance: balance,
      scannedAt: DateTime.now(),
    );
  }

  /// Authenticate a sector with exponential backoff retry.
  Future<bool> _authenticateWithRetry(
    MifareClassic mifare, {
    required int sectorIndex,
    required Uint8List key,
  }) async {
    double backoffMs = _initialBackoffMs.toDouble();

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final ok = await mifare.authenticateSectorWithKeyA(
          sectorIndex: sectorIndex,
          key: key,
        );
        if (ok) return true;
      } catch (_) {
        // Tag communication error, retry
      }

      if (attempt < _maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: backoffMs.toInt()));
        backoffMs = (backoffMs * _backoffMultiplier).clamp(0.0, _maxBackoffMs.toDouble());
      }
    }

    return false;
  }

  /// Read a block, returning null on failure instead of throwing.
  Future<Uint8List?> _readBlockSafe(
      MifareClassic mifare, int blockIndex) async {
    try {
      return await mifare.readBlock(blockIndex: blockIndex);
    } catch (_) {
      return null;
    }
  }

  /// Parse balance from raw bytes.
  ///
  /// Algorithm from decompiled z21.t():
  /// 1. Convert first 2 bytes to hex
  /// 2. Swap byte pairs (little-endian to big-endian)
  /// 3. Parse as int, divide by 2, divide by 100
  static double _parseBalance(Uint8List bytes) {
    final hex = bytes
        .take(2)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final swapped = hex.substring(2, 4) + hex.substring(0, 2);
    final raw = int.parse(swapped, radix: 16);
    return raw / 2.0 / 100.0;
  }

  /// Convert byte array to uppercase hex string.
  ///
  /// Algorithm from decompiled z21.u().
  static String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
  }
}
