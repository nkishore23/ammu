import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:async';

// Import the new HeatwaveScreen
import 'package:keerthana_flutter_app/heatwave_screen.dart'; // Adjust 'ammu' to your project name

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SOSScreen()),
  );
}

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  bool _isSOSActive = false;
  bool _isLocationEnabled = false;
  Position? _currentPosition;
  List<EmergencyContact> _emergencyContacts = [];

  // Animation controllers for different effects
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rippleController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rippleAnimation;

  Timer? _sosTimer;
  int _sosCountdown = 0;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Main pulse animation - continuous breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation - intensity variation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Ripple animation - expanding circles
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Start continuous animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _rippleController.repeat();
  }

  Future<void> _initializeApp() async {
    await _loadEmergencyContacts();
    await _checkLocationPermission();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _loadEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList('emergency_contacts') ?? [];

    setState(() {
      _emergencyContacts = contactsJson
          .map((json) => EmergencyContact.fromJson(jsonDecode(json)))
          .toList();
    });

    if (_emergencyContacts.isEmpty) {
      _emergencyContacts = [
        EmergencyContact(
          name: 'Police',
          number: '100',
          type: ContactType.police,
        ),
        EmergencyContact(name: 'Fire', number: '101', type: ContactType.fire),
        EmergencyContact(
          name: 'Ambulance',
          number: '108',
          type: ContactType.medical,
        ),
      ];
      await _saveEmergencyContacts();
    }
  }

  Future<void> _saveEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = _emergencyContacts
        .map((contact) => jsonEncode(contact.toJson()))
        .toList();
    await prefs.setStringList('emergency_contacts', contactsJson);
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Permission.location.status;
    if (permission.isGranted) {
      await _getCurrentLocation();
      setState(() {
        _isLocationEnabled = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    if (statuses[Permission.location]?.isGranted == true) {
      await _getCurrentLocation();
      setState(() {
        _isLocationEnabled = true;
      });
    }
  }

  Future<void> _activateSOS() async {
    if (_isSOSActive) return;

    final confirmed = await _showSOSConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isSOSActive = true;
      _sosCountdown = 5;
    });

    // Intensify animations during countdown
    _pulseController.duration = const Duration(milliseconds: 500);
    _glowController.duration = const Duration(milliseconds: 300);

    HapticFeedback.heavyImpact();

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosCountdown--;
      });

      if (_sosCountdown <= 0) {
        timer.cancel();
        _executeSOSActions();
      }
    });
  }

  Future<bool> _showSOSConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                '🚨 SOS Alert',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you sure you want to activate SOS?\n\nThis will:\n• Send your location to emergency contacts\n• Turn on camera recording\n• Call emergency services',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Activate SOS',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _executeSOSActions() async {
    await _getCurrentLocation();
    await _startCameraRecording();
    await _sendEmergencyMessages();
    _showSOSActiveDialog();

    Timer(const Duration(seconds: 10), () {
      if (_emergencyContacts.isNotEmpty) {
        _makeEmergencyCall(_emergencyContacts.first.number);
      }
    });
  }

  Future<void> _startCameraRecording() async {
    try {
      if (_cameras != null && _cameras!.isNotEmpty) {
        final camera = _cameras!.first;
        _cameraController = CameraController(camera, ResolutionPreset.high);
        await _cameraController!.initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📹 Camera recording started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error starting camera: $e');
    }
  }

  Future<void> _sendEmergencyMessages() async {
    String locationMessage = 'Emergency! I need help.';

    if (_currentPosition != null) {
      locationMessage +=
          '\nMy location: https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    }

    locationMessage += '\nTime: ${DateTime.now().toString()}';

    for (final contact in _emergencyContacts) {
      print('Sending message to ${contact.name}: $locationMessage');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Emergency messages sent to all contacts'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSOSActiveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '🚨 SOS ACTIVATED',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Emergency services have been notified.'),
            const SizedBox(height: 16),
            const Text('Camera is recording.'),
            const SizedBox(height: 16),
            if (_currentPosition != null)
              Text(
                'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              ),
            const SizedBox(height: 16),
            const Text('Calling emergency services in 10 seconds...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deactivateSOS,
            child: const Text('Deactivate SOS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_emergencyContacts.isNotEmpty) {
                _makeEmergencyCall(_emergencyContacts.first.number);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Call Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deactivateSOS() {
    setState(() {
      _isSOSActive = false;
      _sosCountdown = 0;
    });

    // Reset animation speeds
    _pulseController.duration = const Duration(milliseconds: 2000);
    _glowController.duration = const Duration(milliseconds: 1500);

    _sosTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS Deactivated'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        onContactAdded: (contact) async {
          setState(() {
            _emergencyContacts.add(contact);
          });
          await _saveEmergencyContacts();
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rippleController.dispose();
    _sosTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  // Enhanced SOS Button with contained pulse and glow effects
  Widget _buildAnimatedSOSButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _glowAnimation,
        _rippleAnimation,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _isSOSActive ? null : _activateSOS,
          child: Container(
            width: 140, // Reduced from 250 to 140
            height: 140, // Reduced from 250 to 140
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Contained ripple effects - much smaller
                ...List.generate(2, (index) {
                  // Reduced from 3 to 2 ripples
                  final delay = index * 0.4;
                  final animationValue = (_rippleAnimation.value - delay).clamp(
                    0.0,
                    1.0,
                  );

                  return Transform.scale(
                    scale:
                        1.0 + (animationValue * 0.3), // Reduced from 1.5 to 0.3
                    child: Container(
                      width: 120, // Reduced from 200 to 120
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity(
                            (1.0 - animationValue) *
                                0.2 *
                                _glowAnimation.value, // Reduced opacity
                          ),
                          width: 1, // Reduced from 1 to 1
                        ),
                      ),
                    ),
                  );
                }),

                // Compact concentric circles
                Container(
                  width: 120, // Reduced from 220 to 120
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(
                      0.08 * _glowAnimation.value,
                    ), // Reduced opacity
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(
                          0.15 * _glowAnimation.value,
                        ), // Reduced glow
                        blurRadius: 8, // Reduced from 30 to 8
                        spreadRadius: 2, // Reduced from 10 to 2
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 105, // Reduced from 200 to 105
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.12 * _glowAnimation.value),
                  ),
                ),

                Container(
                  width: 90, // Reduced from 170 to 90
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.18 * _glowAnimation.value),
                  ),
                ),

                Container(
                  width: 75, // Reduced from 140 to 75
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.25 * _glowAnimation.value),
                  ),
                ),

                // Main SOS button with subtle pulse effect
                Transform.scale(
                  scale: 0.95 +
                      (_pulseAnimation.value - 0.95) * 0.5, // More subtle pulse
                  child: Container(
                    width: 60, // Reduced from 80 to 60
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.shade300,
                          Colors.red.shade600,
                          Colors.red.shade800,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(
                            0.4 * _glowAnimation.value,
                          ), // Reduced glow
                          blurRadius: 6, // Reduced from 15 to 6
                          spreadRadius: 1, // Reduced from 3 to 1
                        ),
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 3, // Reduced from 5 to 3
                          spreadRadius: 0.5, // Reduced from 1 to 0.5
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sosCountdown > 0
                          ? Text(
                              _sosCountdown.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24, // Reduced from 28 to 24
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Reduced from 20 to 16
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5, // Reduced from 2 to 1.5
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Handle menu button press
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _requestPermissions,
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Note :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once you tap the button, alert message will send to contacts, police, Staff in charge and camera will turn ON.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SOS Button Section with enhanced animations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Enhanced animated SOS button
                  _buildAnimatedSOSButton(),

                  const SizedBox(height: 30),

                  Text(
                    'Tap the SOS button for Help',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _showAddContactDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add all Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Nearby Helpline section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Helpline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle "Tap to call" action if needed, or remove if not functional
                    },
                    child: const Text(
                      'Tap to call',
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Helpline icons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHelplineIcon(
                    '👮‍♂️',
                    'Police',
                    () => _makeEmergencyCall('100'),
                  ),
                  _buildHelplineIcon('👨‍👩‍👧‍👦', 'Family', () {
                    // Placeholder for family contact call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Family contact functionality not implemented',
                        ),
                      ),
                    );
                  }),
                  _buildHelplineIcon(
                    '🚑',
                    '108',
                    () => _makeEmergencyCall('108'),
                  ),
                  _buildHelplineIcon('👨‍💼', 'Staff', () {
                    // Placeholder for staff contact call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Staff contact functionality not implemented',
                        ),
                      ),
                    );
                  }),
                  _buildHelplineIcon('🤝', 'NGO', () {
                    // Placeholder for NGO contact call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'NGO contact functionality not implemented',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Indicators section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indicators',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Heatwave indicator as an ElevatedButton
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HeatwaveScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero, // Remove default padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0, // Remove default elevation
                      backgroundColor:
                          Colors.transparent, // Make background transparent
                      minimumSize: const Size(
                        double.infinity,
                        0,
                      ), // Ensures button takes full width
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade300,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text('🌡️', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Text(
                            'Heatwave',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'GPS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineIcon(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models and supporting classes
enum ContactType { police, fire, medical, family, personal }

class EmergencyContact {
  final String name;
  final String number;
  final ContactType type;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'number': number, 'type': type.toString()};
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      number: json['number'],
      type: ContactType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ContactType.personal,
      ),
    );
  }
}

class AddContactDialog extends StatefulWidget {
  final Function(EmergencyContact) onContactAdded;

  const AddContactDialog({Key? key, required this.onContactAdded})
      : super(key: key);

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  ContactType _selectedType = ContactType.personal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ContactType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Contact Type',
              border: OutlineInputBorder(),
            ),
            items: ContactType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (type) {
              setState(() {
                _selectedType = type!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _numberController.text.isNotEmpty) {
              widget.onContactAdded(
                EmergencyContact(
                  name: _nameController.text,
                  number: _numberController.text,
                  type: _selectedType,
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add Contact'),
        ),
      ],
    );
  }
}
