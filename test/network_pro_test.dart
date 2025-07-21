import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:network_pro/network_pro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('network_pro');

  setUp(() {
    // Set up method channel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getDnsInfo':
          return <String, dynamic>{
            'dnsServers': ['8.8.8.8', '8.8.4.4'],
            'searchDomains': ['example.com'],
            'isDnsOverHttpsEnabled': false,
            'dnsOverHttpsServer': null,
            'additionalInfo': {'test': true},
          };
        case 'getVpnInfo':
          return <String, dynamic>{
            'isVpnConnected': false,
            'status': 'disconnected',
            'vpnProvider': null,
            'serverAddress': null,
            'protocol': null,
            'connectionStartTime': null,
            'additionalInfo': {'test': true},
          };
        case 'isVpnConnected':
          return false;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NetworkPro Tests', () {
    test('getDnsInfo returns DNS information', () async {
      final dnsInfo = await NetworkPro.getDnsInfo();
      
      expect(dnsInfo.dnsServers, isNotEmpty);
      expect(dnsInfo.dnsServers, contains('8.8.8.8'));
      expect(dnsInfo.dnsServers, contains('8.8.4.4'));
      expect(dnsInfo.searchDomains, contains('example.com'));
      expect(dnsInfo.isDnsOverHttpsEnabled, isFalse);
      expect(dnsInfo.dnsOverHttpsServer, isNull);
      expect(dnsInfo.additionalInfo, isNotNull);
    });

    test('getVpnInfo returns VPN information', () async {
      final vpnInfo = await NetworkPro.getVpnInfo();
      
      expect(vpnInfo.isVpnConnected, isFalse);
      expect(vpnInfo.status, equals(VpnConnectionStatus.disconnected));
      expect(vpnInfo.vpnProvider, isNull);
      expect(vpnInfo.serverAddress, isNull);
      expect(vpnInfo.protocol, isNull);
      expect(vpnInfo.connectionStartTime, isNull);
      expect(vpnInfo.additionalInfo, isNotNull);
    });

    test('isVpnConnected returns connection status', () async {
      final isConnected = await NetworkPro.isVpnConnected();
      expect(isConnected, isFalse);
    });

    test('DnsInfo model serialization', () {
      final dnsInfo = DnsInfo(
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        searchDomains: ['cloudflare.com'],
        isDnsOverHttpsEnabled: true,
        dnsOverHttpsServer: 'cloudflare-dns.com',
        additionalInfo: {'provider': 'Cloudflare'},
      );

      final json = dnsInfo.toJson();
      final reconstructed = DnsInfo.fromJson(json);

      expect(reconstructed.dnsServers, equals(dnsInfo.dnsServers));
      expect(reconstructed.searchDomains, equals(dnsInfo.searchDomains));
      expect(reconstructed.isDnsOverHttpsEnabled, equals(dnsInfo.isDnsOverHttpsEnabled));
      expect(reconstructed.dnsOverHttpsServer, equals(dnsInfo.dnsOverHttpsServer));
    });

    test('VpnInfo model serialization', () {
      final vpnInfo = VpnInfo(
        isVpnConnected: true,
        status: VpnConnectionStatus.connected,
        vpnProvider: 'TestVPN',
        serverAddress: '10.0.0.1',
        protocol: 'OpenVPN',
        connectionStartTime: DateTime.now(),
        additionalInfo: {'version': '2.0'},
      );

      final json = vpnInfo.toJson();
      final reconstructed = VpnInfo.fromJson(json);

      expect(reconstructed.isVpnConnected, equals(vpnInfo.isVpnConnected));
      expect(reconstructed.status, equals(vpnInfo.status));
      expect(reconstructed.vpnProvider, equals(vpnInfo.vpnProvider));
      expect(reconstructed.serverAddress, equals(vpnInfo.serverAddress));
      expect(reconstructed.protocol, equals(vpnInfo.protocol));
    });

    test('VpnConnectionStatus enum conversion', () {
      expect(VpnConnectionStatus.fromString('connected'), equals(VpnConnectionStatus.connected));
      expect(VpnConnectionStatus.fromString('connecting'), equals(VpnConnectionStatus.connecting));
      expect(VpnConnectionStatus.fromString('disconnected'), equals(VpnConnectionStatus.disconnected));
      expect(VpnConnectionStatus.fromString('disconnecting'), equals(VpnConnectionStatus.disconnecting));
      expect(VpnConnectionStatus.fromString('invalid'), equals(VpnConnectionStatus.unknown));
    });
  });
}
