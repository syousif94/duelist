//
//  WormholeManager.swift
//  DueList
//
//  Created by Sammy Yousif on 12/12/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import Foundation
import MMWormhole
import Disk

@objc(TodayManagerMessage)
class TodayManagerMessage: NSObject, NSCoding {
    
    enum MessageType: String {
        case refresh
        case reload
    }
    
    let messageType: MessageType
    
    init(messageType: MessageType) {
        self.messageType = messageType
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(messageType.rawValue, forKey: "messageType")
    }
    
    required init?(coder: NSCoder) {
        guard let messageTypeString = coder.decodeObject(forKey: "messageType") as? String,
            let messageType = MessageType(rawValue: messageTypeString)
            else { return nil }
        
        self.messageType = messageType
    }
}

class TodayManager {
    
    static let shared = TodayManager()
    
    let wormhole = MMWormhole(applicationGroupIdentifier: "group.me.syousif.DueList", optionalDirectory: "todayWormhole")
    
    func send(message: TodayManagerMessage.MessageType) {
        let messageObject = TodayManagerMessage(messageType: message)
        wormhole.passMessageObject(messageObject, identifier: "message")
    }
    
    func startListening(with handler: @escaping ((TodayManagerMessage) -> Void)) {
        wormhole.listenForMessage(withIdentifier: "message") { object in
            
            guard let object = object as? TodayManagerMessage else { return }
            
            handler(object)
        }
    }
}
