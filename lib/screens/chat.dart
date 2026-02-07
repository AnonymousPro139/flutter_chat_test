import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firestore/services/message/listeners.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const ChatScreen({super.key, required this.user});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _chatController = InMemoryChatController();

  types.TextMessage? _replyingTo;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    // _subscription = FirebaseFirestore.instance
    //     .collection('channels')
    //     .doc("123")
    //     .collection('messages')
    //     .orderBy('createdAt', descending: false)
    //     .startAfter([DateTime.now()])
    //     .snapshots()
    //     .listen((snapshot) {
    //       for (final change in snapshot.docChanges) {
    //         final doc = change.doc;
    //         // Map Firestore doc -> types.Message (adjust to your mapper)
    //         final msg = firestoreToTextMessage2(doc);

    //         switch (change.type) {
    //           case DocumentChangeType.added:
    //             // _handleAdded(change.newIndex, msg);
    //             break;
    //           case DocumentChangeType.modified:
    //             // _handleModified(change.oldIndex, change.newIndex, msg);
    //             break;
    //           case DocumentChangeType.removed:
    //             // _handleRemoved(change.oldIndex, id);
    //             break;
    //         }
    //       }

    //       final messages = snapshot.docs.map(firestoreToTextMessage).toList();

    //       print('msgs: $messages');

    //       _chatController.setMessages(messages);
    //     });

    startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void startListening() {
    _subscription = MessageListeners().listenToCollection(
      path: 'channels/1234/messages',
      onData: (snapshot) {
        final messages = snapshot.docs.map(firestoreToTextMessage).toList();

        print('msgs: $messages');

        _chatController.setMessages(messages);

        // Process only changes (incremental updates)
        for (var change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              print('New message: ${change.doc.data()}');
              break;
            case DocumentChangeType.modified:
              print('Modified message: ${change.doc.data()}');
              break;
            case DocumentChangeType.removed:
              print('Removed message: ${change.doc.id}');
              break;
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Text(
              "Chat Screen for user: ${widget.user.phone} (${widget.user.id})",
            ),
            if (_replyingTo != null)
              ReplyPreview(
                message: _replyingTo!,
                onCancel: () {
                  setState(() => _replyingTo = null);
                },
              ),
            Expanded(
              child: Chat(
                chatController: _chatController,
                builders: Builders(
                  textMessageBuilder:
                      (
                        context,
                        message,
                        index, {
                        required bool isSentByMe,
                        MessageGroupStatus? groupStatus,
                      }) =>
                          FlyerChatTextMessage(message: message, index: index),
                ),
                currentUserId: widget.user.id, //123
                backgroundColor: Color.fromARGB(255, 211, 29, 29),
                onMessageSend: (text) {
                  print('replying message to send: $_replyingTo');

                  MessageFunctions().writeMessage2("1234", {
                    "message": text,
                    "createdAt":
                        FieldValue.serverTimestamp(), //Always use server timestamps when writing messages: This avoids clock skew issues.
                    "senderId": widget.user.id,
                    "replyToMessageId": _replyingTo?.id,
                  });

                  if (_replyingTo != null) {
                    setState(() => _replyingTo = null);
                  }
                },
                onMessageLongPress:
                    (context, message, {required details, required index}) =>
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: const Text('Reply'),
                                onTap: () {
                                  Navigator.of(context).pop();

                                  setState(() {
                                    _replyingTo = message as TextMessage;
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text('Delete'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _chatController.deleteMessage(message);
                                },
                              ),
                            ],
                          ),
                        ),
                resolveUser: (id) async {
                  print("WHYYYYYYYYYYYYYYYYYYYYYYYYY NOT CALLED");
                  return User(id: '123', name: 'John SDSDSa ');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on InMemoryChatController {
  void deleteMessage(Message message) {
    print(" delete replying to message: $message");
  }
}
