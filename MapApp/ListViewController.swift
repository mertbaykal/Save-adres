//
//  ListViewController.swift
//  MapApp
//
//  Created by Mert Baykal on 22/09/2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITabBarDelegate,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var namesArray = [String]()
    var idArray = [UUID]()
    var selectedPlaceId : UUID?
    var selectedPlaceName = " "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addClicked))
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let contex = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try contex.fetch(request)
            
            if results.count > 0 {
                
                namesArray.removeAll(keepingCapacity: false)
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    
                    if let name = result.value(forKey: "name") as? String {
                        namesArray.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        idArray.append(id)
                    }
                    tableView.reloadData() // guncelemek - yenilemek
                    
                }
            }
        }catch{
            print("hata")
        }
    }
 
    @objc func addClicked(){
        selectedPlaceName = " "
        performSegue(withIdentifier: "toMapVC", sender: nil) //segue sayfasini degistirme
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return namesArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = namesArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlaceName = namesArray[indexPath.row]
        selectedPlaceId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // veri gonderimi
        if segue.identifier == "toMapVC"  {
            let destinationVS = segue.destination as! mapViewController
            destinationVS.selectedName = selectedPlaceName
            destinationVS.selectedID = selectedPlaceId
        }
            
    }
    
}
