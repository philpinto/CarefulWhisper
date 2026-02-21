import Testing
import Foundation
@testable import CarefulWhisper

@Suite("Message Tests")
struct MessageTests {
    
    @Test("Message initialization sets properties correctly")
    func testMessageInit() {
        let contact = Contact(displayName: "Alice", publicKey: Data(), peerId: "peer1")
        let conversation = Conversation(type: .oneToOne, participants: [contact])
        
        let message = Message(
            content: "Hello, World!",
            sender: contact,
            conversation: conversation,
            isFromMe: true
        )
        
        #expect(message.content == "Hello, World!")
        #expect(message.isFromMe == true)
        #expect(message.status == .sending)
        #expect(message.signalMessageType == .normal)
        #expect(message.sender?.displayName == "Alice")
    }
    
    @Test("Message default status is sending")
    func testDefaultStatus() {
        let contact = Contact(displayName: "Alice", publicKey: Data(), peerId: "peer1")
        let conversation = Conversation(type: .oneToOne, participants: [contact])
        let message = Message(content: "Test", sender: contact, conversation: conversation, isFromMe: true)
        
        #expect(message.status == .sending)
    }
}
