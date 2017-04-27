//
//  AWSCredentialsViewController.swift
//  Pickery
//
//  Created by Okan Arikan on 10/21/16.
//
//


import UIKit
import Eureka
import CoreLocation
import SwiftLocation
import ReactiveSwift

/// AWS credentials form
class AWSCredentialsViewController : FormViewController {
    
    /// Da constants
    struct Constants {
        static let kLocationTag = "location"
    }

    /// We want the navigation bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    /// Configure the view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The view controller title
        title = "Credentials"
        
        // No back button text
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // The access id
        form +++ Section("AWS Credentials")
            <<< TextRow() { row in
                    row.title = "Access Id"
                    row.value = Credentials.sharedInstance.awsAccessId
                    row.add(rule: RuleRequired())
                    row.add(rule: RuleMinLength(minLength: 20))
                    row.add(rule: RuleMaxLength(maxLength: 20))
                    row.validationOptions = .validatesOnChange
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { row in
                    Credentials.sharedInstance.awsAccessId = row.value
                }
            <<< TextRow() { row in
                    row.title = "Secret Key"
                    row.value = Credentials.sharedInstance.awsSecretKey
                    row.add(rule: RuleRequired())
                    row.add(rule: RuleMinLength(minLength: 40))
                    row.add(rule: RuleMaxLength(maxLength: 40))
                    row.validationOptions = .validatesOnChange
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                } .onChange { row in
                    Credentials.sharedInstance.awsSecretKey = row.value
                }
            <<< PickerInlineRow<String>(Constants.kLocationTag) { row in
                    row.title   =   "Region"
                    row.value   =   Amazon.region(for: Credentials.sharedInstance.awsRegion ?? "")?.name ?? ""
                    row.options =   Amazon.Constants.kAllRegions.map { return $0.name }
                }.onChange{ row in
                    Credentials.sharedInstance.awsRegion = row.value
                }
            <<< ButtonRow() { row in
                    row.title = "Pick nearest region"
                }.onCellSelection { _ in
                    self.pickNearestRegion()
                }
        
        // The login button
        form +++ Section("")
            <<< ButtonRow() { row in
                    row.title = "Connect"
                }.onCellSelection { _ in
                    self.login()
                }
    }
    
    /// Pick the nearest region here
    func pickNearestRegion() {
        
        // Grab the location
        Location.getLocation(accuracy: .city, frequency: Frequency.oneShot, success: { request, location in
            assertMainQueue()
            
            // Pick the closest region
            let closestRegion = Amazon.Constants
                .kAllRegions
                .map { (region: Amazon.Region) -> (coordinate: CLLocationDistance, name: String, regionText: String) in
                    return (region.coordinate.metersTo(coordinate: location.coordinate),region.name, region.regionString)
                }
                .min { return $0.0 < $1.0 }
            
            
            // Got region?
            if let closestRegion = closestRegion {
                Credentials.sharedInstance.awsRegion = closestRegion.regionText
                
                // Update the row
                if let row : PickerInlineRow<String> = self.form.rowBy(tag: Constants.kLocationTag) {
                    row.value = closestRegion.name
                    row.reload()
                }
            }
        }) { location, request, error in
            Logger.error(error: error)
        }
        
    }
    
    /// Trigger the login
    func login() {

        // Successful initialization?
        if let initializer = Credentials.sharedInstance.initializer {

            // Set the initializer
            RemoteLibrary.sharedInstance.initializeBackend(producer: initializer)
            
            // Go to the grid view controller right away
            navigationController?.pushViewController(AssetCollectionViewController(collectionViewLayout: AssetLayout()), animated: false)            
        }
    }
}

