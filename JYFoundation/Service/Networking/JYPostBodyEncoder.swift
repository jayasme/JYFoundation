//
//  JYPostBodyEncoder.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/5/1.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import Alamofire

class JYPostJsonBodyEncoder: ParameterEncoding {

    static var shared: JYPostJsonBodyEncoder = JYPostJsonBodyEncoder()
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.addValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        guard let parameters = parameters else {
            return request
        }
        
        let body = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        request.httpBody = body
        return request
    }
}

/* class JYPostWWWFormEncoder: ParameterEncoding {
    
    static var shared: JYPostWWWFormEncoder = JYPostWWWFormEncoder()
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        guard let parameters = parameters else {
            return request
        }
        
        var body =
        let body = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        request.httpBody = body
        return request
    }
}
 */
