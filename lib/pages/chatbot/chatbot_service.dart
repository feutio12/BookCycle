import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isWaitingForResponse = false;
  bool _isFirstLoad = true;
  final FocusNode _focusNode = FocusNode();

  // Instance du modèle génératif Firebase AI
  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAI();
    _loadChatHistory();
  }

  Future<void> _initializeFirebaseAI() async {
    try {
      // Initialiser Firebase AI avec le modèle Gemini
      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
    } catch (e) {
      print("Erreur lors de l'initialisation de Firebase AI: $e");
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: "👋 Bonjour ! Je suis l'assistant BookCycle. Je peux vous aider à trouver des livres, expliquer le fonctionnement de l'application, ou répondre à vos questions. Comment puis-je vous aider aujourd'hui ?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    _saveMessage(welcomeMessage.text, false);
  }

  Future<void> _loadChatHistory() async {
    if (_user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('chatbot_chats')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final List<ChatMessage> loadedMessages = [];

      for (var doc in snapshot.docs.reversed) {
        final data = doc.data();
        loadedMessages.add(ChatMessage(
          text: data['text'] ?? '',
          isUser: data['isUser'] ?? false,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        ));
      }

      setState(() {
        _messages.addAll(loadedMessages);
        _isFirstLoad = false;
      });

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print("Erreur lors du chargement de l'historique: $e");
      setState(() {
        _isFirstLoad = false;
      });
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    }
  }

  Future<void> _saveMessage(String text, bool isUser) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('chatbot_chats')
          .add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print("Erreur lors de la sauvegarde du message: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Appeler l'API Firebase AI Gemini
  Future<String> _getBotResponse(String message) async {
    if (_model == null) {
      throw Exception("Modèle Firebase AI non initialisé");
    }

    try {
      // Préparer le prompt avec le contexte de BookCycle
      final prompt = "Tu es BookCycle Assistant, un chatbot utile et amical pour une application d'échange de livres appelée BookCycle. "
          "L'application permet aux utilisateurs d'échanger et vendre des livres d'occasion. "
          "Réponds toujours en français. Sois concis, utile et amical. "
          "Question de l'utilisateur: $message";

      // Générer la réponse avec le modèle Gemini
      final response = await _model!.generateContent([Content.text(prompt)]);

      return response.text ?? "Je comprends que vous dites: '$message'. En tant qu'assistant BookCycle, je suis là pour vous aider avec les livres et notre application. Pouvez-vous me dire ce dont vous avez besoin ?";
    } catch (e) {
      print("Erreur Firebase AI: $e");
      return "Merci pour votre message ! En tant qu'assistant BookCycle, je peux vous aider à trouver des livres, comprendre comment utiliser l'application, ou répondre à vos questions. Que souhaitez-vous savoir ?";
    }
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    // Ajouter le message de l'utilisateur
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isWaitingForResponse = true;
    });

    await _saveMessage(text, true);
    _scrollToBottom();

    try {
      // Obtenir la réponse du chatbot via Firebase AI
      String response = await _getBotResponse(text);

      final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isWaitingForResponse = false;
        _messages.add(botMessage);
      });

      await _saveMessage(response, false);
      _scrollToBottom();
    } catch (e) {
      print("Erreur détaillée: $e");

      final errorMessage = ChatMessage(
        text: "Je rencontre un petit problème technique. Pouvez-vous reformuler votre question ? 😊",
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isWaitingForResponse = false;
        _messages.add(errorMessage);
      });

      await _saveMessage(errorMessage.text, false);
      _scrollToBottom();
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 12.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF8B78FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Iconsax.book, color: Colors.white, size: 20),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Color(0xFF42A5F5)
                    : Color(0xFFF0F5FF),
                borderRadius: message.isUser
                    ? BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                )
                    : BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Color(0xFF1A1A1A),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: message.isUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 12.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF42A5F5).withOpacity(0.1),
                  border: Border.all(color: Color(0xFF42A5F5), width: 2),
                ),
                child: Icon(Iconsax.user, color: Color(0xFF42A5F5), size: 20),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Column(
        children: [
          // Header personnalisé
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  'assets/images/previous.png',
                  width: 40,
                  height: 40,
                  color: Color(0xFF42A5F5)
                ),
              ),
              title: Text(
                'Assistant BookCycle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white
                ),
                textAlign: TextAlign.center,
              ),
              trailing: IconButton(
                icon: Icon(Iconsax.info_circle, color: Color(0xFF1A1A1A)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("À propos"),
                      content: Text("BookCycle Assistant utilise Firebase AI avec le modèle Gemini pour répondre à vos questions sur notre application d'échange de livres."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK", style: TextStyle(color: Color(0xFF42A5F5))),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _isFirstLoad
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Chargement de la conversation...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isWaitingForResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessage(_messages[index]);
                } else {
                  // Indicateur de chargement pour la réponse du bot
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF8B78FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(Iconsax.book, color: Colors.white, size: 20),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'BookCycle réfléchit...',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          // Input area
          SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom < 0
                      ? MediaQuery.of(context).viewInsets.bottom : 16,
                  left: 16,
                  right: 16,
                  top: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Row(
                            children: [
                              SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  focusNode: _focusNode,
                                  onSubmitted: _handleSubmitted,
                                  decoration: InputDecoration(
                                    hintText: "Écrivez votre message...",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                                  maxLines: null,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Iconsax.emoji_happy, color: Color(0xFF42A5F5)),
                                onPressed: () {
                                  // Option pour ajouter des emojis
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF8B78FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF42A5F5).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Iconsax.send_2, color: Colors.white),
                        onPressed: () => _handleSubmitted(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}