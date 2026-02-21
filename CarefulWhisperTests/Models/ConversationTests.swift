import Testing
import Foundation
@testable import CarefulWhisper

@Suite("Conversation Tests")
struct ConversationTests {
    
    @Test("Conversation initialization sets properties correctly")
    func testConversationInit() {
        let contact1 = Contact(displayName: "Alice", publicKey: Data(), peerId: "peer1")
        let contact2 = Contact(displayName: "Bob", publicKey: Data(), peerId: "peer2")
        
        let conversation = Conversation(
            type: .oneToOne,
            participants: [contact1, contact2]
        )
        
        #expect(conversation.type == .oneToOne)
        #expect(conversation.participants.count == 2)
        #expect(conversation.messages.isEmpty)
        #expect(conversation.lastMessageAt == nil)
    }
    
    @Test("Last message computed property returns most recent message")
    func testLastMessage() {
        let contact = Contact(displayName: "Alice", publicKey: Data(), peerId: "peer1")
        let conversation = Conversation(type: .oneToOne, participants: [contact])
        
        let message1 = Message(content: "First", sender: contact, conversation: conversation, isFromMe: true)
        let message2 = Message(content: "Second", sender: contact, conversation: conversation, isFromMe: true)
        let message3 = Message(content: "Third", sender: contact, conversation: conversation, isFromMe: true)
        
        conversation.messages = [message1, message2, message3]
        
        // Last message should be the one with the most recent timestamp
        let lastMsg = conversation.lastMessage
        #expect(lastMsg != nil)
        #expect(lastMsg?.content == "Third")
    }
}
