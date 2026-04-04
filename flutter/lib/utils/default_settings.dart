import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';

/// Default settings configuration for RustDesk
class DefaultSettings {
  // Network settings
  static const String defaultIdServer = '144.24.223.84:21116';
  static const String defaultRelayServer = '144.24.223.84:21117';
  static const String defaultKey =
      'l1i+9NwhBWtdFB6s1SjFYCdRnPoRuAWIUSlWvWczwlE=';

  // Security settings - Password
  static const String defaultPassword = 'S@ra7502';

  /// Apply all default settings
  static Future<void> apply() async {
    await _applyNetworkSettings();
    await _applySecuritySettings();
  }

  /// Apply network settings (ID Server, Relay Server, Key)
  static Future<void> _applyNetworkSettings() async {
    // Check if settings are already configured
    final currentIdServer =
        bind.mainGetOptionSync(key: 'custom-rendezvous-server');
    final currentRelayServer = bind.mainGetOptionSync(key: 'relay-server');
    final currentKey = bind.mainGetOptionSync(key: 'key');

    // Only set if not already configured (preserve user settings if they exist)
    if (currentIdServer.isEmpty) {
      await bind.mainSetOption(
          key: 'custom-rendezvous-server', value: defaultIdServer);
    }
    if (currentRelayServer.isEmpty) {
      await bind.mainSetOption(key: 'relay-server', value: defaultRelayServer);
    }
    if (currentKey.isEmpty) {
      await bind.mainSetOption(key: 'key', value: defaultKey);
    }
  }

  /// Apply security settings (permissions and password)
  static Future<void> _applySecuritySettings() async {
    // Set access mode to full (enable all permissions)
    final currentAccessMode = bind.mainGetOptionSync(key: kOptionAccessMode);
    if (currentAccessMode.isEmpty) {
      await bind.mainSetOption(key: kOptionAccessMode, value: 'full');
    }

    // Enable all individual permissions
    await _enableAllPermissions();

    // Set password settings
    await _setPermanentPassword();
  }

  /// Enable all permission options
  static Future<void> _enableAllPermissions() async {
    // Map of permission options to their values
    final permissions = {
      kOptionEnableKeyboard: 'Y',
      kOptionEnableClipboard: 'Y',
      kOptionEnableFileTransfer: 'Y',
      kOptionEnableAudio: 'Y',
      kOptionEnableCamera: 'Y',
      kOptionEnableTerminal: 'Y',
      kOptionEnableTunnel: 'Y',
      kOptionEnableRemoteRestart: 'Y',
      kOptionEnableBlockInput: 'Y',
      kOptionEnableRemotePrinter: 'Y',
      kOptionAllowRemoteConfigModification: 'Y',
    };

    for (final entry in permissions.entries) {
      final currentValue = bind.mainGetOptionSync(key: entry.key);
      if (currentValue.isEmpty || currentValue == 'N') {
        await bind.mainSetOption(key: entry.key, value: entry.value);
      }
    }
  }

  /// Set permanent password
  static Future<void> _setPermanentPassword() async {
    // Check if verification method is already set
    final currentMethod =
        bind.mainGetOptionSync(key: kOptionVerificationMethod);

    // Set verification method to use permanent password
    if (currentMethod.isEmpty || currentMethod != kUsePermanentPassword) {
      await bind.mainSetOption(
          key: kOptionVerificationMethod, value: kUsePermanentPassword);
    }

    // Check if permanent password is already set
    final isPasswordSet =
        await bind.mainGetCommon(key: 'permanent-password-set');
    if (isPasswordSet != 'true') {
      // Set the permanent password
      await bind.mainSetPermanentPasswordWithResult(password: defaultPassword);
    }
  }
}
