//
//  ViewController.swift
//  M17
//
//  Created by Jonathan Abercrombie on 10/15/20.
//

import UIKit
import Alamofire
import Kingfisher

class ViewController: UIViewController {

    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var users: [[String: Any]] = [[String: Any]]()
    var usersView: UICollectionView!
    var loading = false
    var query = ""
    var page = 1
    let pageSize = 30
    var nextCell: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        input.placeholder = "Enter a keyword to search GitHub users"
        input.delegate = self
    }

    func fetchUsers(query: String, completion: @escaping ([[String: Any]]?) -> Void) {
        let url = URL(string: "https://api.github.com/search/users")!
        AF.request(url, method: .get, parameters: ["q": query, "page": page, "per_page": pageSize]).validate(statusCode: 200..<300).responseJSON { [unowned self] response in
            guard let value = response.value as? [String: Any], let users = value["items"] as? [[String: Any]] else {
                print("Bad data received from \(url)")
                completion(nil)
                return
            }
            self.page += 1
            completion(users)
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
        cell.backgroundColor = .lightGray

        if let string = users[indexPath.row]["avatar_url"] as? String, let url = URL(string: string) {
            DispatchQueue.main.async {
                cell.avatar.kf.setImage(with: url)
            }
        }

        cell.username.text = users[indexPath.row]["login"] as? String
        cell.username.textColor = .white

        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 2
        let padding = insets.left * (itemsPerRow + 1)
        let remainingWidth = collectionView.frame.width - padding
        var width = remainingWidth / itemsPerRow
        var height: CGFloat

        let randomLayout = Int.random(in: 0..<3)
        if randomLayout == 0 || nextCell == "1x1" {
            height = width
            if nextCell == "1x1" {
                nextCell = nil
            } else {
                nextCell = "1x1"
            }
        } else if randomLayout == 1 {
            width = width * 2 + insets.left
            height = width / 2
        } else {
            width = width * 2 + insets.left
            height = width
        }
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return insets.left
    }
}

extension ViewController { // Pagination
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == self.users.count - 1 && !loading {
            loading = true
            fetchUsers(query: self.query, completion: { [unowned self] users in
                self.loading = false
                guard let users = users else {
                    print("No users were returned.")
                    return
                }
                let oldCount = self.users.count
                self.users.append(contentsOf: users)

                var paths = [IndexPath]()
                for index in 0..<users.count {
                    let path = IndexPath(row: index+oldCount, section: 0)
                    paths.append(path)
                }
                self.collectionView.insertItems(at: paths)
            })
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            self.query = text
            self.page = 1
            fetchUsers(query: text, completion: { [unowned self] users in
                guard let users = users else {
                    print("No users were returned.")
                    return
                }
                self.users = users
                self.collectionView.reloadData()
            })
        }
        textField.resignFirstResponder()
        return true
    }
}

