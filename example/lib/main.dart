import 'package:flutter/material.dart';
import 'package:network_pro/network_pro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Pro Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NetworkInfoScreen(),
    );
  }
}

class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({Key? key}) : super(key: key);

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  DnsInfo? _dnsInfo;
  VpnInfo? _vpnInfo;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _listenToVpnStatus();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dnsInfo = await NetworkPro.getDnsInfo();
      final vpnInfo = await NetworkPro.getVpnInfo();
      
      setState(() {
        _dnsInfo = dnsInfo;
        _vpnInfo = vpnInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Pro Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNetworkInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNetworkInfo,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        title: 'DNS Information',
                        icon: Icons.dns,
                        child: _buildDnsInfo(),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'VPN Information',
                        icon: Icons.vpn_key,
                        child: _buildVpnInfo(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDnsInfo() {
    if (_dnsInfo == null) {
      return const Text('No DNS information available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('DNS Servers', _dnsInfo!.dnsServers.join(', ')),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Search Domains',
          _dnsInfo!.searchDomains.isEmpty
              ? 'None'
              : _dnsInfo!.searchDomains.join(', '),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'DNS over HTTPS',
          _dnsInfo!.isDnsOverHttpsEnabled ? 'Enabled' : 'Disabled',
          valueColor: _dnsInfo!.isDnsOverHttpsEnabled ? Colors.green : null,
        ),
        if (_dnsInfo!.dnsOverHttpsServer != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('DoH Server', _dnsInfo!.dnsOverHttpsServer!),
        ],
        if (_dnsInfo!.additionalInfo != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            'Additional Info',
            _dnsInfo!.additionalInfo.toString(),
            isMonospace: true,
          ),
        ],
      ],
    );
  }

  Widget _buildVpnInfo() {
    if (_vpnInfo == null) {
      return const Text('No VPN information available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'VPN Status',
          _vpnInfo!.isVpnConnected ? 'Connected' : 'Disconnected',
          valueColor: _vpnInfo!.isVpnConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Connection State', _vpnInfo!.status.toString()),
        if (_vpnInfo!.vpnProvider != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('Provider', _vpnInfo!.vpnProvider!),
        ],
        if (_vpnInfo!.serverAddress != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('Server Address', _vpnInfo!.serverAddress!),
        ],
        if (_vpnInfo!.protocol != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('Protocol', _vpnInfo!.protocol!),
        ],
        if (_vpnInfo!.connectionStartTime != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            'Connected Since',
            _vpnInfo!.connectionStartTime!.toLocal().toString(),
          ),
        ],
        if (_vpnInfo!.additionalInfo != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            'Additional Info',
            _vpnInfo!.additionalInfo.toString(),
            isMonospace: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontFamily: isMonospace ? 'monospace' : null,
              fontSize: isMonospace ? 12 : null,
            ),
          ),
        ),
      ],
    );
  }
}

