chats
└── chatId
├── participants: [uid1, uid2]
├── lastMessage
├── lastMessageTime
└── messages (subcollection)
└── messageId
├── senderId
├── text
├── timestamp

                Optional Message Widget Packages

Opinionated packages for rendering different message types. You can also build your own!

flyer_chat_text_message: Renders text messages with markdown support.
flyer_chat_text_stream_message: Renders streamed text messages with markdown and fade-in animation support.
flyer_chat_image_message: Renders image messages.
flyer_chat_file_message: Renders file messages.
flyer_chat_system_message: Renders system messages (e.g., user joined).
