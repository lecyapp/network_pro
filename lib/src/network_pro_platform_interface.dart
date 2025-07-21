import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../models/dns_info.dart';
import '../models/vpn_info.dart';
import 'network_pro_method_channel.dart';

abstract class NetworkProPlatform extends PlatformInterface {
  /// Constructs a NetworkProPlatform.
  NetworkProPlatform() : super(token: _token);

  static final Object _token = Object();

  static NetworkProPlatform _instance = MethodChannelNetworkPro();

  /// The default instance of [NetworkProPlatform] to use.
  ///
  /// Defaults to [MethodChannelNetworkPro].
  static NetworkProPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NetworkProPlatform] when
  /// they register themselves.
  static set instance(NetworkProPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Get DNS information from the device
  Future<DnsInfo> getDnsInfo() {
    throw UnimplementedError('getDnsInfo() has not been implemented.');
  }

  /// Get VPN information from the device
  Future<VpnInfo> getVpnInfo() {
    throw UnimplementedError('getVpnInfo() has not been implemented.');
  }

  /// Check if VPN is connected
  Future<bool> isVpnConnected() {
    throw UnimplementedError('isVpnConnected() has not been implemented.');
  }

  /// Stream of VPN connection status changes
  Stream<VpnConnectionStatus> get vpnStatusStream {
    throw UnimplementedError('vpnStatusStream has not been implemented.');
  }
}

