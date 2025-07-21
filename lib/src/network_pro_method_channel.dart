import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/dns_info.dart';
import '../models/vpn_info.dart';
import 'network_pro_platform_interface.dart';

/// An implementation of [NetworkProPlatform] that uses method channels.
class MethodChannelNetworkPro extends NetworkProPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('network_pro');

  /// The event channel for VPN status updates
  @visibleForTesting
  final eventChannel = const EventChannel('network_pro/vpn_status');

  @override
  Future<DnsInfo> getDnsInfo() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getDnsInfo');
      if (result == null) {
        throw PlatformException(
          code: 'NULL_RESULT',
          message: 'Failed to get DNS information',
        );
      }
      return DnsInfo.fromJson(result.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw Exception('Failed to get DNS info: ${e.message}');
    }
  }

  @override
  Future<VpnInfo> getVpnInfo() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('getVpnInfo');
      if (result == null) {
        throw PlatformException(
          code: 'NULL_RESULT',
          message: 'Failed to get VPN information',
        );
      }
      return VpnInfo.fromJson(result.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw Exception('Failed to get VPN info: ${e.message}');
    }
  }

  @override
  Future<bool> isVpnConnected() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isVpnConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check VPN status: ${e.message}');
    }
  }

  @override
  Stream<VpnConnectionStatus> get vpnStatusStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      if (event is String) {
        return VpnConnectionStatus.fromString(event);
      }
      return VpnConnectionStatus.unknown;
    });
  }
}

