  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart'; // Importing intl package for date formatting
  import 'package:uuid/uuid.dart'; // Importing uuid package for unique ID generation

  class Messages extends StatefulWidget {
    final String uid;
    final String busId;

    const Messages({
      Key? key,
      required this.uid,
      required this.busId,
    }) : super(key: key);

    @override
    _MessagesState createState() => _MessagesState();
  }

  class _MessagesState extends State<Messages> {
    final TextEditingController _messageController = TextEditingController();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    late String _sessionId; // This will hold the session ID based on uid and busId
    late CollectionReference _messagesRef;

    @override
    void initState() {
      super.initState();
      _messagesRef = _firestore.collection('Messages');
      _sessionId = "${widget.busId}_${widget.uid}"; // Unique session ID based on busId and uid
      _initializeChatSession();
    }

    void _initializeChatSession() async {
      DocumentReference chatSessionRef = _messagesRef.doc(_sessionId);
      DocumentSnapshot chatDoc = await chatSessionRef.get();

      if (!chatDoc.exists) {
        await chatSessionRef.set({
          'uid': widget.uid,
          'busId': widget.busId,
          'check': "False",
        });
      }
    }

    void _sendMessage() {
      if (_messageController.text.isNotEmpty) {
        CollectionReference chatMessagesRef = _messagesRef.doc(_sessionId).collection('chatMessages');

        // Determine the sender based on the uid
        String sender = widget.uid == "PassengerID" ? "Passenger" : "Conductor"; // Adjust "PassengerID" to the actual ID for passengers

        chatMessagesRef.add({
          'uid': widget.uid,
          'busId': widget.busId,
          'message': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'sender': "Passenger", // Add sender field
        });
        _messageController.clear();
      }
    }

    String _formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) {
        return "Just now";
      }
      return DateFormat('hh:mm a').format(timestamp.toDate());
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesRef
                    .doc(_sessionId)
                    .collection('chatMessages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages yet.'));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index];

                      Timestamp? timestamp = messageData['timestamp'] as Timestamp?;
                      String formattedTime = _formatTimestamp(timestamp);
                      final isPassenger = messageData['sender'] == "Passenger"; // Check the sender

                      return Align(
                        alignment: isPassenger ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: isPassenger ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isPassenger ? Colors.blue : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                  messageData['message'],
                                  style: TextStyle(
                                    color: isPassenger ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
