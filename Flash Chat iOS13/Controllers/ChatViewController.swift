//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        title = Constants.appName                                      // title for the chat screen
        navigationItem.hidesBackButton = true               // hides the back button the chat screen
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages() {
        db.collection(Constants.FStore.collectionName).order(by: Constants.FStore.dateField).addSnapshotListener { querySnapshot, error in       // showing the messages from the database on the screen
            self.messages = []
            if let e = error {
                print("There was an issue retreiving data from the FireStore. \(e)")
            } else {
                if let snapshotDocs = querySnapshot?.documents {        // holds the docs for the data array
                    for doc in snapshotDocs {
                        let data = doc.data()
                        if let messageSender = data[Constants.FStore.senderField] as? String, let messageBody = data[Constants.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {                  // since in closure, this gets it to the main thread
                                self.tableView.reloadData()             // reloading the table to see the actual msgs
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func sendPressed(_ sender: UIButton) {        // putting message on the database for a user
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            db.collection(Constants.FStore.collectionName).addDocument(data: [Constants.FStore.senderField: messageSender, Constants.FStore.bodyField: messageBody, Constants.FStore.dateField: Date().timeIntervalSince1970]) { error in                   // we add the timeInter. to order msgs by time
                if let e = error {
                    print("Issue saving data to the FireStore, \(e)")
                } else {
                    print("Successfully saved data.")
                }
            }
        }
    }
    
    @IBAction func logOut(_ sender: UIBarButtonItem) {
        do {                                                    // firebase signout can throw error. so need to manage that
          try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)           // this will pop all the view controllers on the stack and take back to the home page
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
      
    }
    
}

extension ChatViewController: UITableViewDataSource {                               // DataSourec protocol is responsible for populating the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count                                   // no. of rows is going to be the no. of messages in the msg array
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! MessageCell                                                        // using the MessageCell we created
        cell.label.text = messages[indexPath.row].body                         // sets the index to the index of the message in the messages array
        return cell
    }
}
