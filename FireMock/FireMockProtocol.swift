//
//  FireMockProtocol.swift
//  FireMock
//
//  Created by BEN HARZALLAH on 18/11/2016.
//  Copyright © 2016 BEN HARZALLAH. All rights reserved.
//

import Foundation

enum MockError: Error {
    case fileNotFound
    case buildDataFailed
}

public enum MockHTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case options = "OPTIONS"
    case head    = "HEAD"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public protocol FireMockProtocol {
    /// Bundle where file is located
    var bundle: Bundle { get }
    
    /// Specifies delay time before mock returns response. Default is 0.0 means instantly.
    var afterTime: TimeInterval { get }

    /// Specifies parameters name matching with url.
    var parameters: [String]? { get }

    /// Specifies headers fields returns from HTTPURLResponse. Default is nil.
    var headers: [String: String]? { get }

    /// Specifies version HTTP returns from HTTPURLResponse. Default is 1.1.
    var httpVersion: String? { get }

    /// Specifies status code returns from HTTPURLResponse. Default is 200.
    var statusCode: Int { get }

    /// Specifies name mock. Appear in view list mock.
    var name: String? { get }
    
    /// Specifies the name of mock file used.
    func mockFile() -> String
    
}

public extension FireMockProtocol {
    
    var afterTime: TimeInterval { return 0.0 }

    var bundle: Bundle { return Bundle.main }

    var parameters: [String]? { return nil }

    var headers: [String: String]? { return nil }

    var httpVersion: String? { return "1.1" }

    var statusCode: Int { return 200 }

    var name: String? { return nil }
    
    /// Read mock from mockFile function specifies in FireMockProtocol. If no extension, json is used to find the file.
    /// - Returns: Data file ou error if file not found.
    func readMockFile() throws -> Data {
        let name = self.mockFile()
        let components = name.components(separatedBy: ".")
        guard let resourceName = components.first else {
            throw MockError.fileNotFound
        }
        
        let extensionName: String
        if let ext = components.last, components.count > 1 {
            extensionName = ext
        } else {
            extensionName = "json"
        }
        
        if let path = bundle.path(forResource: resourceName, ofType: extensionName) {
            let url = URL(fileURLWithPath: path)
            do {
                return try Data(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
            } catch {
                throw MockError.buildDataFailed
            }
        } else {
            throw MockError.fileNotFound
        }
    }
    
}

public struct FireMock {
    
    public struct ConfigMock {
        var mock: FireMockProtocol
        var httpMethod: MockHTTPMethod
        var enabled: Bool = true
        var url: URL
    }
    
    /// Mocks added.
    public private(set) static var mocks: [ConfigMock] = []

    /// Specifies if FireMock is enabled.
    public private(set) static var isEnabled: Bool = false
    
    
    /// Register a FireMockProtocol used for a specific URL when request is fired.
    ///
    /// - Parameters:
    ///   - mock: FireMockProtocol contained file mock will be used.
    ///   - url: URL associated to mock.
    public static func register<T: FireMockProtocol>(mock: T, forURL url: URL, httpMethod: MockHTTPMethod, enabled: Bool = true) {

        // Remove similar mock if existing
        mocks = mocks.filter({ !($0.url == url && $0.httpMethod == httpMethod) })
        
        let config = ConfigMock(mock: mock, httpMethod: httpMethod, enabled: enabled, url: url)
        mocks.append(config)
    }
    
    /// Unregister a FireMockProtocol for a specific URL.
    ///
    /// - Parameter url: URL associated to mock.
    public static func unregister(forURL url: URL, httpMethod: MockHTTPMethod) {
        mocks = mocks.filter({ !($0.url == url && $0.httpMethod == httpMethod) })
    }
    
    /// Unregister all mocks.
    public static func unregisterAll() {
        mocks.removeAll()
    }

    internal static func update(configMock: ConfigMock) {
        mocks = mocks.filter({ !($0.url == configMock.url && $0.httpMethod == configMock.httpMethod) })
        mocks.append(configMock)
    }
    
    /// Enabled FireMock.
    ///
    /// - Parameter enabled: Enabled Mock in application.
    public static func enabled(_ enabled: Bool) {
        if enabled {
            URLProtocol.registerClass(FireURLProtocol.self)
        } else {
            URLProtocol.unregisterClass(FireURLProtocol.self)
        }
        
        FireMock.isEnabled = enabled
    }
    
    /// Specifies URLSessionConfiguration to use when request if fired.
    public static var sessionConfiguration: URLSessionConfiguration? = nil
    
    /// Specifies hosts where mock can be used. If empty, mock works for all hosts.
    public static var onlyHosts: [String] = []
    
    /// Specifies hosts where mock cannot be used.
    public static var excludeHosts: [String] = []

    public static func presentMockRegister(from: UIViewController, backTapped: ( () -> Void )?) {
        let mockController = FireMockViewController(nibName: "FireMockViewController", bundle: Bundle(for: FireMockViewController.self))
        mockController.backTapped = backTapped
        from.present(mockController, animated: true, completion: nil)
    }
}

func ==(lhs: FireMock.ConfigMock, rhs: FireMock.ConfigMock) -> Bool {
    return lhs.url == rhs.url && rhs.httpMethod == lhs.httpMethod
}


