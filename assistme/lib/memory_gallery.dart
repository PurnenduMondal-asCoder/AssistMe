import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryGallery extends StatefulWidget {
  const MemoryGallery({super.key});

  @override
  State<MemoryGallery> createState() => _MemoryGalleryState();
}

class _MemoryGalleryState extends State<MemoryGallery> {
  final List<Map<String, dynamic>> _memories = [];
  final List<Map<String, dynamic>> _quotes = [
    {
      "text": "Memories are the treasures that we keep locked deep within",
      "author": "Disney"
    },
    {
      "text": "A moment lasts all of a second, but the memory lives on forever",
      "author": "Unknown"
    },
    {
      "text": "Life is a collection of moments, create beautiful ones",
      "author": "Unknown"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getStringList('memories') ?? [];

    setState(() {
      _memories.clear();
      for (final memoryStr in memoriesJson) {
        final memory = Map<String, dynamic>.from(jsonDecode(memoryStr));
        memory['image'] = File(memory['imagePath']);
        memory['date'] = DateTime.parse(memory['date']);
        _memories.add(memory);
      }
    });
  }

  Future<void> _saveMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = _memories.map((memory) {
      return jsonEncode({
        'imagePath': memory['image'].path,
        'label': memory['label'],
        'date': memory['date'].toIso8601String(),
      });
    }).toList();

    await prefs.setStringList('memories', memoriesJson);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _showAddMemoryDialog(pickedFile);
    }
  }

  Future<void> _showAddMemoryDialog(XFile pickedFile) async {
    final TextEditingController labelController = TextEditingController();
    final randomQuote = _quotes[DateTime.now().second % _quotes.length];

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 227, 234, 229),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '"${randomQuote['text']}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: const Color.fromARGB(255, 133, 180, 204),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "- ${randomQuote['author']}",
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(pickedFile.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Describe this memory',
                  hintText: 'What makes this special?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLength: 60,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (labelController.text.trim().isNotEmpty) {
                        _addMemory(pickedFile, labelController.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save Memory'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMemory(XFile imageFile, String label) {
    final memory = {
      'image': File(imageFile.path),
      'label': label,
      'date': DateTime.now(),
    };
    setState(() {
      _memories.insert(0, memory);
    });
    _saveMemories();
  }

  Future<void> _confirmDelete(int index) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever, size: 50, color: Colors.red[400]),
              SizedBox(height: 16),
              Text(
                'Delete this memory?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _memories.removeAt(index));
                      _saveMemories();
                      Navigator.pop(context);
                    },
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemoryDetail(Map<String, dynamic> memory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                memory['image'],
                fit: BoxFit.contain,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory['label'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _formatDate(memory['date']),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Memory Gallery', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 16, 38, 58),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(255, 220, 231, 165),
                  const Color.fromARGB(255, 125, 185, 234),
                ],
              ),
            ),
            child: _memories.isEmpty ? _buildEmptyState() : _buildMemoryGrid(),
          ),
          if (_memories.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _pickImage,
                backgroundColor: Colors.blue[600],
                elevation: 4,
                child: Icon(Icons.add_a_photo, size: 28),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final randomQuote = _quotes[DateTime.now().second % _quotes.length];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 80, color: Colors.blue[600]),
                    SizedBox(height: 24),
                    Text(
                      '"${randomQuote['text']}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "- ${randomQuote['author']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Add Your First Memory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryGrid() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: _memories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final memory = _memories[index];
          return GestureDetector(
            onTap: () => _showMemoryDetail(memory),
            child: Hero(
              tag: memory['image'].path,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.file(
                        memory['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory['label'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatDate(memory['date']),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _confirmDelete(index),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month-1]} ${date.day}, ${date.year}';
  }
}