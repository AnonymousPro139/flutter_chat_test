import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final AppUser user;
  final String chatId;

  const ChatScreen({super.key, required this.user, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _chatController = InMemoryChatController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _listenerChat;
  types.TextMessage? _replyingTo;

  Future<void> loadInitial() async {
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final msgs = snap.docs.map((d) {
      final data = d.data();

      return TextMessage(
        id: d.id,
        authorId: data['senderId'] as String,

        // createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
        createdAt: data['createdAt'] == null
            ? DateTime.now()
            : (data['createdAt'] is String
                  ? DateTime.parse(data['createdAt'])
                  : (data['createdAt'] as Timestamp).toDate()),
        text: (data['text'] ?? '') as String,
      );
    }).toList();

    _chatController.setMessages(msgs.reversed.toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listeningChat({
    required String chatId,
  }) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    loadInitial();
    _listenerChat = listeningChat(chatId: widget.chatId);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _listenerChat.drain();
    super.dispose();
  }

  // 1. get messages and put it into inital messages of chat controller
  // 2. listen messages and update chat controller when new message comes
  // 3. When close chat screen, dispose the stream subscription

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Chat")),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // initialData: initialSnap.data,
          stream: _listenerChat,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('No Messages yet GUYS!'));
            } else {
              final msgs = docs
                  .map((d) {
                    final data = d.data();

                    print('TIME: ${data['createdAt']}');

                    return TextMessage(
                      id: d.id,
                      authorId: data['senderId'] as String,
                      createdAt: data['createdAt'] == null
                          ? DateTime.now()
                          : (data['createdAt'] is String
                                ? DateTime.parse(data['createdAt'])
                                : (data['createdAt'] as Timestamp).toDate()),

                      text: (data['text'] ?? '') as String,
                    );
                  })
                  .toList()
                  .reversed
                  .toList();

              _chatController.setMessages(msgs);
            }

            return Column(
              children: [
                Text("Logged user: ${widget.user.phone} (${widget.user.id})"),
                Text(" chatId: ${widget.chatId}"),

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
                    // builders: Builders(
                    //   textMessageBuilder:
                    //       (
                    //         context,
                    //         message,
                    //         index, {
                    //         required bool isSentByMe,
                    //         MessageGroupStatus? groupStatus,
                    //       }) => FlyerChatTextMessage(
                    //         message: message,
                    //         index: index,
                    //       ),
                    // ),
                    currentUserId: widget.user.id,

                    onMessageSend: (text) async {
                      // print('replying message to send: $_replyingTo');

                      // End shaardlagagui !!!!
                      // String chatId = await MessageFunctions().createOrGetChat(
                      //   widget.user.id,
                      //   widget.otherUid,
                      // );

                      MessageFunctions().sendMessage2(
                        chatId: widget.chatId,
                        senderId: widget.user.id,
                        text: text,
                      );

                      if (_replyingTo != null) {
                        setState(() => _replyingTo = null);
                      }
                    },
                    onMessageLongPress:
                        (
                          context,
                          message, {
                          required details,
                          required index,
                        }) => showModalBottomSheet(
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
            );
          },
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
