import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flyer_chat_file_message/flyer_chat_file_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:test_firebase/firebase/firestore/services/group/index.dart';
import 'package:test_firebase/firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firebase/storage/index.dart';
import 'package:test_firebase/riverpod/providers.dart';
import 'package:test_firebase/screens/ChatGallery.dart';
import 'package:test_firebase/screens/MediaViewerScreen.dart';
import 'package:test_firebase/widgets/AddParticipantsDialog.dart';
import 'package:test_firebase/widgets/ShowParticipants.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen5 extends ConsumerStatefulWidget {
  final AppUser user;
  final String chatId;
  final String title;

  const ChatScreen5({
    super.key,
    required this.user,
    required this.chatId,
    required this.title,
  });

  @override
  ConsumerState<ChatScreen5> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen5> {
  final _chatController = InMemoryChatController();
  types.TextMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    // _initController();

    // Use addPostFrameCallback to ensure ref is ready and provider is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  void _initController() async {
    // We read the provider once to get the current cached data
    // final initialData = ref.read(
    //   chatMessagesProvider(widget.chatId),
    // ); // Here getting error

    // if (initialData.hasValue) {
    //   _chatController.setMessages(initialData.value!, animated: false);
    // }

    // 2. FIXED: Access the value properly from the AsyncValue
    final messagesAsync = ref.read(chatMessagesProvider(widget.chatId));

    // messagesAsync.whenData((messages) {
    //   _chatController.setMessages(messages, animated: false);
    // });

    if (messagesAsync.hasValue) {
      _chatController.setMessages(messagesAsync.value!, animated: false);
    }
  }

  void _confirmLeaveGroup(BuildContext context, String chatId, String userId) {
    // 1. CAPTURE the screen's Navigator and Ref before entering the dialog/async zone
    final navigator = Navigator.of(context);
    final rootRef = ref; // 'ref' from your ConsumerState

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Group?"),
        content: const Text(
          "You will no longer receive messages from this group.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Close dialog
              Navigator.pop(context);

              await leaveGroup(chatId, userId);

              // 4. Use the CAPTURED navigator and ref
              // We don't check 'dialogContext.mounted' because that context is gone.
              // We use the captured navigator which still points to the main app stack.

              if (navigator.mounted) {
                rootRef.read(bottomNavIndexProvider.notifier).state = 0;
                navigator.popUntil((route) => route.isFirst);

                ScaffoldMessenger.of(navigator.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "You left the group",
                      style: TextStyle(
                        color: Theme.of(
                          navigator.context,
                        ).colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text("Leave", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOptionsModal(
    BuildContext context,
    String chatId,
    String chatTitle,
    List<AppUser> allFriends,
    List<AppUser> currentParticipants,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  chatTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Show files"),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatGalleryScreen(chatId: widget.chatId),
                    ),
                  );
                },
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Show participants"),

                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => ShowParticipantsDialog(
                      chatId: widget.chatId,
                      currentParticipants: currentParticipants,
                    ),
                  );

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                ),
                title: const Text(
                  "Add user",
                  style: TextStyle(color: Colors.blue),
                ),
                subtitle: const Text("Add new participants to the chat."),
                onTap: () async {
                  // 2. Show the dialog
                  await showDialog(
                    context: context,
                    builder: (context) => AddParticipantsDialog(
                      chatId: widget.chatId,
                      allFriends: allFriends,
                      currentParticipants: currentParticipants,
                    ),
                  );

                  Navigator.pop(context); // Close modal
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.exit_to_app_outlined,
                  color: Colors.red,
                ),
                title: const Text("Leave this chat"),
                onTap: () {
                  Navigator.pop(context);

                  _confirmLeaveGroup(context, widget.chatId, widget.user.id);
                },
              ),

              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
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
          _chatController.setMessages(next.value, animated: false); // true
        }
      },
    );

    // 2. WATCH for the initial status (Loading/Error)
    // We don't use the 'data' here to build the list directly because
    // the Chat widget uses the controller instead.
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final friends =
        ref.watch(friendsProvider(widget.user.id)).value ??
        []; // Bur gadna tald n baij bgaad param-r orj ireh ??
    final participants =
        ref.watch(participantProfilesProvider(widget.chatId)).value ?? [];

    // Watch the profiles map
    // final profilesAsync = ref.watch(chatProfilesProvider(widget.chatId));

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
              onPressed: () {
                _showOptionsModal(
                  context,
                  widget.chatId,
                  widget.title,
                  friends,
                  participants,
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
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                error: (error, stackTrace) =>
                    Center(child: Text('Error shu sda: $error')),
                data: (_) {
                  // 3. THE CRITICAL FIX: Wrap the Chat widget in a Provider.
                  // This ensures that when the Hero "flies" back, the
                  // FlyerChatImageMessage can still find the ChatController.

                  return Chat(
                    chatController: _chatController,
                    currentUserId: widget.user.id,
                    builders: _buildersChat(),
                    onMessageLongPress: _handleMessageLongPress,
                    resolveUser: (id) {
                      return Future.value(
                        types.User(id: id, name: "Loading..."),
                      );
                    }, // Usually fetched from DB
                    onAttachmentTap: _handleAttachmentTap,
                    onMessageSend: _handleMessageSend,
                    onMessageTap:
                        (context, message, {required details, required index}) {
                          if (message is types.ImageMessage) {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => FullScreenImage(
                            //       uri: message.source,
                            //       messageId: message.id,
                            //     ),
                            //   ),
                            // );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaViewerScreen(
                                  uri: message.source,
                                  isImage: true,
                                  fileName: message.source,
                                ),
                              ),
                            );
                          }

                          if (message is types.FileMessage) {
                            print('File message bnshu');
                          }
                        },
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
      fileMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return FlyerChatFileMessage(message: message, index: index);
          },
      imageMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return Hero(
              tag: message.id,
              key: ValueKey('hero-${message.id}'),

              child: FlyerChatImageMessage(
                message: message,
                index: index, //ValueKey(message.id),
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
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      String downloadUrl = await uploadImage(widget.chatId, file.path);

      if (downloadUrl != '') {
        MessageFunctions().sendFileMessage(
          chatId: widget.chatId,
          sender: widget.user,
          filename: file.path,
          uri: downloadUrl,
          size: result.files.single.size,
        );
      }
    }
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
