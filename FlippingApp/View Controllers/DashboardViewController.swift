//
//  DashboardViewController.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 2/12/21.
//

import UIKit

class DashboardViewController: UIViewController {
    
    // MARK: - Properties
    
    let itemController = ItemController()
    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()
    var recentlyListedPrice: Double = 0.0
    
    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var profitView: UIView!
    @IBOutlet weak var inventoryView: UIView!
    @IBOutlet weak var soldItemsView: UIView!
    @IBOutlet weak var salesView: UIView!
    @IBOutlet weak var addItemButton: UIButton!
    @IBOutlet weak var inventoryButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var soldItemsButton: UIButton!
    @IBOutlet weak var recordSaleButton: UIButton!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var inventoryValueLabel: UILabel!
    @IBOutlet weak var inventoryQuantityLabel: UILabel!
    @IBOutlet weak var numberOfSalesLabel: UILabel!
    @IBOutlet weak var recentlyAddedLabel: UILabel!
    @IBOutlet weak var recentItemNameLabel: UILabel!
    @IBOutlet weak var recentItemPriceLabel: UILabel!
    @IBOutlet weak var oldestItemLabel: UILabel!
    @IBOutlet weak var oldestItemNameLabel: UILabel!
    @IBOutlet weak var oldestItemDaysLabel: UILabel!
    
    // MARK: - IBActions
    
    @IBAction func inventoryButtonTapped(_ sender: UIButton) {
        guard let inventoryVC = storyboard?.instantiateViewController(identifier: "InventoryVC") as? InventoryViewController else { return }
        inventoryVC.itemController = itemController
        inventoryVC.searchType = "inventory"
        inventoryVC.filteredItems = itemController.inventory
        inventoryVC.viewingSold = false
        inventoryVC.delegate = self
        present(inventoryVC, animated: true, completion: nil)
    }
    
    @IBAction func soldItemsButtonTapped(_ sender: UIButton) {
        guard let inventoryVC = storyboard?.instantiateViewController(identifier: "InventoryVC") as? InventoryViewController else { return }
        inventoryVC.itemController = itemController
        inventoryVC.searchType = "soldItems"
        inventoryVC.filteredItems = itemController.soldItems
        inventoryVC.viewingSold = true
        inventoryVC.delegate = self
        present(inventoryVC, animated: true, completion: nil)
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        guard let inventoryVC = storyboard?.instantiateViewController(identifier: "InventoryVC") as? InventoryViewController else { return }
        inventoryVC.itemController = itemController
        inventoryVC.filteredItems = itemController.inventory
        inventoryVC.viewingSold = false
        inventoryVC.delegate = self
        inventoryVC.searchType = "selling"
        present(inventoryVC, animated: true, completion: nil)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemController.load()
        itemController.delegate = self
        updateViews()
    }
    
    // MARK: - View configuration
    
    func updateViews() {
        numberFormatter.numberStyle = .currency
        profitLabel.text = numberFormatter.string(from: itemController.calculateProfit() as NSNumber)
        inventoryValueLabel.text = numberFormatter.string(from: itemController.calculateInventoryValue() as NSNumber)
        if itemController.calculateInventoryValue() > 2147483647 {
            inventoryValueLabel.text = "Too High!"
            inventoryValueLabel.textColor = .systemYellow
        } else if itemController.calculateInventoryValue() >= 1 {
            inventoryValueLabel.textColor = .systemGreen
        } else {
            inventoryValueLabel.textColor = .white
        }

        numberFormatter.numberStyle = .decimal
        numberOfSalesLabel.text = numberFormatter.string(from: itemController.calculateSales() as NSNumber)
        
        if itemController.inventory.isEmpty {
            for constraint in salesView.constraints {
                if constraint.identifier == "salesViewHeight" {
                    constraint.constant = 100
                }
            }
        } else {
            for constraint in salesView.constraints {
                if constraint.identifier == "salesViewHeight" {
                    constraint.constant = 200
                }
            }
        }
        
        if itemController.inventory.isEmpty {
            oldestItemDaysLabel.text = ""
            oldestItemNameLabel.text = ""
            oldestItemLabel.isHidden = true
            recentItemNameLabel.text = "Add an item to begin"
            recentItemPriceLabel.isHidden = true
        } else {
            if let recentlyListed = itemController.inventory.last {
                if recentlyListed.quantity > 1 {
                    for _ in 1...recentlyListed.quantity {
                        recentlyListedPrice += itemController.inventory.last?.listingPrice ?? 0
                    }
                } else {
                    recentlyListedPrice = recentlyListed.listingPrice ?? -1
                }
                
                recentItemPriceLabel.isHidden = false
                recentItemNameLabel.text = itemController.inventory.last?.title
                numberFormatter.numberStyle = .currency
                recentItemPriceLabel.text = "\(numberFormatter.string(from: recentlyListedPrice as NSNumber) ?? "Unknown")"
            }
           
            if let oldestDate = itemController.inventory.first?.listedDate {
                if let diffInDays = Calendar.current.dateComponents([.day], from: oldestDate, to: Date()).day {
                    oldestItemLabel.isHidden = false
                    oldestItemNameLabel.text = itemController.inventory.first?.title
                    numberFormatter.numberStyle = .none
                    oldestItemDaysLabel.text = "\(numberFormatter.string(from: diffInDays as NSNumber) ?? "") days"
                }
            } else {
                oldestItemDaysLabel.text = ""
            }
        }
        
        inventoryQuantityLabel.text = numberFormatter.string(from: itemController.calculateInventoryQuantity() as NSNumber)
        
        // Easter egg
        if UserDefaults.standard.bool(forKey: "gnomes") {
            titleLabel.text = "Gnomeboard"
        } else {
            titleLabel.text = "Dashboard"
        }
        
        configureViews()
        configureColors()
    }
    
    func configureViews() {
        profitView.layer.cornerRadius = 12
        inventoryView.layer.cornerRadius = 12
        soldItemsView.layer.cornerRadius = 12
        salesView.layer.cornerRadius = 12
        
        inventoryButton.layer.cornerRadius = 12
        soldItemsButton.layer.cornerRadius = 12
        settingsButton.layer.cornerRadius = 25
        addItemButton.layer.cornerRadius = 25
        recordSaleButton.layer.cornerRadius = 25
        
        profitView.layer.shadowOpacity = 0.7
        profitView.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        profitView.layer.shadowRadius = 4
        profitView.layer.shadowOffset = CGSize(width: 0, height: 8)
        profitView.layer.masksToBounds = false
        
        inventoryView.layer.shadowOpacity = 0.7
        inventoryView.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        inventoryView.layer.shadowRadius = 4
        inventoryView.layer.shadowOffset = CGSize(width: 0, height: 8)
        inventoryView.layer.masksToBounds = false
        
        soldItemsView.layer.shadowOpacity = 0.7
        soldItemsView.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        soldItemsView.layer.shadowRadius = 4
        soldItemsView.layer.shadowOffset = CGSize(width: 0, height: 8)
        soldItemsView.layer.masksToBounds = false
        
        salesView.layer.shadowOpacity = 0.7
        salesView.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        salesView.layer.shadowRadius = 4
        salesView.layer.shadowOffset = CGSize(width: 0, height: 8)
        salesView.layer.masksToBounds = false
        
        addItemButton.layer.shadowOpacity = 0.7
        addItemButton.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        addItemButton.layer.shadowRadius = 1
        addItemButton.layer.shadowOffset = CGSize(width: -1, height: 1)
        addItemButton.layer.masksToBounds = false
        
        recordSaleButton.layer.shadowOpacity = 0.7
        recordSaleButton.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        recordSaleButton.layer.shadowRadius = 1
        recordSaleButton.layer.shadowOffset = CGSize(width: -1, height: 1)
        recordSaleButton.layer.masksToBounds = false
        
        inventoryButton.layer.shadowOpacity = 0.7
        inventoryButton.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        inventoryButton.layer.shadowRadius = 1
        inventoryButton.layer.shadowOffset = CGSize(width: -1, height: 1)
        inventoryButton.layer.masksToBounds = false
        
        soldItemsButton.layer.shadowOpacity = 0.7
        soldItemsButton.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        soldItemsButton.layer.shadowRadius = 1
        soldItemsButton.layer.shadowOffset = CGSize(width: -1, height: 1)
        soldItemsButton.layer.masksToBounds = false
        
        settingsButton.layer.shadowOpacity = 0.7
        settingsButton.layer.shadowColor = UIColor(rgb: 0x1d3557).cgColor
        settingsButton.layer.shadowRadius = 1
        settingsButton.layer.shadowOffset = CGSize(width: -1, height: 1)
        settingsButton.layer.masksToBounds = false
    }
    
    func configureColors() {
        view.backgroundColor = UIColor(named: "Background")
        bannerView.backgroundColor = UIColor(named: "Background")
        contentView.backgroundColor = UIColor(named: "Background")
        profitView.backgroundColor = UIColor(named: "Foreground")
        inventoryView.backgroundColor = UIColor(named: "Foreground")
        soldItemsView.backgroundColor = UIColor(named: "Foreground")
        salesView.backgroundColor = UIColor(named: "Foreground")
        
        inventoryButton.backgroundColor = UIColor(named: "Background")
        soldItemsButton.backgroundColor = UIColor(named: "Background")
        addItemButton.backgroundColor = UIColor(named: "Background")
        recordSaleButton.backgroundColor = UIColor(named: "Background")
        settingsButton.backgroundColor = UIColor(named: "Foreground")
        
        titleLabel.textColor = UIColor(named: "Text")
        
        inventoryButton.setTitleColor(UIColor(named: "Text"), for: .normal)
        soldItemsButton.setTitleColor(UIColor(named: "Text"), for: .normal)
        addItemButton.tintColor = UIColor(named: "Text")
        recordSaleButton.tintColor = UIColor(named: "Text")
        settingsButton.setTitleColor(UIColor(named: "Text"), for: .normal)
        
        if itemController.calculateProfit() > 0 {
            profitLabel.textColor = .systemGreen
        } else if itemController.calculateProfit() < 0 {
            profitLabel.textColor = .systemRed
        } else {
            profitLabel.textColor = .white
        }
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddItemSegue" {
            guard let addItemVC = segue.destination as? AddItemViewController else { return }
            addItemVC.itemController = itemController
            addItemVC.delegate = self
        } else if segue.identifier == "SettingsSegue" {
            guard let settingsVC = segue.destination as? SettingsViewController else { return }
            settingsVC.itemController = itemController
            settingsVC.delegate = self
            settingsVC.eraseDelegate = self
        }
    }

}

// MARK: - Protocol methods

extension DashboardViewController: AddItemViewControllerDelegate, ItemControllerDelegate, InventoryDelegate, EditItemDelegate, SettingsDelegate {
    
    func itemWasEdited() {
        updateViews()
    }

    func saleWasMade() {
        updateViews()
    }

    func itemWasDeleted() {
        updateViews()
    }

    func itemWasAdded() {
        updateViews()
    }
    
    func dataWasErased() {
        updateViews()
    }

}
