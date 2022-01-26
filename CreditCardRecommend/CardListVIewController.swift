//
//  CardListVIewController.swift
//  CreditCardRecommend
//
//  Created by LeeHsss on 2022/01/25.
//

import Foundation
import UIKit
import Kingfisher //이미지 url을 전달해서 이미지 표시
import FirebaseDatabase

class CardListViewController: UITableViewController {
    
    var ref: DatabaseReference! // Realtime Database를 가져올 수 있는 Reference -> Root 객체를 가져올 수 있는 ref
    
    var creditCardList: [CreditCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UITableView Cell Register
        
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
        ref = Database.database().reference() // Data Root 가져오기
        
        ref.observe(.value) { snapshot in // snapshot을 통해 data를 불러온다. 전체 데이터 읽기
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
                let cardList = Array(cardData.values)
                
                self.creditCardList = cardList.sorted { $0.rank < $1.rank }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch let error {
                print("Error: JSON Parsing", error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell", for: indexPath) as? CardListCell else { return UITableViewCell()}
        
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = "\(creditCardList[indexPath.row].name)"
        
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        cell.cardImageView.kf.setImage(with: imageURL)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 상세화면 전달
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let detailViewController = storyboard.instantiateViewController(withIdentifier: "CardDetailViewController") as? CardDetailViewController else { return }
        
        detailViewController.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.show(detailViewController, sender: nil)
        
        // Option1 Write Data
        let cardID = creditCardList[indexPath.row].id
//        ref.child("Item\(cardID)/isSelected").setValue(true) // 데이터 쓰기
        
        // Option2
        // "id"라는 key의 value가 cardID와 일치한 객체를 snapshot으로 전달 snapshot은 Any형태이기 때문에 딕셔너리 형태로 변환필요
        ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self] snapshot in
            guard let self = self,
            let value = snapshot.value as? [String: [String: Any]],
            let key = value.keys.first else { return }

            self.ref.child("\(key)/isSelected").setValue(true)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete Database
            
            // Option1: 경로를 알 때
            let cardID = creditCardList[indexPath.row].id
            ref.child("Item\(cardID)").removeValue()
            
            // Option2: 경로를 모를 때
//            ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self] snapshot in
//                guard let self = self,
//                      let value = snapshot.value as? [String: [String: Any]],
//                      let key = value.keys.first else { return }
//
//                self.ref.child(key).removeValue()
//            }
            
            
        }
    }
}


