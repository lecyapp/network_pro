/// Model class for VPN information
class VpnInfo {
  /// Whether VPN is currently connected
  final bool isVpnConnected;
  
  /// VPN connection status
  final VpnConnectionStatus status;
  
  /// VPN provider name if available
  final String? vpnProvider;
  
  /// VPN server address if available
  final String? serverAddress;
  
  /// VPN protocol being used
  final String? protocol;
  
  /// Connection start time if connected
  final DateTime? connectionStartTime;
  
  /// Additional VPN configuration details
  final Map<String, dynamic>? additionalInfo;

  VpnInfo({
    required this.isVpnConnected,
    required this.status,
    this.vpnProvider,
    this.serverAddress,
    this.protocol,
    this.connectionStartTime,
    this.additionalInfo,
  });

  /// Create VpnInfo from JSON
  factory VpnInfo.fromJson(Map<String, dynamic> json) {
    return VpnInfo(
      isVpnConnected: json['isVpnConnected'] ?? false,
      status: VpnConnectionStatus.fromString(json['status'] ?? 'disconnected'),
      vpnProvider: json['vpnProvider'],
      serverAddress: json['serverAddress'],
      protocol: json['protocol'],
      connectionStartTime: json['connectionStartTime'] != null
          ? DateTime.parse(json['connectionStartTime'])
          : null,
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isVpnConnected': isVpnConnected,
      'status': status.toString(),
      'vpnProvider': vpnProvider,
      'serverAddress': serverAddress,
      'protocol': protocol,
      'connectionStartTime': connectionStartTime?.toIso8601String(),
      'additionalInfo': additionalInfo,
    };
  }

  @override
  String toString() {
    return 'VpnInfo(isVpnConnected: $isVpnConnected, status: $status, '
        'vpnProvider: $vpnProvider, serverAddress: $serverAddress, protocol: $protocol)';
  }
}

/// Enum for VPN connection status
enum VpnConnectionStatus {
  connected('connected'),
  connecting('connecting'),
  disconnected('disconnected'),
  disconnecting('disconnecting'),
  unknown('unknown');

  final String value;
  const VpnConnectionStatus(this.value);

  static VpnConnectionStatus fromString(String status) {
    return VpnConnectionStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => VpnConnectionStatus.unknown,
    );
  }

  @override
  String toString() => value;
}

