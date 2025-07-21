/// Model class for DNS information
class DnsInfo {
  /// List of DNS server addresses
  final List<String> dnsServers;
  
  /// DNS search domains
  final List<String> searchDomains;
  
  /// Whether DNS over HTTPS is enabled
  final bool isDnsOverHttpsEnabled;
  
  /// DNS over HTTPS server URL if enabled
  final String? dnsOverHttpsServer;
  
  /// Additional DNS configuration details
  final Map<String, dynamic>? additionalInfo;

  DnsInfo({
    required this.dnsServers,
    required this.searchDomains,
    required this.isDnsOverHttpsEnabled,
    this.dnsOverHttpsServer,
    this.additionalInfo,
  });

  /// Create DnsInfo from JSON
  factory DnsInfo.fromJson(Map<String, dynamic> json) {
    return DnsInfo(
      dnsServers: List<String>.from(json['dnsServers'] ?? []),
      searchDomains: List<String>.from(json['searchDomains'] ?? []),
      isDnsOverHttpsEnabled: json['isDnsOverHttpsEnabled'] ?? false,
      dnsOverHttpsServer: json['dnsOverHttpsServer'],
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dnsServers': dnsServers,
      'searchDomains': searchDomains,
      'isDnsOverHttpsEnabled': isDnsOverHttpsEnabled,
      'dnsOverHttpsServer': dnsOverHttpsServer,
      'additionalInfo': additionalInfo,
    };
  }

  @override
  String toString() {
    return 'DnsInfo(dnsServers: $dnsServers, searchDomains: $searchDomains, '
        'isDnsOverHttpsEnabled: $isDnsOverHttpsEnabled, dnsOverHttpsServer: $dnsOverHttpsServer)';
  }
}

