import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class HomeScreen3 extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen3({super.key, required this.user});

  @override
  ConsumerState<HomeScreen3> createState() => _HomeScreenState2();
}

class _HomeScreenState2 extends ConsumerState<HomeScreen3> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final Map<String, Map<String, dynamic>> _cache = {};
  final List<String> _order = []; // sorted by lastMessageAt desc

  bool _loading = true;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // _initAndListen();
  }

  Future<void> _initAndListen() async {
    try {
      // 1) Initial fetch
      final initial = await MessageHandlers().fetchInitialInbox(
        myid: widget.user.id,
      );

      _cache.clear();
      _order.clear();

      for (final doc in initial.docs) {
        _cache[doc.id] = doc.data();
        _order.add(doc.id);
      }

      _sortOrder();

      setState(() {
        _loading = false;
        _hasError = false;
        _error = null;
      });

      // 2) Listen + apply only changes
      _sub = MessageHandlers().listeningInbox(myId: widget.user.id).listen((
        snapshot,
      ) {
        bool changed = false;

        for (final c in snapshot.docChanges) {
          final id = c.doc.id;
          final data = c.doc.data();
          if (data == null) continue;

          switch (c.type) {
            case DocumentChangeType.added:
              if (_cache.containsKey(id)) break;
              _cache[id] = data;
              _order.add(id);
              changed = true;
              break;

            case DocumentChangeType.modified:
              _cache[id] = data;
              if (!_order.contains(id)) _order.add(id);
              changed = true;
              break;

            case DocumentChangeType.removed:
              _cache.remove(id);
              _order.remove(id);
              changed = true;
              break;
          }
        }

        if (changed) {
          _sortOrder();
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _error = e;
      });
    }
  }

  void _sortOrder() {
    // sort by lastMessageAt desc (newest chat on top)
    _order.sort((a, b) {
      final ad = _cache[a];
      final bd = _cache[b];

      final at = ad?['lastMessageAt'];
      final bt = bd?['lastMessageAt'];

      DateTime toDateTime(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is String)
          return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final aTime = toDateTime(at);
      final bTime = toDateTime(bt);

      return bTime.compareTo(aTime);
    });
  }

  @override
  void dispose() {
    print("DISPOSEEEEEEEEEEEEEEEEEEEE");
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (_order.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('No chats yet')),

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PhoneSearchBottomSheet(),
            ),
            child: const Icon(Icons.search),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("HOME 3 (${widget.user.phone}) - (${widget.user.id})"),
      ),
      body: ListView.separated(
        itemCount: _order.length,
        separatorBuilder: (_, __) => const Divider(height: 0.2),
        itemBuilder: (context, index) {
          final chatId = _order[index];
          final chat = _cache[chatId]!;

          return ChatElement(
            chatId: chatId,
            title: 'test',
            user: widget.user,
            lastMessage: chat['lastMessageText'],
            lastMessageAt: chat['lastMessageAt'],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PhoneSearchBottomSheet(),
          ),
          child: const Icon(Icons.search),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
