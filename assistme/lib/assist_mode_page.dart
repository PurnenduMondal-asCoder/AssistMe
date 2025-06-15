import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'main.dart';
import 'memory_gallery.dart';
import 'pick_mode_page.dart';

class AssistModePage extends StatefulWidget {
  const AssistModePage({super.key});

  @override
  State<AssistModePage> createState() => _AssistModePageState();
}

class _AssistModePageState extends State<AssistModePage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int? _hoveredIndex;
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int? _playingVideoIndex;
  bool _isVideoInitializing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), 
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  Future<void> _initializeVideoPlayer(String videoPath) async {
    try {
      // Dispose previous controllers if they exist
      await _disposeVideoControllers();

      setState(() => _isVideoInitializing = true);

      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: const Color.fromARGB(255, 236, 224, 224),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Failed to load video',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _playVideo(_playingVideoIndex!, videoPath),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      // Handle full screen exit
      _chewieController!.addListener(() {
        if (!_chewieController!.isFullScreen && !mounted) {
          _disposeVideoControllers();
        }
      });

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    }
  }

  Future<void> _disposeVideoControllers() async {
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  Future<void> _playVideo(int index, String videoPath) async {
    if (_playingVideoIndex == index && _videoController != null) {
      if (_videoController!.value.isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
      setState(() {});
      return;
    }

    setState(() => _playingVideoIndex = index);
    await _initializeVideoPlayer(videoPath);
  }

  void _stopVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.seekTo(Duration.zero);
    }
    setState(() => _playingVideoIndex = null);
  }

  @override
  void dispose() {
    _disposeVideoControllers();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Dispose video controllers when back button is pressed
        await _disposeVideoControllers();
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Assist Mode',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black54,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await _disposeVideoControllers();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 202, 213, 197)),
              onSelected: (value) async {
                switch (value) {
                  case 'home':
                    await _disposeVideoControllers();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PickModePage()),
                      );
                    }
                  //   break;
                  // case 'gallery':
                  //   await _disposeVideoControllers();
                  //   if (mounted) {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const MemoryGallery()),
                  //     );
                  //   }
                    break;
                  case 'help':
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Help'),
                        content: const Text(
                          'This is the Assist Mode. Here you can learn how to use each feature of the app through interactive tutorials. '
                          'Tap on the play icons to watch demonstration videos for each feature.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'home',
                  child: ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Go to Home'),
                  ),
                ),
                // const PopupMenuItem<String>(
                //   value: 'gallery',
                //   child: ListTile(
                //     leading: Icon(Icons.photo_library),
                //     title: Text('Memory Gallery'),
                //   ),
                // ),
                const PopupMenuItem<String>(
                  value: 'help',
                  child: ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Help'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003366), Color(0xFF336699)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.3, 0.7],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome to Assist Mode',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Learn how to use the app step by step. Below are the main features and their usage instructions:',
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Text-to-Speech
                            _buildFeatureTile(
                              index: 0,
                              icon: Icons.text_fields,
                              title: "1. Text-to-Speech",
                              description: "Convert your typed text into clear, spoken words. Navigate to the Text-to-Speech page, type your message, and tap 'Speak'.",
                              hasVideo: true,
                              videoPath: "assets/videos/tts_demo.mp4",
                            ),

                            // Symbol Communication
                            _buildFeatureTile(
                              index: 1,
                              icon: Icons.emoji_symbols,
                              title: "2. Symbol Communication",
                              description: "Use visual symbols to express needs, feelings, or actions. Select a symbol and let the app communicate for you.",
                              hasVideo: true,
                              videoPath: "assets/videos/symbols_demo.mp4",
                            ),

                            // Voice Recording
                            _buildFeatureTile(
                              index: 2,
                              icon: Icons.mic,
                              title: "3. Voice Recording",
                              description: "Record your voice and save it with a label for easy identification. Quickly access and play pre-recorded messages for faster communication.",
                              hasVideo: true,
                              videoPath: "assets/videos/recording_demo.mp4",
                            ),

                            // Emergency Alert
                            _buildFeatureTile(
                              index: 3,
                              icon: Icons.emergency,
                              title: "Emergency Alert",
                              description: "Immediate help with one tap sends your location to emergency contacts.",
                              hasVideo: true,
                              videoPath: "assets/videos/emergency_demo.mp4",
                            ),

                            // Navigation
                            _buildFeatureTile(
                              index: 4,
                              icon: Icons.navigation,
                              title: "Navigation",
                              description: "Easily switch between modes using the main menu. All features are just a tap away.",
                              hasVideo: false,
                              onTap: () {},
                            ),

                            // Memory Gallery
                            _buildFeatureTile(
                              index: 5,
                              icon: Icons.photo_library,
                              title: "Memory Gallery",
                              description: "Capture the beauty of the past and organize it with care, so every glance brings warmth to your heart.",
                              hasVideo: false,
                              onTap: () async {
                                await _disposeVideoControllers();
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MemoryGallery()),
                                  );
                                }
                              },
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF003366),
                                size: 32,
                              ),
                            ),

                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Get Started!',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Follow the steps and explore each mode to enhance your communication experience.',
                                    style: TextStyle(
                                      fontSize: 16, 
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 14),
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF003366),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 6,
                                        shadowColor: Colors.black45,
                                      ),
                                      onPressed: () async {
                                        await _disposeVideoControllers();
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const HomePage()),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.swap_horiz, size: 24),
                                      label: const Text("Switch to Standard Mode"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    bool hasVideo = false,
    String? videoPath,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _hoveredIndex == index
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _hoveredIndex == index
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon, 
                          color: const Color(0xFF003366), 
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.black87.withOpacity(0.8),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasVideo)
                        _isVideoInitializing && _playingVideoIndex == index
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF003366),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  _playingVideoIndex == index && 
                                  _videoController != null &&
                                  _videoController!.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: const Color(0xFF003366),
                                  size: 32,
                                ),
                                onPressed: () => _playVideo(index, videoPath!),
                              ),
                      if (!hasVideo && trailing != null) 
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: trailing,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_playingVideoIndex == index && hasVideo)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: _chewieController != null && 
                          _chewieController!.videoPlayerController.value.isInitialized
                        ? Chewie(controller: _chewieController!)
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading AssistMe Tutorial',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _stopVideo,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AssistMe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}