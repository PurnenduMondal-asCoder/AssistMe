import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SymbolCommunication extends StatefulWidget {
  const SymbolCommunication({super.key});

  @override
  State<SymbolCommunication> createState() => _SymbolCommunicationState();
}

class _SymbolCommunicationState extends State<SymbolCommunication> {
  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, dynamic>> predefinedSymbols = [
    {"image": "assets/image/water.jpg", "message": "I want to drink water", "userAdded": false},
    {"image": "assets/image/eat_food.jpg", "message": "I am hungry", "userAdded": false},
    {"image": "assets/image/Sleep.png", "message": "I want to sleep", "userAdded": false},
    {"image": "assets/image/Home.png", "message": "I want to go to my home", "userAdded": false},
    {"image": "assets/image/Medicine .png", "message": "I need my medicine", "userAdded": false},
    {"image": "assets/image/toilet.png", "message": "I need to use the toilet", "userAdded": false},
    {"image": "assets/image/headache.jpg", "message": "I have a headache", "userAdded": false},
    {"image": "assets/image/pain.png", "message": "I am in pain", "userAdded": false},
    {"image": "assets/image/music.png", "message": "I want to listen to music", "userAdded": false},
    {"image": "assets/image/TV.png", "message": "Please turn on the TV", "userAdded": false},
    {"image": "assets/image/Cold.png", "message": "I am feeling cold", "userAdded": false},
    {"image": "assets/image/hot.png", "message": "I am feeling hot", "userAdded": false},
    {"image": "assets/image/happy.png", "message": "I am happy", "userAdded": false},
    {"image": "assets/image/sad.png", "message": "I am feeling sad", "userAdded": false},
    {"image": "assets/image/Outside.png", "message": "I want to go outside", "userAdded": false},
    {"image": "assets/image/call.png", "message": "Can someone come here?", "userAdded": false},
    {"image": "assets/image/Thankyou.png", "message": "Thank you very much", "userAdded": false},
    {"image": "assets/image/Help.png", "message": "Please call someone for help", "userAdded": false},
  ];

  List<Map<String, dynamic>> userSymbols = [];
  List<Map<String, dynamic>> get allSymbols => [...predefinedSymbols, ...userSymbols];

  @override
  void initState() {
    super.initState();
    loadUserSymbols();
  }

  Future<void> loadUserSymbols() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString('user_symbols');
    if (storedData != null) {
      List decoded = jsonDecode(storedData);
      setState(() {
        userSymbols = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> saveUserSymbols() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_symbols', jsonEncode(userSymbols));
  }

  void speak(String message) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saying: "$message"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.lightBlue.shade200,
      ),
    );
  }

  void showAddEditSymbolDialog({Map<String, dynamic>? symbol, int? index}) async {
    final messageController = TextEditingController(text: symbol?['message'] ?? '');
    String? imagePath = symbol?['image'];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(symbol == null ? 'Add New Symbol' : 'Edit Symbol'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setStateDialog(() {
                        imagePath = image.path;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Upload Image'),
                ),
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: imagePath.toString().startsWith("assets/")
                        ? Image.asset(imagePath!, height: 80)
                        : Image.file(File(imagePath!), height: 80),
                  ),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (e.g., Please call my doctor)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final message = messageController.text.trim();
                  if (message.isNotEmpty && imagePath != null) {
                    final newSymbol = {
                      "image": imagePath!,
                      "message": message,
                      "userAdded": true,
                    };
                    setState(() {
                      if (symbol == null) {
                        userSymbols.add(newSymbol);
                      } else {
                        userSymbols[index!] = newSymbol;
                      }
                      saveUserSymbols();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(symbol == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        elevation: 4,
        centerTitle: true,
        title: const Text(
          'Symbol  Communication',
          
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            
          ),
        ),
         shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: allSymbols.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
          ),
          itemBuilder: (context, index) {
            final symbol = allSymbols[index];
            final imagePath = symbol["image"];
            final userAdded = symbol["userAdded"] == true;

            Widget imageWidget;
            if (imagePath != null && imagePath.toString().startsWith("assets/")) {
              imageWidget = Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.contain);
            } else if (imagePath != null) {
              imageWidget = Image.file(File(imagePath), width: 60, height: 60, fit: BoxFit.contain);
            } else {
              imageWidget = const Icon(Icons.image, size: 60);
            }

            return InkWell(
              onTap: () => speak(symbol["message"]),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB2EBF2), Color(0xFFE0F7FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(2, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: imageWidget,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              symbol["message"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF004D40),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (userAdded)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showAddEditSymbolDialog(symbol: symbol, index: index - predefinedSymbols.length);
                            } else if (value == 'delete') {
                              setState(() {
                                userSymbols.removeAt(index - predefinedSymbols.length);
                                saveUserSymbols();
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          icon: const Icon(Icons.more_vert, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditSymbolDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
