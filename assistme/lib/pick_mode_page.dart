import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main.dart';
import 'assist_mode_page.dart';
import 'login.dart';
import 'profile_page.dart';
import 'navapp_overview.dart';

class PickModePage extends StatefulWidget {
  final bool openDrawer;
  const PickModePage({super.key, this.openDrawer = false});

  @override
  State<PickModePage> createState() => _PickModePageState();
}

class _PickModePageState extends State<PickModePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> emergencyNumbers = [];
  int? selectedNumberIndex;
  Position? _currentPosition;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyNumbers();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingLocation = true;
  });

  try {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final shouldOpenSettings = await _showLocationServiceDialog();
      if (shouldOpenSettings) {
        await Geolocator.openLocationSettings();
      }
      throw Exception('Location services disabled');
    }

    // 2. Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      final shouldOpenSettings = await _showPermissionSettingsDialog();
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      throw Exception('Location permissions permanently denied');
    }

    // 3. Try to get current position with fallbacks
    Position? position;
    
    // First try with high accuracy
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('High accuracy location failed: $e');
      // Fallback to lower accuracy if high accuracy fails
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));
    }

    // ignore: unnecessary_null_comparison
    if (position == null) {
      throw Exception('Could not get location');
    }

    setState(() {
      _currentPosition = position;
      _isGettingLocation = false;
    });
    
  } catch (e) {
    setState(() {
      _isGettingLocation = false;
    });
    debugPrint('Location error: $e');
    // Don't show error here - let the calling function handle it
    rethrow;
  }
}

Future<bool> _showLocationServiceDialog() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Location Services Required'),
      content: const Text('Emergency location sharing requires location services to be enabled.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enable'),
        ),
      ],
    ),
  ) ?? false;
}

Future<bool> _showPermissionSettingsDialog() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission Required'),
      content: const Text('Please enable location permissions in app settings for emergency location sharing.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  ) ?? false;
}

Future<void> _launchSMS(String number) async {
  String locationMessage = "";
  
  try {
    // Try to get location if we don't have it
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      locationMessage = "\n\n📍 My current location: https://www.google.com/maps?q=$lat,$lng";
    } else {
      // If we still don't have location, provide alternative instructions
      locationMessage = "\n\n⚠️ Could not share location automatically. "
          "Please describe your location or share manually: "
          "https://maps.google.com";
    }
  } catch (e) {
    debugPrint('Location error in SMS: $e');
    locationMessage = "\n\n⚠️ Could not share location automatically. "
        "Please describe your location or share manually: "
        "https://maps.google.com";
  }

  final message = '🚨 EMERGENCY! I need help immediately!$locationMessage';

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:$number',
      arguments: {'sms_body': message},
    );
    await intent.launch();
  } catch (_) {
    await _launchWhatsApp(number, message);
  }
}

  Future<void> _loadEmergencyNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emergencyNumbers = prefs.getStringList('emergencyNumbers') ?? [];
      selectedNumberIndex = prefs.getInt('selectedNumberIndex');
      if (selectedNumberIndex != null &&
          (selectedNumberIndex! < 0 || selectedNumberIndex! >= emergencyNumbers.length)) {
        selectedNumberIndex = null;
      }
    });
  }

  Future<void> _saveEmergencyNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergencyNumbers', emergencyNumbers);
    if (selectedNumberIndex != null) {
      await prefs.setInt('selectedNumberIndex', selectedNumberIndex!);
    } else {
      await prefs.remove('selectedNumberIndex');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.openDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openDrawer();
      });
    }
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchCall(String number) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$number',
      );
      await intent.launch();
    } catch (_) {
      try {
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showMessage(context, "Call feature not available.");
        }
      } catch (e) {
        _showMessage(context, "Failed to initiate call.");
      }
    }
  }

  Future<void> _launchWhatsApp(String number, [String? customMessage]) async {
    String cleanedNumber = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = cleanedNumber.substring(1);
    }
    if (!cleanedNumber.startsWith('+')) {
      cleanedNumber = '+$cleanedNumber';
    }

    String message = customMessage ?? "🚨 EMERGENCY! I need immediate help!";
    final whatsappUrl = 'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        await _launchSMS(number);
      }
    } catch (_) {
      await _launchSMS(number);
    }
  }

  void _showEmergencyOptions() {
    if (emergencyNumbers.isEmpty) {
      _showAddNumberDialog(fromEmergency: true);
      return;
    }

    if (selectedNumberIndex == null) {
      _showMessage(context, "Please select an emergency number first.");
      _showAddNumberDialog();
      return;
    }

    final number = emergencyNumbers[selectedNumberIndex!];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Emergency Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Selected number: $number', style: const TextStyle(fontSize: 16)),
            if (_isGettingLocation)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                    SizedBox(width: 10),
                    Text('Getting location...'),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyOptionButton(
                  icon: Icons.call,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _launchCall(number);
                  },
                ),
                _buildEmergencyOptionButton(
                  icon: Icons.message,
                  label: 'SMS',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _launchSMS(number);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddNumberDialog({bool fromEmergency = false}) {
    TextEditingController controller = TextEditingController();
    int? editingIndex;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> addOrUpdateNumber() async {
            final number = controller.text.trim();
            if (number.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a phone number")),
              );
              return;
            }

            if (editingIndex != null) {
              emergencyNumbers[editingIndex!] = number;
              editingIndex = null;
            } else {
              if (!emergencyNumbers.contains(number)) {
                emergencyNumbers.add(number);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Number already exists")),
                );
                return;
              }
            }

            controller.clear();
            setStateDialog(() {});
            await _saveEmergencyNumbers();
            setState(() {});
          }

          void startEdit(int index) {
            setStateDialog(() {
              editingIndex = index;
              controller.text = emergencyNumbers[index];
            });
          }

          void deleteNumber(int index) async {
            setStateDialog(() {
              if (editingIndex == index) {
                editingIndex = null;
                controller.clear();
              }
              emergencyNumbers.removeAt(index);
              if (selectedNumberIndex != null) {
                if (selectedNumberIndex == index) {
                  selectedNumberIndex = null;
                } else if (selectedNumberIndex! > index) {
                  selectedNumberIndex = selectedNumberIndex! - 1;
                }
              }
            });
            await _saveEmergencyNumbers();
            setState(() {});
          }

          void selectNumber(int? index) {
            setStateDialog(() {
              selectedNumberIndex = index;
            });
            _saveEmergencyNumbers();
            setState(() {});
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color.fromARGB(255, 232, 239, 233),
            title: const Text('Manage Emergency Numbers', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      suffixIcon: IconButton(
                        icon: Icon(editingIndex == null ? Icons.add_circle : Icons.check_circle, color: Colors.blue),
                        onPressed: addOrUpdateNumber,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 221, 223, 229),
                    ),
                    onSubmitted: (_) => addOrUpdateNumber(),
                  ),
                  const SizedBox(height: 24),
                  emergencyNumbers.isEmpty
                      ? const Text(
                          "No emergency numbers added yet.",
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                        )
                      : Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: emergencyNumbers.length,
                            itemBuilder: (context, index) {
                              final num = emergencyNumbers[index];
                              final isEditing = editingIndex == index;
                              final isSelected = selectedNumberIndex == index;

                              return Card(
                                elevation: isSelected ? 4 : 1,
                                color: isSelected ? const Color.fromARGB(255, 206, 212, 221) : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(color: const Color.fromARGB(255, 118, 161, 196), width: 2)
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      Radio<int>(
                                        value: index,
                                        groupValue: selectedNumberIndex,
                                        onChanged: selectNumber,
                                        activeColor: const Color.fromARGB(255, 47, 128, 39),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            num,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.grey[700]),
                                        onPressed: () {
                                          if (isEditing) {
                                            setStateDialog(() {
                                              editingIndex = null;
                                              controller.clear();
                                            });
                                          } else {
                                            startEdit(index);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => deleteNumber(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _customDrawerTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE6F7FF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 72, 68),
        title: const Text('                 AssistMe', style: TextStyle(color: Colors.white)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => _showMessage(context, 'No new notifications at the moment.'),
          ),
        ],
      ),
      drawer: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(child: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Drawer(child: Center(child: Text('User data not found.')));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = userData['name'] ?? 'User';

          return Drawer(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                color: const Color(0xFF0375F6),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $fullName',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Glad to have you onboard.', 
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _customDrawerTile(
                      icon: Icons.info_outline,
                      label: 'About App',
                      subtitle: 'Overview & Features',
                      color: const Color(0xFF1565C0),
                      backgroundColor: const Color(0xFFD0E8FF),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()))
                            .then((_) => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PickModePage(openDrawer: true)),
                                ));
                      },
                    ),
                    _customDrawerTile(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      subtitle: 'View & Edit Info',
                      color: const Color(0xFF1565C0),
                      backgroundColor: const Color(0xFFF0F8FF),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))
                            .then((_) => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PickModePage(openDrawer: true)),
                                ));
                      },
                    ),
                    _customDrawerTile(
                      icon: Icons.logout,
                      label: 'Log Out',
                      subtitle: 'Exit your session',
                      color: Colors.redAccent,
                      backgroundColor: const Color(0xFFFFEBEE),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
      body: SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/image/temp.png',
            height: 180,
            width: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'PICK YOUR MODE',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF002C5F),
            ),
          ),
          const SizedBox(height: 40),
          _buildModeButton(
            text: 'Assistive Mode',
            color1: const Color(0xFF42A5F5),
            color2: const Color(0xFF1E88E5),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistModePage())),
          ),
          const SizedBox(height: 20),
          _buildModeButton(
            text: 'Standard Mode',
            color1: const Color(0xFF66BB6A),
            color2: const Color(0xFF43A047),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  ),
),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB3A34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  onPressed: _showEmergencyOptions,
                  child: const Text(
                    'EMERGENCY', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_call, color: Colors.white),
                onPressed: () => _showAddNumberDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String text,
    required VoidCallback onTap,
    required Color color1,
    required Color color2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1, color2]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color.fromARGB(255, 237, 213, 213), 
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}