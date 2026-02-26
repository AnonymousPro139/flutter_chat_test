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
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen3 extends ConsumerStatefulWidget {
  final AppUser user;
  final String chatId;

  const ChatScreen3({super.key, required this.user, required this.chatId});

  @override
  ConsumerState<ChatScreen3> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen3> {
  final _chatController = InMemoryChatController();
  final ImagePicker _picker = ImagePicker();
  types.TextMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Initialize the controller once outside of the build loop
    // so the UI doesn't "flicker" on the first load.
    _initController();
  }

  void _initController() async {
    // We read the provider once to get the current cached data
    final initialData = ref.read(chatMessagesProvider(widget.chatId));
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
        // next.whenData((messages) {
        //   _chatController.setMessages(messages, animated: true);
        // });

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
        appBar: AppBar(title: const Text("Chat 3")),
        body: Column(
          children: [
            Text("Logged user: ${widget.user.phone} (${widget.user.id})"),
            Text(" chatId: ${widget.chatId}"),

            if (_replyingTo != null)
              ReplyPreview(
                message: _replyingTo!,
                onCancel: () => setState(() => _replyingTo = null),
              ),

            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error shu sda: $error')),
                data: (_) {
                  return Chat(
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
    return Builders(
      textMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) =>
              FlyerChatTextMessage(
                message: message,
                index: index,
                receivedBackgroundColor: Theme.of(context).primaryColorLight,
              ),
      imageMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) =>
              FlyerChatImageMessage(message: message, index: index),
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
      senderId: widget.user.id,
      text:
          'https://randomimageurl.com/assets/images/local/2026...png', // Replace with Storage URL
      type: 'file',
    );
  }

  Future<void> _handleMessageSend(String text) async {
    MessageFunctions().sendMessage(
      chatId: widget.chatId,
      senderId: widget.user.id,
      text: text,
      // Pass the reply context if needed for your database design:
      // replyToMessageId: _replyingTo?.id,
    );

    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }
  }
}
