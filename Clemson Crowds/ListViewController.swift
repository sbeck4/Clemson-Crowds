//
//  ListViewController.swift
//  Clemson Crowds
//
//  Created by Shannon Beck on 1/29/17.
//  Copyright © 2017 Shannon Beck. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref : FIRDatabaseReference?
    var places: [Place] = []
    @IBOutlet var tableView: UITableView!
    var cacheArray: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()


        ref = FIRDatabase.database().reference()
//        self.addPlaces()

        let _ = (ref?.queryLimited(toFirst: 100))?.observe(.value, with: { (snapshot) in
            self.places.removeAll()

            for snap in snapshot.children.allObjects as! [FIRDataSnapshot] {
                self.places.append(Place.snapshotToPlace(snap: snap))
            }

            self.places = Places.produceRandomData(places: self.places)
            self.cacheArray = [UIImage](repeating: UIImage(), count: self.places.count)
            self.tableView.reloadData()
        })


        let _ = ref?.observe(FIRDataEventType.childChanged, with: { (snapshot) in
            let place = Place.snapshotToPlace(snap: snapshot.children.allObjects.first as! FIRDataSnapshot)
            for (index, p) in self.places.enumerated() {
                if p.name == place.name {
                    self.places[index] = p
                }
            }
        })
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell") as! MainListTableViewCell

        let place = places[indexPath.row]
        cell.iconView.layer.cornerRadius = cell.iconView.frame.width/2
        cell.placeIconImage.image = place.placeImageIcon()
        cell.crowdLevelView.layer.cornerRadius = cell.crowdLevelView.frame.width/2
        cell.crowdIconImage.image = place.crowdImage()
        cell.placeNameLabel.text = place.name
        cell.crowdLevelLabel.text = place.crowdDescription()
        cell.placeImage.image = #imageLiteral(resourceName: "placeholder")

        if cacheArray[indexPath.row].size != CGSize.zero {
            cell.placeImage.image = cacheArray[indexPath.row]
        } else {
            let task = URLSession.shared.dataTask(with: URL.init(string: place.placeImage)!) { (responseData, responseUrl, error) -> Void in
                // if responseData is not null...
                if let data = responseData{

                    // execute in UI thread
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.cacheArray[indexPath.row] = UIImage(data: data)!
                        cell.placeImage.image = self.cacheArray[indexPath.row]
                    })
                }
            }
            task.resume()
        }

        cell.currentPeopleLabel.text = "~\(place.currentCrowdNumber!) people"
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }


    func addPlaces() {
        let places = Places.initalizePlaces()
        for place in places {
            ref?.child(place.name!).setValue(place.dictionaryOf())
            if place.floors != [] {
                for floor in place.floors {
                    ref?.child("\(place.name!)/floors/\(floor.name!)").setValue(floor.dictionaryOf())
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
           let destVC = segue.destination as! DetailViewController
            destVC.place = places[(tableView.indexPathForSelectedRow?.row)!]
        } else if segue.identifier == "mapSegue" {
            let mapVC = segue.destination as! MapViewController
            mapVC.places = places
        }

        let backItem = UIBarButtonItem()
        backItem.title = ""
        backItem.image = #imageLiteral(resourceName: "list")
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationItem.backBarButtonItem = backItem
    }


}
