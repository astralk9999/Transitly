import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../../core/utils/app_logger.dart';

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
/// Protocol reverse-engineered from the saldotarjetas Android app. Sector
/// keys default to the values required by that card format; override at
/// build time with `--dart-define=NFC_KEY_SECTOR0=<hex>` and
/// `--dart-define=NFC_KEY_SECTOR9=<hex>` for environments where those
/// defaults are inappropriate or legally sensitive.
class NfcCardService {
  static const _tag = 'NfcCardService';

  // Default Mifare Classic sector keys (hex, 6 bytes each).
  // Overridable via --dart-define at build time. See class docstring.
  static const _defaultKeySector9Hex = '99100225D83B';
  static const _defaultKeySector0Hex = '1848A8D1E4C5';

  static final _keySector9 = _parseHexKey(
    const String.fromEnvironment(
      'NFC_KEY_SECTOR9',
      defaultValue: _defaultKeySector9Hex,
    ),
  );
  static final _keySector0 = _parseHexKey(
    const String.fromEnvironment(
      'NFC_KEY_SECTOR0',
      defaultValue: _defaultKeySector0Hex,
    ),
  );

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
    } catch (e) {
      AppLogger.warn(_tag, 'isAvailable() failed', e);
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
            onError(classify(e));
          } finally {
            try {
              await NfcManager.instance.stopSession();
            } catch (e) {
              AppLogger.warn(_tag, 'stopSession (finally) failed', e);
            }
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
    } catch (e) {
      AppLogger.warn(_tag, 'stopScan failed', e);
    }
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
    final balance = parseBalance(balanceBytes);
    final cardId = bytesToHex(idBytes);

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
      } catch (e) {
        AppLogger.warn(_tag, 'auth sector=$sectorIndex attempt=$attempt', e);
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
    } catch (e) {
      AppLogger.warn(_tag, 'readBlock $blockIndex failed', e);
      return null;
    }
  }

  /// Classify an arbitrary exception thrown from the NFC stack.
  ///
  /// Exposed (not private) so unit tests can exercise the heuristic without
  /// needing a real [NfcTag]. Keep behavior backwards-compatible with prior
  /// inline classification.
  @visibleForTesting
  static NfcCardException classify(Object e) {
    final text = e.toString();
    final isTagLost = text.contains('TagLost') || text.contains('tag was lost');
    if (isTagLost) {
      return const NfcCardException(NfcCardError.tagLost);
    }
    return NfcCardException(NfcCardError.unknown, text);
  }

  /// Parse balance from raw bytes.
  ///
  /// Algorithm from decompiled z21.t():
  /// 1. Convert first 2 bytes to hex
  /// 2. Swap byte pairs (little-endian to big-endian)
  /// 3. Parse as int, divide by 2, divide by 100
  @visibleForTesting
  static double parseBalance(Uint8List bytes) {
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
  @visibleForTesting
  static String bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
  }

  /// Parse a hex string (e.g. "99100225D83B") into a 6-byte key.
  ///
  /// Throws [FormatException] if the string is not exactly 12 hex chars.
  static Uint8List _parseHexKey(String hex) {
    if (hex.length != 12) {
      throw FormatException('NFC key must be 12 hex chars, got ${hex.length}');
    }
    final out = Uint8List(6);
    for (int i = 0; i < 6; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
