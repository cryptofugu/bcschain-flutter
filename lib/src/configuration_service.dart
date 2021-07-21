import 'package:shared_preferences/shared_preferences.dart';

abstract class IConfigurationService {
  Future<void> setBCSMnemonic(String? value);
  Future<void> bcsWalletSetupDone(bool value);
  Future<void> setBCSWIF(String? value);
  Future<void> setBCSPIN(String? value);
  Future<void> setBCSFingerprint(bool value);
  String? getBCSMnemonic();
  String? getBCSWIF();
  String? getBCSPIN();
  bool getBCSFingerprint();
  bool didSetupBCSWallet();
}

class ConfigurationService implements IConfigurationService {
  const ConfigurationService(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> setBCSMnemonic(String? value) async {
    await _preferences.setString('mnemonic', value ?? '');
  }

  @override
  Future<void> setBCSWIF(String? value) async {
    await _preferences.setString('WIF', value ?? '');
  }

  @override
  Future<void> setBCSPIN(String? value) async {
    await _preferences.setString('PIN', value ?? '');
  }

  @override
  Future<void> setBCSFingerprint(bool value) async {
    await _preferences.setBool('fingerprint', value);
  }

  @override
  Future<void> bcsWalletSetupDone(bool value) async {
    await _preferences.setBool('didSetupWallet', value);
  }

  // gets
  @override
  String? getBCSMnemonic() {
    return _preferences.getString('mnemonic');
  }

  @override
  String? getBCSWIF() {
    return _preferences.getString('WIF');
  }

  @override
  String? getBCSPIN() {
    return _preferences.getString('PIN');
  }

  @override
  bool getBCSFingerprint() {
    return _preferences.getBool('fingerprint') ?? false;
  }

  @override
  bool didSetupBCSWallet() {
    return _preferences.getBool('didSetupWallet') ?? false;
  }
}
