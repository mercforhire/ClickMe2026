//
//  ChattingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class ChattingViewModel: ObservableObject {

    // MARK: Identity
    let peerName: String
    let peerAvatarURL: String
    let myAvatarURL: String
    let myName: String

    // MARK: View state
    @Published var items: [ChatItem]
    @Published var messageText: String
    @Published var showMenu: Bool
    @Published var selectedPhoto: PhotosPickerItem?

    init(
        peerName: String = "Dr. Olivia Bennett",
        peerAvatarURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        myAvatarURL: String = "https://randomuser.me/api/portraits/men/32.jpg",
        myName: String = "Ethan",
        items: [ChatItem] = ChatItem.sampleConversation,
        messageText: String = "",
        showMenu: Bool = false,
        selectedPhoto: PhotosPickerItem? = nil
    ) {
        self.peerName = peerName
        self.peerAvatarURL = peerAvatarURL
        self.myAvatarURL = myAvatarURL
        self.myName = myName
        self.items = items
        self.messageText = messageText
        self.showMenu = showMenu
        self.selectedPhoto = selectedPhoto
    }

    // MARK: Actions

    func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(.message(ChatMessage(
                sender: .me, senderName: myName, body: trimmed, avatarURL: myAvatarURL
            )))
        }
        messageText = ""
    }
}
