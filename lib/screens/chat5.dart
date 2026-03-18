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
import 'package:test_firebase/const.dart';
import 'package:test_firebase/crypto/chacha.dart';
import 'package:test_firebase/firebase/firestore/services/group/index.dart';
import 'package:test_firebase/firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/firebase/storage/index.dart';
import 'package:test_firebase/localstorage/index.dart';
import 'package:test_firebase/riverpod/providers.dart';
import 'package:test_firebase/screens/ChatGallery2.dart';
import 'package:test_firebase/screens/MediaViewerScreen.dart';
import 'package:test_firebase/widgets/AddParticipantsDialog.dart';
import 'package:test_firebase/widgets/Dialog.dart';
import 'package:test_firebase/widgets/ReactionsDialog.dart';
import 'package:test_firebase/widgets/ShowParticipants.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen5 extends ConsumerStatefulWidget {
  final AppUser me;
  final String chatId;
  final String title;
  final String idPubKey;
  final String epPubKey;
  final String spPubKey;

  const ChatScreen5({
    super.key,
    required this.me,
    required this.chatId,
    required this.title,

    required this.idPubKey,
    required this.epPubKey,
    required this.spPubKey,
  });

  @override
  ConsumerState<ChatScreen5> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen5> {
  final _chatController = InMemoryChatController();
  types.TextMessage? _replyingTo;
  ({String sending, String receiving})? _sessionKeys;

  @override
  void initState() {
    super.initState();

    // _initialize();
    // // Use addPostFrameCallback to ensure ref is ready and provider is active
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _initController();
    // });

    // Call the async wrapper, but don't await it (since initState can't be async)
    _runStartupSequence();
  }

  Future<void> _runStartupSequence() async {
    // 1. Await the initialization to ensure _sessionKeys is fully populated
    await _initialize();

    // 2. CRITICAL: Always check if the widget is still mounted after an `await`
    // If the user navigates away before _initialize finishes, this prevents crashes.
    if (!mounted) return;

    // 3. Now it is 100% safe to initialize your controller and use ref.read
    _initController();
  }

  Future<void> _initialize() async {
    // 2. Read the manager from Riverpod and get the key
    final manager = ref.read(sessionProvider);

    final keys = await manager.getSharedSecretKeys(
      chatId: widget.chatId,
      otherIdPubKey: widget.idPubKey,
      otherEphPubKey: widget.epPubKey,
      otherSPpubKey: widget.spPubKey,
    );

    // 3. Update the UI state so you can start decrypting messages
    setState(() {
      _sessionKeys = keys;
    });
  }

  void _initController() async {
    final messagesAsync = ref.read(
      chatMessagesProvider((
        chatId: widget.chatId,
        myId: widget.me.id,

        receivingKey: _sessionKeys!.receiving,
        sendingKey: _sessionKeys!.sending,
      )),
    );

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

                context.showCustomSnackBar("You left the group");
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
                leading: const Icon(Icons.image),
                title: const Text("Show files"),

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatGalleryScreen2(
                        chatId: widget.chatId,
                        me: widget.me,
                        sessionKeys: _sessionKeys!,
                      ),
                    ),
                  );
                },
              ),

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

                  _confirmLeaveGroup(context, widget.chatId, widget.me.id);
                },
              ),
              const Divider(),

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
    // 1. Guard clause: If keys are not ready, show a loading screen.
    if (_sessionKeys == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen<AsyncValue<List<types.Message>>>(
      chatMessagesProvider((
        chatId: widget.chatId,
        myId: widget.me.id,
        receivingKey: _sessionKeys!.receiving,
        sendingKey: _sessionKeys!.sending,
      )),
      (previous, next) {
        if (next is AsyncData<List<types.Message>>) {
          // animated: true allows the chat UI to slide new messages in nicely
          _chatController.setMessages(next.value, animated: false); // true
        }
      },
    );

    final messagesAsync = ref.watch(
      chatMessagesProvider((
        chatId: widget.chatId,
        myId: widget.me.id,
        receivingKey: _sessionKeys!.receiving,
        sendingKey: _sessionKeys!.sending,
      )),
    );

    final friends =
        ref.watch(friendsProvider(widget.me.id)).value ??
        []; // Bur gadna tald n baij bgaad param-r orj ireh ??
    final participants =
        ref.watch(participantProfilesProvider(widget.chatId)).value ?? [];

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
                    "Send: ${_sessionKeys?.sending.substring(0, 12)}", // Or fetch real status
                    style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                  ),
                  Text(
                    "Rec: ${_sessionKeys?.receiving.substring(0, 12)}", // Or fetch real status
                    style: TextStyle(fontSize: 10, color: Colors.red[600]),
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
                  return Chat(
                    chatController: _chatController,
                    currentUserId: widget.me.id,
                    builders: _buildersChat(),
                    // onMessageLongPress: _handleMessageLongPress,
                    onMessageLongPress: _handleSecondaryTap,
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaViewerScreen(
                                  uri: message.source,
                                  isImage: true,
                                  fileName: message.source,
                                  isCache: true,
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

  Widget _buildReactionsUI(types.Message message, bool isSentByMe) {
    // 1. If there are no reactions, draw nothing.
    if (message.reactions == null || message.reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. Draw the emojis!
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 12, right: 12, bottom: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        // Align to the right for your messages, left for others
        alignment: isSentByMe ? WrapAlignment.end : WrapAlignment.start,
        children: message.reactions!.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;
          // Check if the current user clicked this emoji so we can highlight it
          final didIReact = entry.value.contains(widget.me.id);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: didIReact
                  ? Theme.of(context).primaryColor.withOpacity(0.15)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: didIReact
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                // Only show the number if more than 1 person reacted
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: didIReact
                          ? Theme.of(context).primaryColor
                          : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Builders _buildersChat() {
    final colorScheme = Theme.of(context).colorScheme;

    return Builders(
      textMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return Column(
              crossAxisAlignment: isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FlyerChatTextMessage(
                  message: message,
                  index: index,
                  sentBackgroundColor: colorScheme.primary,
                  sentTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  receivedBackgroundColor: const Color.fromARGB(
                    255,
                    245,
                    240,
                    240,
                  ),
                  receivedTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // ADD THE REACTIONS HERE!
                _buildReactionsUI(message, isSentByMe),
              ],
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
            // return FlyerChatFileMessage(message: message, index: index);

            return Column(
              crossAxisAlignment: isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FlyerChatFileMessage(message: message, index: index),
                // ADD THE REACTIONS HERE!
                _buildReactionsUI(message, isSentByMe),
              ],
            );
          },
      imageMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return Hero(
              tag: message.id,
              key: ValueKey('hero-${message.id}'),

              // child: FlyerChatImageMessage(
              //   message: message,
              //   index: index, //ValueKey(message.id),
              // ),
              child: Column(
                crossAxisAlignment: isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlyerChatImageMessage(
                    message: message,
                    index: index, //ValueKey(message.id),
                  ),
                  // ADD THE REACTIONS HERE!
                  _buildReactionsUI(message, isSentByMe),
                ],
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

  Future<void> _handleSecondaryTap(
    BuildContext context,
    types.Message message, {
    required details,
    required int index,
  }) async {
    final selectedEmoji = await showReactionsDialog(context);

    // 3. If the user tapped outside the sheet or didn't pick anything, stop here.
    if (selectedEmoji == null) return;

    // 4. Apply the selected emoji to the message
    _toggleReaction(message, selectedEmoji);

    // MyDialogs().showSnackBar(
    //   context,
    //   "Please wait, You're reacted ${selectedEmoji} with this message.",
    // );

    context.showCustomSnackBar(
      "Please wait, You're reacted ${selectedEmoji} with this message!",
    );
  }

  Future<void> _toggleReaction(types.Message message, String emojiType) async {
    final currentUserId = widget.me.id;

    // 1. Grab the current reactions directly from the message object.
    // We make a deep copy of the map so we can safely modify it.
    final Map<String, List<String>> currentReactions = {};

    if (message.reactions != null) {
      message.reactions!.forEach((key, value) {
        currentReactions[key] = List<String>.from(value);
      });
    }

    // 2. Get the list of users who have already reacted with this specific emoji.
    // If no one has used this emoji yet, we start with an empty list.
    final List<String> usersWhoReacted = currentReactions[emojiType] ?? [];

    // 3. Toggle logic!
    if (usersWhoReacted.contains(currentUserId)) {
      // TOGGLE OFF: The user already clicked this emoji, so we remove their ID.
      usersWhoReacted.remove(currentUserId);

      if (usersWhoReacted.isEmpty) {
        // Clean up: If they were the only person to use this emoji,
        // completely remove the emoji key from the map so we don't have an empty bubble.
        currentReactions.remove(emojiType);
      } else {
        currentReactions[emojiType] = usersWhoReacted;
      }
    } else {
      // TOGGLE ON: The user hasn't clicked this emoji yet, so we add their ID.
      usersWhoReacted.add(currentUserId);
      currentReactions[emojiType] = usersWhoReacted;
    }

    try {
      // 4. Update Firestore
      // Note: We are saving this to the 'reactions' field at the root of the document,
      // which matches how we parsed `data['reactions']` in the previous step.
      await FirestoreService().firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(message.id)
          .update({'reactions': currentReactions});
    } catch (e) {
      print('Failed to update reaction: $e');
    }
  }

  Future<void> _handleAttachmentTap() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // 1. Grab the original file
      File originalFile = File(result.files.single.path!);
      // File fileName = result.files.single.name;

      // --- NEW: THE MAGIC COMPRESSION STEP ---
      // This will silently shrink photos. Non-photos are returned untouched.
      File fileToProcess = await LocalStorageService().compressImageIfNeeded(
        originalFile,
      );

      // Recalculate the size AFTER compression
      int finalSizeBytes = await fileToProcess.length();

      // int fileSizeInBytes = result.files.single.size;

      // 3. The Guard Clause: Check and prevent large files
      if (finalSizeBytes > maxFileSize) {
        // Use the SnackBar extension we talked about earlier!
        context.showCustomSnackBar(
          'File is too large. Please select a file under 3 MB.',
          isError: true,
        );

        return; // STOP EXECUTION HERE. The rest of the function will not run.
      }

      context.showWaitSnackBar('Please wait, encrypting file and sending...');

      // File file = File(result.files.single.path!);

      final bytes = await ChaCha20().encryptFile(
        // inputFile: file,
        inputFile: fileToProcess,
        ssk: _sessionKeys!.sending,
      );

      final String fname;

      if (LocalStorageService().isImage(
        LocalStorageService().getExtension(result.files.single.name),
      )) {
        fname =
            "${LocalStorageService().getFileNameWithoutExt(result.files.single.name)}_${LocalStorageService().getSimpleRandom()}.jpg";
      } else {
        fname =
            "${LocalStorageService().getSimpleRandom()}_${result.files.single.name}";
      }

      String downloadUrl = await FbStorage().uploadImage2(
        widget.chatId,
        bytes,
        fname,
      );

      if (downloadUrl != '') {
        MessageFunctions().sendFileMessage(
          chatId: widget.chatId,
          sender: widget.me,
          filename: fname,
          uri: downloadUrl,
          // size: result.files.single.size,
          size: finalSizeBytes,
        );
        context.showWaitSnackBar('File sent successfully', isLoading: false);
      } else {
        context.showWaitSnackBar(
          'Failed to send file!',
          isLoading: false,
          isError: true,
        );
      }
    }
  }

  Future<void> _handleMessageSend(String text) async {
    final encrypted = await ChaCha20().encrypt(text, _sessionKeys!.sending);

    MessageFunctions().sendMessage(
      chatId: widget.chatId,
      sender: widget.me,
      text: encrypted,
      // text: text,
      // Pass the reply context if needed for your database design:
      // replyToMessageId: _replyingTo?.id,
    );

    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }
  }
}
