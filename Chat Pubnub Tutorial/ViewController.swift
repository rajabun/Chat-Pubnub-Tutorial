//
//  ViewController.swift
//  Chat Pubnub Tutorial
//
//  Created by Muhammad Rajab Priharsanto on 23/09/21.
// Sumber : https://medium.com/@shabashiki/how-to-use-pubnub-in-your-swift-application-90aa873e0c79

import UIKit
import PubNub // <- Here is our PubNub module import.

class ViewController: UIViewController {

    // Stores reference on PubNub client to make sure what it won't be released.
//    var client: PubNub!
    
    @IBOutlet weak var publishLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var chatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpPubNub()
        setUpTableView()
        setUpTextField()
    }

    func setUpPubNub() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let clientSetUp = appDelegate.clientSetUp
        
        // Initialize and configure PubNub client instance
//        let configuration = PNConfiguration(publishKey: "YOUR_PUBLISH_KEY", subscribeKey: "YOUR_SUBSCRIBE_KEY")
//        configuration.stripMobilePayload = false
//        clientSetUp = PubNub.clientWithConfiguration(configuration)
        clientSetUp.addListener(self)
        
        // Subscribe to demo channel with presence observation
        clientSetUp.subscribeToChannels(["CHANNEL_DESTINATION_NAME"], withPresence: true)
    }
    
    func setUpTableView() {
        chatTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        chatTableView.delegate = self
        chatTableView.dataSource = self
    }
    
    func setUpTextField() {
        inputTextField.delegate = self
//        self.dismissKeyboard()
    }
    
    @IBAction func publishButton(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let clientPublish = appDelegate.clientSetUp
        
        guard let publishString = inputTextField.text else {
            return
        }
        
        clientPublish.publish(publishString, toChannel: "CHANNEL_DESTINATION_NAME") { (status) in
            if !status.isError {
                //Message was successfully published
                let successText = "SUCCESS sending text"
                self.statusLabel.text = successText
                print(successText)
            } else {
                //Handle message publish error.
                //Request can be resent using: status.retry()
                print("Error publishing message: \(status)")
            }
        }

    }
}

extension ViewController: PNEventsListener {
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        //Unwrap message payload.
        guard let receivedMessage = message.data.message else {
            print("default value")
            return
        }
        publishLabel.text = receivedMessage as? String
        print("Received message: \(receivedMessage), on channel \(message.data.subscription ?? "") " + "at time \(message.data.timetoken)")
    }
    
    func client(_ client: PubNub, didReceive status: PNStatus) {
        print("STATUSNYA STRING CATEGORY =", status.stringifiedCategory())
        print("STATUSNYA STRING OPERATION =", status.stringifiedOperation())
        print("STATUSNYA CATEGORY =", status.category)
        print("STATUSNYA NOMOR =", status.category.rawValue)
        
        statusLabel.text = status.stringifiedCategory()
        
        switch status.category.rawValue {
        case 6:
            print("BERHASIL WOY")
        default:
            print("GAGAL WOY")
        }
        
        switch status.stringifiedCategory() {
        case "Connected":
            print("BERHASIL DUA KALI WOY")
        default:
            print("BERHASIL WOY")
        }
    }
    
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        print("STATUSNYA EVENT DATA =", event.data)
        print("STATUSNYA EVENT PRESENCE =", event.data.presence)
        print("STATUSNYA EVENT STATE =", event.data.presence.state ?? [])
    }
}

extension ViewController: UITextFieldDelegate {
    func dismissKeyboard()
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.viewTapped(gestureRecognizer:)))
        
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer)
    {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        return true
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "John Smith"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Show Chat Messages
        let vc = ChatViewController()
        vc.title = "Chat"
        navigationController?.pushViewController(vc, animated: true)
    }
}
