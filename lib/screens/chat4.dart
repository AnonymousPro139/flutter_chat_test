import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/riverpod/providers.dart';
import 'package:test_firebase/widgets/AddParticipantsDialog.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen4 extends ConsumerStatefulWidget {
  final AppUser user;
  final String chatId;
  final String title;

  const ChatScreen4({
    super.key,
    required this.user,
    required this.chatId,
    required this.title,
  });

  @override
  ConsumerState<ChatScreen4> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen4> {
  final _chatController = InMemoryChatController();
  final ImagePicker _picker = ImagePicker();
  types.TextMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() async {
    // We read the provider once to get the current cached data
    final initialData = ref.read(
      chatMessagesProvider(widget.chatId),
    ); // Here getting error
    if (initialData.hasValue) {
      _chatController.setMessages(initialData.value!, animated: false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //1. LISTEN for changes only.
    // This handles the real-time "push" to the controller.
    ref.listen<AsyncValue<List<types.Message>>>(
      chatMessagesProvider(widget.chatId),
      (previous, next) {
        if (next is AsyncData<List<types.Message>>) {
          // animated: true allows the chat UI to slide new messages in nicely
          _chatController.setMessages(next.value, animated: true);
        }
      },
    );

    // 2. WATCH for the initial status (Loading/Error)
    // We don't use the 'data' here to build the list directly because
    // the Chat widget uses the controller instead.
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(widget.title[0].toUpperCase()),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Online", // Or fetch real status
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                // 1. Fetch your full friend list (from a provider or service)
                // final allFriends = ref.read(friendsProvider).value ?? [];
                final allFriends = [];

                // 2. Show the dialog
                final List<String>? selectedIds =
                    await showDialog<List<String>>(
                      context: context,
                      builder: (context) => AddMembersDialog(
                        allFriends: [],
                        // currentParticipants: widget
                        //     .chatParticipants, // Pass the current group list
                        currentParticipants: [],
                      ),
                    );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_replyingTo != null)
              ReplyPreview(
                message: _replyingTo!,
                onCancel: () => setState(() => _replyingTo = null),
              ),

            Expanded(
              child: messagesAsync.when(
                loading: () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading messages...",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                error: (error, stackTrace) =>
                    Center(child: Text('Error shu sda: $error')),
                data: (_) {
                  return Chat(
                    // theme: ChatTheme(colors: colors, typography: typography, shape: shape),
                    chatController: _chatController,
                    currentUserId: widget.user.id,
                    builders: _buildersChat(),

                    onMessageLongPress: _handleMessageLongPress,
                    resolveUser: (id) async => User(
                      id: id,
                      name: 'John Doe',
                    ), // Usually fetched from DB
                    onAttachmentTap: _handleAttachmentTap,
                    onMessageSend: _handleMessageSend,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Builders _buildersChat() {
    final colorScheme = Theme.of(context).colorScheme;

    return Builders(
      textMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return FlyerChatTextMessage(
              message: message,
              index: index,
              // --- Sent Message Style (Right Side) ---
              sentBackgroundColor: colorScheme.primary,
              sentTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              // --- Received Message Style (Left Side) ---
              receivedBackgroundColor: const Color.fromARGB(255, 245, 240, 240),
              receivedTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            );
          },
      systemMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            // Assuming you cast your Firestore data to Flyer's SystemMessage type
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.text, // e.g., "John joined the group"
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            );
          },
      imageMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlyerChatImageMessage(message: message, index: index),
              ),
            );
          },
    );
  }

  void _handleMessageLongPress(
    BuildContext context,
    types.Message message, {
    required details,
    required int index,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              if (message is types.TextMessage) {
                setState(() => _replyingTo = message);
              }
            },
          ),
          ListTile(
            title: const Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              // Make sure to delete from Firebase, not just local controller!
              // MessageFunctions().deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttachmentTap() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    // TODO: Upload `image.path` to Firebase Storage first to get a real URL!
    // Using a hardcoded URL for now.
    MessageFunctions().sendMessage(
      chatId: widget.chatId,
      sender: widget.user,
      text:
          'https://randomimageurl.com/assets/images/local/2026...png', // Replace with Storage URL
      type: 'file',
    );
  }

  Future<void> _handleMessageSend(String text) async {
    MessageFunctions().sendMessage(
      chatId: widget.chatId,
      sender: widget.user,
      text: text,
      // Pass the reply context if needed for your database design:
      // replyToMessageId: _replyingTo?.id,
    );

    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }
  }
}
