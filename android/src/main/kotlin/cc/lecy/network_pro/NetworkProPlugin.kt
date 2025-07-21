package cc.lecy.network_pro

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import java.net.InetAddress
import android.net.VpnService
import android.content.Intent
import android.net.NetworkRequest
import android.net.ConnectivityManager.NetworkCallback

/** NetworkProPlugin */
class NetworkProPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null
  private var networkCallback: NetworkCallback? = null
  private lateinit var connectivityManager: ConnectivityManager

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "network_pro")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "network_pro/vpn_status")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getDnsInfo" -> {
        result.success(getDnsInfo())
      }
      "getVpnInfo" -> {
        result.success(getVpnInfo())
      }
      "isVpnConnected" -> {
        result.success(isVpnConnected())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getDnsInfo(): Map<String, Any?> {
    val dnsServers = mutableListOf<String>()
    val searchDomains = mutableListOf<String>()
    var isDnsOverHttpsEnabled = false
    var dnsOverHttpsServer: String? = null

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val activeNetwork = connectivityManager.activeNetwork
      val linkProperties = connectivityManager.getLinkProperties(activeNetwork)
      
      linkProperties?.let { lp ->
        // Get DNS servers
        lp.dnsServers.forEach { dns ->
          dnsServers.add(dns.hostAddress ?: dns.toString())
        }
        
        // Get search domains
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          lp.domains?.split(",")?.forEach { domain ->
            searchDomains.add(domain.trim())
          }
        }
        
        // Check for DNS over HTTPS (Private DNS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
          val privateDnsServerName = lp.privateDnsServerName
          if (!privateDnsServerName.isNullOrEmpty()) {
            isDnsOverHttpsEnabled = true
            dnsOverHttpsServer = privateDnsServerName
          }
        }
      }
    }

    // Fallback for older Android versions
    if (dnsServers.isEmpty()) {
      try {
        val systemProperties = Class.forName("android.os.SystemProperties")
        val method = systemProperties.getMethod("get", String::class.java)
        
        for (i in 1..4) {
          val dns = method.invoke(null, "net.dns$i") as String?
          if (!dns.isNullOrEmpty() && dns != "0.0.0.0") {
            dnsServers.add(dns)
          }
        }
      } catch (e: Exception) {
        e.printStackTrace()
      }
    }

    return mapOf(
      "dnsServers" to dnsServers,
      "searchDomains" to searchDomains,
      "isDnsOverHttpsEnabled" to isDnsOverHttpsEnabled,
      "dnsOverHttpsServer" to dnsOverHttpsServer,
      "additionalInfo" to mapOf(
        "androidVersion" to Build.VERSION.SDK_INT,
        "method" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) "LinkProperties" else "SystemProperties"
      )
    )
  }

  private fun getVpnInfo(): Map<String, Any?> {
    val isConnected = isVpnConnected()
    var status = "disconnected"
    var vpnProvider: String? = null
    var serverAddress: String? = null
    var protocol: String? = null

    if (isConnected) {
      status = "connected"
      
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val activeNetwork = connectivityManager.activeNetwork
        val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        val linkProperties = connectivityManager.getLinkProperties(activeNetwork)
        
        networkCapabilities?.let { nc ->
          if (nc.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            // Try to get VPN details from link properties
            linkProperties?.let { lp ->
              // Interface name might give hints about VPN type
              val interfaceName = lp.interfaceName
              vpnProvider = when {
                interfaceName?.contains("tun", ignoreCase = true) == true -> "Generic VPN (TUN)"
                interfaceName?.contains("tap", ignoreCase = true) == true -> "Generic VPN (TAP)"
                interfaceName?.contains("ipsec", ignoreCase = true) == true -> "IPSec VPN"
                interfaceName?.contains("pptp", ignoreCase = true) == true -> "PPTP VPN"
                else -> "Unknown VPN"
              }
              
              // Try to get routes which might contain VPN server
              lp.routes.firstOrNull()?.let { route ->
                serverAddress = route.gateway?.hostAddress
              }
            }
          }
        }
      }
    }

    return mapOf(
      "isVpnConnected" to isConnected,
      "status" to status,
      "vpnProvider" to vpnProvider,
      "serverAddress" to serverAddress,
      "protocol" to protocol,
      "connectionStartTime" to null, // Android doesn't provide this easily
      "additionalInfo" to mapOf(
        "androidVersion" to Build.VERSION.SDK_INT
      )
    )
  }

  private fun isVpnConnected(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val networks = connectivityManager.allNetworks
      for (network in networks) {
        val capabilities = connectivityManager.getNetworkCapabilities(network)
        if (capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
          return true
        }
      }
    } else {
      // For older versions, check if VPN interface exists
      try {
        val networkInterfaces = java.net.NetworkInterface.getNetworkInterfaces()
        while (networkInterfaces.hasMoreElements()) {
          val networkInterface = networkInterfaces.nextElement()
          val interfaceName = networkInterface.name
          if (interfaceName.contains("tun") || interfaceName.contains("tap") || 
              interfaceName.contains("ppp") || interfaceName.contains("pptp")) {
            return true
          }
        }
      } catch (e: Exception) {
        e.printStackTrace()
      }
    }
    return false
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      networkCallback = object : NetworkCallback() {
        override fun onAvailable(network: Network) {
          checkAndEmitVpnStatus()
        }
        
        override fun onLost(network: Network) {
          checkAndEmitVpnStatus()
        }
        
        override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
          checkAndEmitVpnStatus()
        }
      }
      
      val networkRequest = NetworkRequest.Builder()
        .addTransportType(NetworkCapabilities.TRANSPORT_VPN)
        .build()
        
      connectivityManager.registerNetworkCallback(networkRequest, networkCallback!!)
    }
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      networkCallback?.let {
        connectivityManager.unregisterNetworkCallback(it)
      }
      networkCallback = null
    }
  }

  private fun checkAndEmitVpnStatus() {
    eventSink?.let { sink ->
      val isConnected = isVpnConnected()
      sink.success(if (isConnected) "connected" else "disconnected")
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}

