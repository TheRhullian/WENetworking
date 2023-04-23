//
//  WENetworking.swift
//  WENetworking
//
//  Created by Rhullian Damião on 21/04/23.
//

import Foundation

struct WENetworkingRequest {
    var host: String
    var endpoint: String
    var urlQueries: [String: String]
    var params: [String: Any]
    var header: [String: String]
    var httpMethod: WENetworking.HTTPMethod
}

struct WEError: Error {
    let code: Int
    let message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    static func urlRequestNotCreated() -> WEError {
        return self.init(code: -1, message: "[WEError]: Request not created")
    }
    
    static func dataNotReceived() -> WEError {
        return self.init(code: -2, message: "[WEError]: Data not received")
    }
    
    static func responseNotReceived() -> WEError {
        return self.init(code: -3, message: "[WEError]: Response not received")
    }
}

class WENetworking {
    enum HTTPMethod: String {
        case GET, POST, PATCH, DELETE
    }
    /// Singleton
    static let shared = WENetworking()
    let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 40
        session = URLSession(configuration: configuration)
    }
    
    /// Make a request that have a Codable Object as response
    /// - Parameters:
    ///   - request: WENetworkingRequest Object
    ///   - onSuccess: Completion called when there is a Success on request
    ///   - onFailure: Completion called when there is a Failure on request
    public func makeRequest<T: Codable>(request: WENetworkingRequest,
                                        onSuccess: @escaping ((T?) -> Void),
                                        onFailure: @escaping ((Error) -> Void)) {
        guard let request = buildURLRequest(request: request) else {
            return onFailure(WEError.urlRequestNotCreated())
        }
        logRequest(request: request)
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                onFailure(WEError(code: (response as? HTTPURLResponse)?.statusCode ?? -1, message: error.localizedDescription))
            } else {
                guard let data else {
                    return onFailure(WEError.dataNotReceived())
                }
                let object: T? = data.convertObject()
                logResponse(response: object)
                onSuccess(object)
            }
        }.resume()
    }
    
    /// Make a request that doesn't have a object on response
    /// - Parameters:
    ///   - request: WENetworkingRequest Object
    ///   - onSuccess: Completion called when there is a Success on request
    ///   - onFailure: Completion called when there is a Failure on request
    public func makeRequest(request: WENetworkingRequest,
                            onSuccess: @escaping (() -> Void),
                            onFailure: @escaping ((Error) -> Void)) {
        guard let request = buildURLRequest(request: request) else {
            return onFailure(WEError.urlRequestNotCreated())
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error {
                return onFailure(WEError(code: (response as? HTTPURLResponse)?.statusCode ?? -1, message: error.localizedDescription))
            } else {
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                    return onFailure(WEError.responseNotReceived())
                }
                print("[WENetworking]: REQUEST SUCCESS")
                return statusCode == 200 ? onSuccess() : onFailure(WEError(code: statusCode, message: "[WEError]: Somenthing went wrong with the request"))
            }
        }
    }
    
    /// Function to create a URL Request
    /// - Parameter request: WENetworkingRequest Object
    /// - Returns: URL Request
    private func buildURLRequest(request: WENetworkingRequest) -> URLRequest? {
        guard var url = URL(string: request.host + request.endpoint) else { return nil }
        
        // ADD QUERY ITEMS
        var queries = [URLQueryItem]()
        request.urlQueries.forEach { (key: String, value: String) in
            queries.append(URLQueryItem(name: key, value: value))
        }
        if !queries.isEmpty {
            url.append(queryItems: queries)
        }
        
        // BUILD REQUEST
        var urlReq = URLRequest(url: url)
        
        urlReq.httpMethod = request.httpMethod.rawValue
        if !request.params.isEmpty {
            urlReq.httpBody = Data.createData(params: request.params)
        }
        
        request.header.forEach { (key: String, value: String) in
            urlReq.addValue(value, forHTTPHeaderField: key)
        }
        
        return urlReq
    }
    
    private func logRequest(request: URLRequest) {
        print("[WENetworking - \(request.httpMethod ?? "No Method")]: \(request.url?.description ?? ">>> No URL <<<")\n")
        let headers = request.allHTTPHeaderFields ?? [:]
        print(headers.isEmpty ? ">>> No Headers <<<" : headers)
        print((try? JSONSerialization.jsonObject(with: request.httpBody ?? Data())) ?? ">>> No Body <<<")
    }
    
    private func logResponse(response: Codable? = nil) {
        print((response?.json ?? "----SEM RESPOSTA PARSEAVEL----") as Any)
    }
}

// MARK: - ENCODABLE EXTENSION
extension Encodable {
    var json: NSString {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else { return "" }
        let result = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return result ?? ""
    }
    
    var jsonFromData: NSString {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let result = NSString(data: self as! Data, encoding: String.Encoding.utf8.rawValue)
        return result ?? ""
    }
}

// MARK: - DATA EXTENSION
extension Data {
    
    /// Create a data object from dictionary parameters
    /// - Parameter params: Parameters Dictionary
    /// - Returns: Data Encoded
    static func createData(params: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: params)
    }
    
    /// Create a data object from a codable object
    /// - Parameter paramsObj: Codable Object
    /// - Returns: Data Encoded
    static func createData(paramsObj: Codable) -> Data? {
        return try? JSONEncoder().encode(paramsObj)
    }
    
    func convertObject<T: Codable>() -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
}

