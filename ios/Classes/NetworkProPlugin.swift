import Flutter
import UIKit
import SystemConfiguration
import Network
import NetworkExtension

public class NetworkProPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var vpnStatusObserver: NSObjectProtocol?
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network_pro.monitor")
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "network_pro", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "network_pro/vpn_status", binaryMessenger: registrar.messenger())
        
        let instance = NetworkProPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDnsInfo":
            result(getDnsInfo())
        case "getVpnInfo":
            result(getVpnInfo())
        case "isVpnConnected":
            result(isVpnConnected())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getDnsInfo() -> [String: Any?] {
        var dnsServers: [String] = []
        var searchDomains: [String] = []
        var isDnsOverHttpsEnabled = false
        var dnsOverHttpsServer: String? = nil
        
        // Get DNS resolver configuration
        if let resolver = DNS.resolver {
            // Get DNS servers
            if let nameservers = resolver.nameservers {
                dnsServers = nameservers.compactMap { nameserver in
                    if let address = nameserver as? String {
                        return address
                    }
                    return nil
                }
            }
            
            // Get search domains
            if let domains = resolver.searchDomains {
                searchDomains = domains
            }
        }
        
        // Alternative method using resolv.conf (iOS fallback)
        if dnsServers.isEmpty {
            // On iOS, we can try to get DNS info from system proxy settings
            if let cfDict = CFNetworkCopySystemProxySettings() {
                let nsDict = cfDict.takeRetainedValue() as NSDictionary
                // Note: DNS info is not directly available through proxy settings
                // This is a limitation on iOS - DNS configuration is not directly accessible
            }
        }
        
        // Check for DNS over HTTPS
        if #available(iOS 14.0, *) {
            pathMonitor.pathUpdateHandler = { path in
                // Check if using encrypted DNS
                if path.usesInterfaceType(.cellular) || path.usesInterfaceType(.wifi) {
                    // Note: iOS doesn't provide direct API to check DoH status
                    // This is a placeholder for potential future implementation
                }
            }
        }
        
        return [
            "dnsServers": dnsServers,
            "searchDomains": searchDomains,
            "isDnsOverHttpsEnabled": isDnsOverHttpsEnabled,
            "dnsOverHttpsServer": dnsOverHttpsServer,
            "additionalInfo": [
                "iosVersion": UIDevice.current.systemVersion,
                "method": "SystemConfiguration"
            ]
        ]
    }
    
    private func getVpnInfo() -> [String: Any?] {
        let isConnected = isVpnConnected()
        var status = "disconnected"
        var vpnProvider: String? = nil
        var serverAddress: String? = nil
        var vpnProtocol: String? = nil
        var connectionStartTime: String? = nil
        
        if isConnected {
            status = "connected"
            
            // Try to get VPN configuration details using iOS-compatible methods
            // Note: Detailed VPN configuration access is limited on iOS for security reasons
            
            // Use NEVPNManager to get basic VPN info
            let vpnManager = NEVPNManager.shared()
            if let vpnConnection = vpnManager.protocolConfiguration {
                if vpnConnection is NEVPNProtocolIKEv2 {
                    vpnProtocol = "IKEv2"
                    if let ikev2 = vpnConnection as? NEVPNProtocolIKEv2 {
                        serverAddress = ikev2.serverAddress
                    }
                } else if vpnConnection is NEVPNProtocolIPSec {
                    vpnProtocol = "IPSec"
                    if let ipsec = vpnConnection as? NEVPNProtocolIPSec {
                        serverAddress = ipsec.serverAddress
                    }
                }
            }
            
            // Try to determine VPN type from network interfaces
            if let interfaces = getNetworkInterfaces() {
                for interface in interfaces {
                    if interface.hasPrefix("utun") {
                        vpnProvider = "Personal VPN"
                        if vpnProtocol == nil {
                            vpnProtocol = "IKEv2/IPSec"
                        }
                    } else if interface.hasPrefix("ipsec") {
                        if vpnProtocol == nil {
                            vpnProtocol = "IPSec"
                        }
                    } else if interface.hasPrefix("ppp") {
                        if vpnProtocol == nil {
                            vpnProtocol = "PPP"
                        }
                    }
                }
            }
        }
        
        return [
            "isVpnConnected": isConnected,
            "status": status,
            "vpnProvider": vpnProvider,
            "serverAddress": serverAddress,
            "protocol": vpnProtocol,
            "connectionStartTime": connectionStartTime,
            "additionalInfo": [
                "iosVersion": UIDevice.current.systemVersion
            ]
        ]
    }
    
    private func isVpnConnected() -> Bool {
        // Method 1: Check VPN status from System Configuration
        if let cfDict = CFNetworkCopySystemProxySettings() {
            let nsDict = cfDict.takeRetainedValue() as NSDictionary
            if let keys = nsDict["__SCOPED__"] as? NSDictionary {
                for key in keys.allKeys {
                    if let keyString = key as? String,
                       keyString.contains("tap") || keyString.contains("tun") || keyString.contains("ppp") || keyString.contains("ipsec") {
                        return true
                    }
                }
            }
        }
        
        // Method 2: Check network interfaces
        if let interfaces = getNetworkInterfaces() {
            for interface in interfaces {
                if interface.hasPrefix("utun") || interface.hasPrefix("ipsec") || interface.hasPrefix("ppp") {
                    return true
                }
            }
        }
        
        // Method 3: Check VPN configuration status
        let vpnStatus = getVpnStatus()
        return vpnStatus == .connected || vpnStatus == .connecting
    }
    
    private func getNetworkInterfaces() -> [String]? {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let name = String(cString: interface.ifa_name)
            addresses.append(name)
        }
        
        freeifaddrs(ifaddr)
        return Array(Set(addresses))
    }
    
    private func getVpnStatus() -> NEVPNStatus {
        let vpnManager = NEVPNManager.shared()
        return vpnManager.connection.status
    }
    
    // FlutterStreamHandler methods
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        // Start monitoring VPN status changes
        vpnStatusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAndEmitVpnStatus()
        }
        
        // Also monitor with path monitor
        pathMonitor.pathUpdateHandler = { [weak self] _ in
            self?.checkAndEmitVpnStatus()
        }
        pathMonitor.start(queue: monitorQueue)
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let observer = vpnStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        pathMonitor.cancel()
        eventSink = nil
        return nil
    }
    
    private func checkAndEmitVpnStatus() {
        guard let eventSink = eventSink else { return }
        
        let isConnected = isVpnConnected()
        eventSink(isConnected ? "connected" : "disconnected")
    }
}

// DNS resolver helper
struct DNS {
    static var resolver: DNSResolver? {
        return DNSResolver()
    }
}

class DNSResolver {
    var nameservers: [String]? {
        // On iOS, DNS server information is not directly accessible
        // due to system security restrictions
        // We can only get limited network information
        return nil
    }
    
    var searchDomains: [String]? {
        // On iOS, DNS search domains are not directly accessible
        // due to system security restrictions
        return nil
    }
}

