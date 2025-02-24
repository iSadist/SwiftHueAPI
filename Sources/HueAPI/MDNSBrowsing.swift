//
//  MDNSBrowsing.swift
//
//  This file contains code for browsing for mDNS services.
//
//  Created by Jan Svensson on 2025-02-24.
//

import Foundation
import Network

public protocol MDNSBrowsing {
    var delegate: MDNSBrowserDelegate? { get set }
    func searchForDevice(serviceType: String)
}

/// A delegate for the MDNSBrowser
public protocol MDNSBrowserDelegate: AnyObject {
    /// Method is called when there is an update to the list of resolved ip addresses.
    /// - Parameter addresses: The IP addresses
    func update(addresses: [String])
}

fileprivate func isIPAddress(value: String) -> Bool {
    let parts = value.components(separatedBy: ".")
    let nums = parts.compactMap { Int($0) }
    guard nums.count == parts.count else { return false }
    return nums.filter { $0 >= 0 && $0 <= 255 }.count == nums.count
}

/// A class for browsing for mDNS services and resolving their ip addresses.
public class MDNSBrowser: NSObject, MDNSBrowsing {
    private var browser: NetServiceBrowser
    private var netServices: [NetService] = []
    /// A list of resolved ip addresses.
    private(set) var resolvedAddresses: [String] = []
    
    /// The delegate for the browser
    public var delegate: MDNSBrowserDelegate?

    override public init() {
        browser = NetServiceBrowser()
        super.init()
        browser.delegate = self
    }

    /// Search for devices of a specific registered service type. This service type needs to be registered
    /// in Info.plist Bonjour Services.
    /// - Parameter serviceType: The registered service type.
    public func searchForDevice(serviceType: String) {
        browser.searchForServices(ofType: serviceType, inDomain: "local.")
    }

    deinit {
        browser.stop()
        netServices.removeAll()
    }
}

extension MDNSBrowser: NetServiceBrowserDelegate {
    public func netServiceDidStop(_ sender: NetService) {
        // Remove the service from the list if it has stopped
        if let index = netServices.firstIndex(of: sender) {
            netServices.remove(at: index)
        }
    }

    public func netServiceWillResolve(_ sender: NetService) {
        print(sender.name)
        netServices.append(sender)
        sender.delegate = self
        sender.resolve(withTimeout: 5.0)
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }
}

extension MDNSBrowser: NetServiceDelegate {
    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        if let errorCode = errorDict[NetService.errorCode] {
            print("Failed to resolve service: \(sender) with error: \(errorCode)")
        } else {
            print("Failed to resolve service: \(sender) with unknown error")
        }
    }

    public func netServiceDidResolveAddress(_ sender: NetService) {
        if let addresses = sender.addresses {
            for address in addresses {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                
                address.withUnsafeBytes { addressBytes in
                    if let pointer = addressBytes.baseAddress?.assumingMemoryBound(to: sockaddr.self) {
                        if getnameinfo(pointer, socklen_t(addressBytes.count),
                                       &hostname, socklen_t(hostname.count),
                                       nil, 0, NI_NUMERICHOST) == 0 {
                            if let addressString = String(cString: hostname, encoding: String.Encoding.utf8) {
                                if isIPAddress(value: addressString) {
                                    print("Found device IP: \(addressString)")
                                    resolvedAddresses.append(addressString)
                                    delegate?.update(addresses: resolvedAddresses)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

