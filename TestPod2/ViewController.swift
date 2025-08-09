//
//  ViewController.swift
//  TestPod2
//
//  Created by Tez Park on 8/9/25.
//

import UIKit
import SendbirdAIAgentMessenger

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        AIAgentMessenger.initialize(appId: "test", params) { result in
            
        }
    }


}

