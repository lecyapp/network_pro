library network_pro;

export 'models/dns_info.dart';
export 'models/vpn_info.dart';

import 'src/network_pro_platform_interface.dart';
import 'models/dns_info.dart';
import 'models/vpn_info.dart';

/// Main class for NetworkPro plugin
class NetworkPro {
  /// Get DNS information from the device
  ///
  /// Returns a [DnsInfo] object containing:
  /// - DNS server addresses
  /// - Search domains
  /// - DNS over HTTPS status
  /// - Additional DNS configuration
  static Future<DnsInfo> getDnsInfo() {
    return NetworkProPlatform.instance.getDnsInfo();
  }

  /// Get VPN information from the device
  ///
  /// Returns a [VpnInfo] object containing:
  /// - VPN connection status
  /// - VPN provider information
  /// - Server address
  /// - Protocol information
  /// - Connection time
  static Future<VpnInfo> getVpnInfo() {
    return NetworkProPlatform.instance.getVpnInfo();
  }

  /// Check if VPN is currently connected
  ///
  /// Returns true if VPN is connected, false otherwise
  static Future<bool> isVpnConnected() {
    return NetworkProPlatform.instance.isVpnConnected();
  }

  /// Stream of VPN connection status changes
  ///
  /// Emits [VpnConnectionStatus] whenever the VPN connection state changes
  static Stream<VpnConnectionStatus> get vpnStatusStream {
    return NetworkProPlatform.instance.vpnStatusStream;
  }
}
