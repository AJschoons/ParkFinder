//
//  NetworkingHelpers.swift
//  NearbyParkFinder
//
//  Created by adam on 12/23/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

// use "task, responseObject in"
typealias AFHTTPSuccessBlock = ((task: NSURLSessionDataTask?, responseObject: AnyObject?) -> Void)?
// use "task, error in"
typealias AFHTTPFailureBlock = ((task: NSURLSessionDataTask?, error: NSError?) -> Void)?

let defaultExtraNetworkingAttempts = 2

let defaultAFHTTPFailureBlock: AFHTTPFailureBlock = { task, error in
    guard let task = task, error = error else { return }
    var haveHTTPCodeErrorMessage = false
    
    if let response = task.response as? NSHTTPURLResponse {
        let code = response.statusCode
        if code == 400 || code == 401 || code == 404 || code == 500 || code == 503 {
            haveHTTPCodeErrorMessage = true
            print("Networking error: \(code)")
        }
    }
    
    if !haveHTTPCodeErrorMessage {
        print("Networking error: \(error.code)")
    }
}

func errorShouldBeHandledWithRepeatedRequest(error: NSError!, attemptsLeft: Int? = nil) -> Bool {
    guard let error = error else { return false }
    var shouldRepeatRequest = false
    
    let code = error.code
    if code == -1001 || code == -1003 || code == -1004 || code == -1005 || code == -1009 || code == -1011 {
        // If timed out, cannot find host, cannot connect to host, connection lost, not connected to internet, server 500 code equivalent
        shouldRepeatRequest = true
    }
    
    if attemptsLeft != nil {
        return (shouldRepeatRequest && (attemptsLeft > 0))
    } else {
        return shouldRepeatRequest
    }
}


