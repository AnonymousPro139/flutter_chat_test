import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';

import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';
import 'package:test_firebase/widgets/replyPreview.dart';
import 'package:test_firebase/models/user.dart';

class ChatScreen2 extends ConsumerStatefulWidget {
  final AppUser user;
  final String chatId;

  const ChatScreen2({super.key, required this.user, required this.chatId});

  @override
  ConsumerState<ChatScreen2> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen2> {
  final _chatController = InMemoryChatController();
  final ImagePicker _picker = ImagePicker();
  types.TextMessage? _replyingTo;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _initialized = false;

  final Map<String, Message> _cacheById = {};
  final List<String> _orderedIds = [];

  @override
  void initState() {
    super.initState();

    _sub = MessageHandlers().listeningChat(chatId: widget.chatId).listen((
      snapshot,
    ) {
      print(
        "DOCC LENGTH!: ${snapshot.docChanges.length} ${snapshot.docs.length}",
      );

      // First event is often a full batch of "added" docs.
      if (!_initialized) {
        _cacheById.clear();
        _orderedIds.clear();

        for (final d in snapshot.docs) {
          final msg = MessageUtils().mapDocToMessage(d);

          _cacheById[msg.id] = msg;
          _orderedIds.add(msg.id);
        }

        print("Initialized _orderedIds: ${_orderedIds.length}");

        _chatController.setMessages(
          _orderedIds.map((id) => _cacheById[id]!).toList(),
          animated: false,
        );
        _initialized = true;
        return;
      }

      // bool changed = false;

      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        // doc can be QueryDocumentSnapshot in docChanges too, but keep it safe: as QueryDocumentSnapshot<Map<String, dynamic>>,
        if (doc.data() == null) continue;

        final msg = MessageUtils().mapDocToMessage2(doc);

        switch (change.type) {
          case DocumentChangeType.added:
            print("DocumentChangeType added ++ ${doc.data()}");

            if (_cacheById.containsKey(msg.id)) break;

            // _cacheById[msg.id] = msg;

            // If your query is descending, new items should typically be inserted at index 0
            // Use Firestore's newIndex if it’s stable for your query.

            // final insertAt = change.newIndex.clamp(0, _orderedIds.length);
            // final insertAt = change.newIndex.clamp(0, _orderedIds.length);

            // _orderedIds.insert(insertAt, msg.id);

            // _orderedIds.add(msg.id);

            // If your controller supports it, prefer insertMessage(msg).
            // But safest is to re-set with animated:false when indices might shift.
            // changed = true;

            _chatController.insertMessage(msg);

            break;

          case DocumentChangeType.modified:
            // _cacheById[msg.id] = msg;

            // print('MODIFIED');
            // If order might change (createdAt updated from null->serverTimestamp),
            // use Firestore indexes to move it.
            // final oldI = change.oldIndex;
            // final newI = change.newIndex;

            // if (oldI != newI &&
            //     oldI >= 0 &&
            //     oldI < _orderedIds.length &&
            //     newI >= 0) {
            //   final id = _orderedIds.removeAt(oldI);

            //   _orderedIds.insert(newI.clamp(0, _orderedIds.length), id);
            // }

            // changed = true;
            break;

          case DocumentChangeType.removed:
            // print("REMOVED!!!!!!!!!!!!!!!!!! ${_orderedIds.length} ${msg.id}");

            // _cacheById.remove(msg.id);
            // _orderedIds.remove(msg.id);

            // print("REMOVED!!!!!!!!!!!!!!!!!! ${_orderedIds.length}");

            // changed = true;
            break;
        }
      }

      print("PROCESSING _orderedIds: ${_orderedIds.length}");

      // if (changed) {
      //   _chatController.setMessages(
      //     _orderedIds.map((id) => _cacheById[id]!).toList(),
      //     animated: false, // keeps SliverAnimatedList stable
      //   );
      // }

      // Update controller OUTSIDE of build.
      // _chatController.setMessages(msgs, animated: false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Chat 2")),
        body: Column(
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
                currentUserId: widget.user.id,
                builders: Builders(
                  textMessageBuilder:
                      (
                        context,
                        message,
                        index, {
                        required isSentByMe,
                        groupStatus,
                      }) => FlyerChatTextMessage(
                        message: message,
                        index: index,
                        receivedBackgroundColor: Theme.of(
                          context,
                        ).primaryColorLight,
                      ),
                  imageMessageBuilder:
                      (
                        context,
                        message,
                        index, {
                        required isSentByMe,
                        groupStatus,
                      }) =>
                          FlyerChatImageMessage(message: message, index: index),
                ),
                onMessageLongPress:
                    (context, message, {required details, required index}) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: const Text('Reply'),
                              onTap: () {
                                Navigator.of(context).pop();

                                if (message is TextMessage) {
                                  setState(() => _replyingTo = message);
                                } else {
                                  // ignore or show "Reply only supports text"
                                }
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
                      );
                    },
                resolveUser: (id) async {
                  // IMPORTANT: return SAME id you were asked for
                  return User(id: id, name: 'John Doe');
                },
                onAttachmentTap: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (image == null) return;

                  MessageFunctions().sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.user.id,
                    text:
                        'https://randomimageurl.com/assets/images/local/20260103_0519_Random%20Natural%20Landscape_simple_compose_01ke205qahfmftrexg9rs7svjn.png',
                    type: 'file',
                  );
                },
                onMessageSend: (text) async {
                  MessageFunctions().sendMessage(
                    chatId: widget.chatId,
                    senderId: widget.user.id,
                    text: text,
                  );

                  if (_replyingTo != null) {
                    setState(() => _replyingTo = null);
                  }
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
