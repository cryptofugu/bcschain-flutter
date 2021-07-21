import 'package:bitcoin_flutter/bitcoin_flutter.dart';

final bcsNetwork = NetworkType(
  messagePrefix: '\x18BCS Signed Message:\n',
  bech32: 'bc',
  bip32: new Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
  pubKeyHash: 0x19,
  scriptHash: 0x32,
  wif: 0x80
);

const BCS_DECIMALS = 1e8;