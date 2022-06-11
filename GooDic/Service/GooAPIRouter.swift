//
//  GooAPIRouter.swift
//  GooDic
//
//  Created by ttvu on 12/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

class GooAPIRouter {
    class func buildURL(url: String, params: [String: String]? = nil) -> URL? {
        if var urlComponents = URLComponents(string: url) {
            let queryItems = params?.map({ URLQueryItem(name: $0.key, value: $0.value) })
            urlComponents.queryItems = queryItems
            
            return urlComponents.url
        }
        
        return nil
    }
    
    // httpBody is JSON Object
    class func request<T:Codable>(ofType type: T.Type,
                                  url: String,
                                  urlParams: [String: String]? = nil,
                                  httpBody: [String: Encodable],
                                  method: HttpMethodSession,
                                  header: [String: String] = [:],
                                  needCheckHttpStatusCode: Bool = false) -> Observable<T>{
        
        let data = try? JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        var newHeader = header
        newHeader["Content-Type"] = "application/json"
        
        return request(ofType: type,
                       url: url,
                       urlParams: urlParams,
                       httpBody: data,
                       method: method,
                       header: newHeader,
                       needCheckHttpStatusCode: needCheckHttpStatusCode)
    }
    
    class func request<T:Codable>(ofType type: T.Type,
                                  url: String,
                                  urlParams: [String: String]? = nil,
                                  httpBody: Data? = nil,
                                  method: HttpMethodSession,
                                  header: [String: String] = [:],
                                  needCheckHttpStatusCode: Bool = false) -> Observable<T>{
        
        guard let url = buildURL(url: url, params: urlParams) else {
            return Observable.error(GooServiceError.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if httpBody != nil {
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.addValue(GlobalConstant.userAgent, forHTTPHeaderField: "User-Agent")
        header.forEach({ (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        })
        
        return URLSession.shared.rx
            .response(request: request)
            .flatMapLatest { (data) -> Observable<T> in
                self.tracking(data: data.data, parameters: urlParams?.description, method: method, url: url, header: header, httpBody: httpBody)
                if needCheckHttpStatusCode {
                    if data.response.statusCode >= 400 {
                        return Observable.error(GooServiceError.errorHttpStatus("\(data.response.statusCode)"))
                    }
                }
                do {
                    let object = try JSONDecoder().decode(T.self, from: data.data)
                    return Observable.just(object)
                } catch let err {
                    return Observable.error(err)
                }
            }
    }
    
    class func requestAPI<T:Codable>(ofType type: T.Type,
                                     url: URL,
                                     parameters: String?,
                                     method: HttpMethodSession,
                                     header: [String: String] = [:],
                                     isTimeout: Bool = false) -> Observable<GooResponse<T>>{
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = parameters?.data(using: .utf8)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(GlobalConstant.userAgent, forHTTPHeaderField: "User-Agent")
        header.forEach({ (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        })
        
        if isTimeout {
            request.timeoutInterval = 10
        }
        
        return URLSession.shared.rx
            .response(request: request)
            .flatMapLatest { (data) -> Observable<GooResponse<T>> in
                self.tracking(data: data.data, parameters: parameters, method: method, url: url, header: header, httpBody: nil)
                do {
                    let object = try JSONDecoder().decode(GooResponse<T>.self, from: data.data)
                    return Observable.just(object)
                } catch let err {
                    return Observable.error(err)
                }
            }
    }
    
    class func tracking(data: Data,parameters: String?, method: HttpMethodSession, url: URL, header: [String: String], httpBody: Data?) {
        #if DEBUG
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            var body: [String : Any]? = [:]
            if let data = httpBody {
                body = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            }
            
            print("------------ API RESPONSE ---------")
            print("// Success")
            print("//Method: \(method)")
            print("//url")
            print("//\(url)")
            print("//Parameters")
            print("//\(parameters ?? "")")
            print("//HttpBody")
            print("//\(String(describing: body))")
            print("//Header")
            print("//\(header)")
            print("//JSON")
            print("\(String(describing: json))")
            print("-----------------------------------")
        } catch let err {
            print(err.localizedDescription)
        }
        #endif
    }
}
enum HttpMethodSession: String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
    case delete = "DELETE"
}
