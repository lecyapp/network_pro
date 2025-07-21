# Network Pro

A Flutter plugin for retrieving network information including DNS configuration and VPN connection status on iOS and Android devices.

## Features

- **DNS Information**
  - Get DNS server addresses
  - Retrieve search domains
  - Check DNS over HTTPS status
  - Access DNS configuration details

- **VPN Information**
  - Check VPN connection status
  - Get VPN provider information
  - Retrieve VPN server address
  - Monitor VPN protocol details
  - Real-time VPN status monitoring

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| Android  | API 16 (4.1)    |
| iOS      | 11.0            |

## Installation

Add `network_pro` to your `pubspec.yaml`:

```yaml
dependencies:
  network_pro: ^0.0.1
```

## Permissions

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

No additional permissions required. The plugin uses system APIs that don't require special permissions.

## Usage

### Import the package

```dart
import 'package:network_pro/network_pro.dart';
```

### Get DNS Information

```dart
try {
  final dnsInfo = await NetworkPro.getDnsInfo();

  print('DNS Servers: ${dnsInfo.dnsServers}');
  print('Search Domains: ${dnsInfo.searchDomains}');
  print('DNS over HTTPS enabled: ${dnsInfo.isDnsOverHttpsEnabled}');

  if (dnsInfo.isDnsOverHttpsEnabled) {
    print('DoH Server: ${dnsInfo.dnsOverHttpsServer}');
  }
} catch (e) {
  print('Failed to get DNS info: $e');
}
```

### Get VPN Information

```dart
try {
  final vpnInfo = await NetworkPro.getVpnInfo();

  print('VPN Connected: ${vpnInfo.isVpnConnected}');
  print('VPN Status: ${vpnInfo.status}');

  if (vpnInfo.isVpnConnected) {
    print('VPN Provider: ${vpnInfo.vpnProvider}');
    print('Server Address: ${vpnInfo.serverAddress}');
    print('Protocol: ${vpnInfo.protocol}');
  }
} catch (e) {
  print('Failed to get VPN info: $e');
}
```

### Check VPN Connection Status

```dart
final isConnected = await NetworkPro.isVpnConnected();
print('VPN is ${isConnected ? "connected" : "not connected"}');
```

### Monitor VPN Status Changes

```dart
NetworkPro.vpnStatusStream.listen((status) {
  print('VPN Status changed to: $status');

  switch (status) {
    case VpnConnectionStatus.connected:
      print('VPN is now connected');
      break;
    case VpnConnectionStatus.connecting:
      print('VPN is connecting...');
      break;
    case VpnConnectionStatus.disconnected:
      print('VPN is disconnected');
      break;
    case VpnConnectionStatus.disconnecting:
      print('VPN is disconnecting...');
      break;
    case VpnConnectionStatus.unknown:
      print('VPN status is unknown');
      break;
  }
});
```

## Models

### DnsInfo

```dart
class DnsInfo {
  final List<String> dnsServers;
  final List<String> searchDomains;
  final bool isDnsOverHttpsEnabled;
  final String? dnsOverHttpsServer;
  final Map<String, dynamic>? additionalInfo;
}
```

### VpnInfo

```dart
class VpnInfo {
  final bool isVpnConnected;
  final VpnConnectionStatus status;
  final String? vpnProvider;
  final String? serverAddress;
  final String? protocol;
  final DateTime? connectionStartTime;
  final Map<String, dynamic>? additionalInfo;
}
```

### VpnConnectionStatus

```dart
enum VpnConnectionStatus {
  connected,
  connecting,
  disconnected,
  disconnecting,
  unknown
}
```

## Example App

```dart
import 'package:flutter/material.dart';
import 'package:network_pro/network_pro.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DnsInfo? _dnsInfo;
  VpnInfo? _vpnInfo;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _listenToVpnStatus();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final dnsInfo = await NetworkPro.getDnsInfo();
      final vpnInfo = await NetworkPro.getVpnInfo();

      setState(() {
        _dnsInfo = dnsInfo;
        _vpnInfo = vpnInfo;
      });
    } catch (e) {
      print('Error loading network info: $e');
    }
  }

  void _listenToVpnStatus() {
    NetworkPro.vpnStatusStream.listen((status) {
      setState(() {
        if (_vpnInfo != null) {
          _vpnInfo = VpnInfo(
            isVpnConnected: status == VpnConnectionStatus.connected,
            status: status,
            vpnProvider: _vpnInfo!.vpnProvider,
            serverAddress: _vpnInfo!.serverAddress,
            protocol: _vpnInfo!.protocol,
            connectionStartTime: _vpnInfo!.connectionStartTime,
            additionalInfo: _vpnInfo!.additionalInfo,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Network Pro Example'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DNS Information', style: Theme.of(context).textTheme.headline6),
              if (_dnsInfo != null) ...[
                Text('DNS Servers: ${_dnsInfo!.dnsServers.join(", ")}'),
                Text('Search Domains: ${_dnsInfo!.searchDomains.join(", ")}'),
                Text('DNS over HTTPS: ${_dnsInfo!.isDnsOverHttpsEnabled}'),
              ],
              SizedBox(height: 20),
              Text('VPN Information', style: Theme.of(context).textTheme.headline6),
              if (_vpnInfo != null) ...[
                Text('VPN Connected: ${_vpnInfo!.isVpnConnected}'),
                Text('Status: ${_vpnInfo!.status}'),
                if (_vpnInfo!.vpnProvider != null)
                  Text('Provider: ${_vpnInfo!.vpnProvider}'),
                if (_vpnInfo!.serverAddress != null)
                  Text('Server: ${_vpnInfo!.serverAddress}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

## Platform-Specific Implementation Details

### Android

- Uses `ConnectivityManager` and `LinkProperties` for network information
- Requires Android M (API 23) or higher for full functionality
- Falls back to `SystemProperties` for DNS on older Android versions
- VPN detection uses `NetworkCapabilities.TRANSPORT_VPN`

### iOS

- Uses `SystemConfiguration` framework for DNS information
- Uses `NetworkExtension` framework for VPN status
- Monitors network interfaces (utun, ipsec, ppp) for VPN detection
- Supports real-time VPN status monitoring via `NEVPNStatusDidChange`

## Limitations

- DNS over HTTPS detection is limited on both platforms
- VPN provider identification may not always be accurate
- Some VPN protocols may not be detected on older OS versions
- Connection start time is not available on Android

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
