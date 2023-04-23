//
//  ViewController.swift
//  WENetworking
//
//  Created by Rhullian Damião on 21/04/23.
//

import UIKit

struct BasicModel: Codable {
    let id: Int
    let title: String
    let completed: Bool
}

class ViewController: UIViewController {

    let host = "https://rhutest.free.beeceptor.com"
    let endpoint = "/todos"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let getReq = WENetworkingRequest(host: host,
                                         endpoint: endpoint,
                                         urlQueries: [:],
                                         params: [:],
                                         header: [:],
                                         httpMethod: .GET)
        WENetworking.shared.makeRequest(request: getReq) { (object: [BasicModel]?) in
            
        } onFailure: { error in
            print(error)
        }

    }
}

