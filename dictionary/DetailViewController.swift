//
//  DetailViewController.swift
//  dictionary
//
//  Created by Kristoffer Anger on 2022-10-18.
//

import UIKit

class DetailViewController: UIViewController {
    
    var word: String?
    var removeAction: (() -> Void) = {}
    
    lazy private var removeButton: UIButton = {
        var configuration = UIButton.Configuration.gray()
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .tintColor
        configuration.buttonSize = .large
        configuration.title = String(format: "Remove %@", word ?? "")
        let button = UIButton(configuration: configuration, primaryAction: UIAction(){ _ in
            self.removeAction()
            self.navigationController?.popViewController(animated: true)
        })
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = word ?? "Unknown"
        
        self.view.addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.view.bottomAnchor.constraint(equalTo: removeButton.bottomAnchor, constant: 60).isActive = true
    }
}
