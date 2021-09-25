//
//  ChatViewController.swift
//  Chat Pubnub Tutorial
//
//  Created by Muhammad Rajab Priharsanto on 23/09/21.
//

import UIKit
import MessageKit
import PubNub

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}
 
class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    let currentUser = Sender(senderId: "CURRENT_SENDER_ID", displayName: "CURRENT_USER_NAME")
    let otherUser = Sender(senderId: "DESTINATION_SENDER_ID", displayName: "DESTINATION_USER_NAME")
    let historian = PubNubHistorian(historyChannel: "CHANNEL_DESTINATION_NAME")
    
    //array history chat, ambil dari database atau backend
    var messages = [MessageType]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupMockUpChat()
        getChatHistory()
        setupDelegate()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        historian.fetchLast10()
//
//        let date = NSNumber(value: (1 as CUnsignedLongLong))
//        historian.historyNewerThen(date, withCompletion: { (messageHistory) in
//            self.messages.append(Message(sender: self.currentUser,
//                                    messageId: "1",
//                                    sentDate: Date().addingTimeInterval(-86400),
//                                    kind: .text(messageHistory.first as! String)))
//        })
//    }
    
    func getChatHistory() {
        historian.fetchLast10()
        
//        var timeMinus = 0
//        var id = 0
//        for textMessage in historian.textArray {
//            timeMinus += 10000
//            id += 1
//            messages.append(Message(sender: currentUser,
//                                    messageId: "\(id)",
//                                    sentDate: Date().addingTimeInterval(TimeInterval(-86400+timeMinus)),
//                                    kind: .text(textMessage)))
//        }
        
        //Dipanggil setelah datanya keluar dari history message, ada jeda waktunya.
        //Kalo datanya belum keluar selama delay 1 detik, bubble chatnya gak keluar.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.messages = self.historian.messages
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom(animated: false)
        })
        
    }
    
    func setupMockUpChat() {
        messages.append(Message(sender: currentUser,
                                messageId: "1",
                                sentDate: Date().addingTimeInterval(-86400),
                                kind: .text("Hello World")))
        
        messages.append(Message(sender: otherUser,
                                messageId: "2",
                                sentDate: Date().addingTimeInterval(-76400),
                                kind: .text("How is it going")))
        
        messages.append(Message(sender: currentUser,
                                messageId: "3",
                                sentDate: Date().addingTimeInterval(-66400),
                                kind: .text("here is a long reply. here is a long reply. here is a long reply.")))
        
        messages.append(Message(sender: otherUser,
                                messageId: "4",
                                sentDate: Date().addingTimeInterval(-56400),
                                kind: .text("Look it works")))
        
        messages.append(Message(sender: currentUser,
                                messageId: "5",
                                sentDate: Date().addingTimeInterval(-46400),
                                kind: .text("I love making apps. I love making apps. I love making apps.")))
        
        messages.append(Message(sender: otherUser,
                                messageId: "6",
                                sentDate: Date().addingTimeInterval(-26400),
                                kind: .text("And this is the last message!")))
    }
    
    func setupDelegate() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class PubNubHistorian: NSObject {
    let client: PubNub
    let historyChannel: String
    var textArray: [String] = []
    var messages = [MessageType]()
    
    required init(historyChannel: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let clientPublish = appDelegate.clientSetUp

        self.client = clientPublish
        self.historyChannel = historyChannel
        super.init()
    }
    
    //Get the last 10 messages.
    func fetchLast10() {
        self.client.historyForChannel(self.historyChannel, start: nil, end: nil, limit: 10, reverse: false, withCompletion: { (result, status) in
            if status == nil {
                print(result?.data.messages ?? "")
                self.textArray = result?.data.messages as! [String]
                let text = result?.data.messages as! [String]
                /**
                Handle downloaded history using:
                result.data.start - oldest message time stamp in response
                result.data.end - newest message time stamp in response
                result.data.messages - list of messages
                */
                var timeMinus = 0
                var id = 0
                let currentUser = Sender(senderId: "CURRENT_SENDER_ID", displayName: "CURRENT_USER_NAME")
                for textMessage in text {
                    timeMinus += 10000
                    id += 1
                    self.messages.append(Message(sender: currentUser,
                                            messageId: "\(id)",
                                            sentDate: Date().addingTimeInterval(TimeInterval(-86400+timeMinus)),
                                            kind: .text(textMessage)))
                }
            } else {
                /**
                Handle message history download error. Check 'category' properly
                to find out possible reason because of which request did fail.
                Review 'errorData' property (which has PNErrorData data type) of status
                object to get additional information about issue.
                 
                Request can be resend using: status.retry()
                */
            }
        })
    }
    
    func historyNewerThen(_ date: NSNumber,
                          withCompletion closure: @escaping (Array<Any>) -> Void) {
        var msgs: Array<Any> = []
        self.historyNewerThen(date, withProgress: { (messages) in
            msgs.append(contentsOf: messages)
            if messages.count < 100 { closure (msgs)}
        })
    }
    
    private func historyNewerThen(_ date: NSNumber,
                                  withProgress closure: @escaping (Array<Any>) -> Void) {
        self.client.historyForChannel(self.historyChannel, start: nil, end: nil, limit: 10, reverse: false, withCompletion: {
            (result, status) in
            if status == nil {
                closure((result?.data.messages)!)
                if result?.data.messages.count == 100 {
                    self.historyNewerThen((result?.data.end)!, withProgress: closure)
                }
            } else {
                /**
                Handle message history download error. Check 'category' properly
                to find out possible reason because of which request did fail.
                Review 'errorData' property (which has PNErrorData data type) of status
                object to get additional information about issue.
                 
                Request can be resend using: status.retry()
                */
            }
        })
    }
}
