// main.dart (kept for context of the overall application structure)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for Firebase logout
import 'package:url_launcher/url_launcher.dart'; // For launching phone calls

// Assuming these files exist in your project structure:
import 'signup_page.dart';
import 'heatwave_screen.dart';

import 'gps_tracking_screen.dart';

import 'reports_screen.dart';

import 'subscription_plan_screen.dart';

import 'academic_followup_screen.dart';

import 'health_followup_screen.dart';

import 'parent_health_alerts_screen.dart';

// This should be your main application entry point.
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // Start with the HomeScreen
    ),
  );
}

/// The main scaffold for the application, handling BottomNavigationBar and AppBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Tracks the currently selected tab index.

  // The list of pages that the BottomNavigationBar will switch between.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize _pages in initState to ensure `this` is available for callbacks.
    _pages = [
      HomeTabPage(
        onNavigateToReports: () {
          // This callback allows the HomeTabPage to change the index of the BottomNavBar.
          setState(() {
            _currentIndex = 2; // Index 2 corresponds to the Reports screen.
          });
        },
      ),
      const GpsTrackingScreen(), // Assuming GpsTrackingScreen is a StatelessWidget or StatefulWidget
      const ReportsScreen(), // Assuming ReportsScreen is a StatelessWidget or StatefulWidget
    ];
  }

  /// Helper method to get the title for the AppBar based on the current index.
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'GPS Tracking';
      case 2:
        return 'Reports';
      default:
        return 'AMMU'; // Default title if somehow an invalid index is selected
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_currentIndex)),
        backgroundColor: const Color(0xFF0d47a1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Conditionally show the "Plan" text link only when on the GPS Tracking screen (index 1)
          if (_currentIndex == 1) // Only show when GPS tab is active
            TextButton(
              onPressed: () {
                print('Plan text link tapped from GPS Tracking tab');
                // Navigate to the PlanScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubscriptionPlanScreen()),
                );
              },
              child: const Column(
                // Changed to Row to include icon and text
                mainAxisSize: MainAxisSize
                    .min, // Ensure the row only takes up needed space
                children: [
                  Icon(Icons.assignment,
                      color: Colors.white, size: 16), // Added an icon
                  SizedBox(width: 4), // Small space between icon and text
                  Text(
                    'Plan',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (_currentIndex != 1)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More options coming soon!')),
                );
              },
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      // The drawer is placed here, so it's accessible from all pages managed by the HomeScreen.
      drawer: const AppDrawer(),
      // IndexedStack keeps the state of pages when switching tabs.
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedItemColor: const Color(0xFF0d47a1),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index on tap
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'GPS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// screens/home_tab_page.dart (part of HomeScreen, but separated for clarity)
/// The main content tab for the Home screen, featuring the SOS button and other options.
class HomeTabPage extends StatefulWidget {
  final VoidCallback onNavigateToReports; // Callback to change parent's tab

  const HomeTabPage({required this.onNavigateToReports, super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage>
    with TickerProviderStateMixin {
  late final AnimationController
      _sosController; // Controller for the SOS button's ripple animation.

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2), // Full cycle duration for one ripple
    );

    // Start the ripple animation immediately and repeat indefinitely.
    // Using addPostFrameCallback ensures the widget is fully built before starting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sosController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _sosController
        .dispose(); // Dispose the animation controller to prevent memory leaks.
    super.dispose();
  }

  /// Builds a single ripple circle for the SOS button animation.
  /// [normalizedTime] is the current animation progress for this ripple (0.0 to 1.0).
  Widget _buildRipple({required double normalizedTime}) {
    // Apply an easing curve (easeInOutQuad) for a more pronounced and
    // visually impactful expansion and fade-out effect.
    final double easedProgress = Curves.easeInOutQuad.transform(normalizedTime);

    // Define the base radius of the button and the maximum radius a ripple will reach.
    const double baseButtonRadius = 70.0;
    const double maxRippleRadius = 180.0;

    // Calculate the current radius, expanding from the button's edge.
    final double currentRadius =
        baseButtonRadius + (maxRippleRadius - baseButtonRadius) * easedProgress;

    // Define the start and end opacity for the fade-out effect.
    // A higher start opacity makes the ripple more noticeable.
    const double startOpacity = 0.6;
    const double endOpacity = 0.0;
    final double opacity =
        startOpacity + (endOpacity - startOpacity) * easedProgress;

    return CircleAvatar(
      radius: currentRadius,
      // Use the SOS button's color with the calculated fading opacity.
      backgroundColor:
          const Color(0xFFFF4747).withOpacity(opacity.clamp(0.0, 1.0)),
    );
  }

  /// Helper function to launch a phone dialer with a given number.
  /// Displays a SnackBar if the number cannot be launched.
  Future<void> _callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not dial $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating call: $e')),
        );
      }
    }
  }

  /// Helper widget to build individual helpline icons.
  /// Replaced `imagePath` with `iconData` for `MaterialIcons`.
  Widget _buildHelplineIcon(
      IconData iconData, String label, String phoneNumber) {
    return GestureDetector(
      onTap: () =>
          _callNumber(phoneNumber), // Call the number when icon is tapped
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                const Color(0xFFE3F2FD), // Light blue background for icons
            child: Icon(iconData,
                size: 36,
                color: const Color(0xFF0d47a1)), // Main app blue for icons
          ),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  /// Helper widget to build the indicator cards (e.g., Heatwave Indicator).
  Widget _buildIndicatorCard({
    required String title,
    required IconData icon, // Changed from title-only to include an icon
    required Gradient gradient,
    required Color shadowColor,
    VoidCallback? onTap, // Added onTap for reusability
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28), // Display the icon
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Note: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Once you tap the button, an alert message will be sent to emergency contacts.',
                ),
              ],
            ),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          Center(
            child: GestureDetector(
              onTap: () {
                // TODO: Implement SOS Logic here (e.g., send SMS, make API call)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('SOS message sent! (Placeholder)')),
                );
              },
              child: SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _sosController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Four staggered ripples create the continuous pulsing effect.
                        _buildRipple(
                            normalizedTime: (_sosController.value + 0.0) % 1.0),
                        _buildRipple(
                            normalizedTime:
                                (_sosController.value + 0.25) % 1.0),
                        _buildRipple(
                            normalizedTime: (_sosController.value + 0.5) % 1.0),
                        _buildRipple(
                            normalizedTime:
                                (_sosController.value + 0.75) % 1.0),
                        child!, // The main SOS button itself
                      ],
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4744).withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 70,
                      backgroundColor:
                          Color(0xFFFF4747), // The prominent red for SOS
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Tap the SOS button for Help',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Navigates to the AddAllContactsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAllContactsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0d47a1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Add all Contacts', // Original label
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Helpline',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tap on specific icons to call!')),
                  );
                },
                child: const Text(
                  'Tap to call',
                  style: TextStyle(color: Color(0xFF0d47a1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHelplineIcon(
                  Icons.local_police, 'Police', '100'), // Example Police number
              _buildHelplineIcon(Icons.people, 'Family',
                  '1234567890'), // Placeholder for Family contact
              _buildHelplineIcon(
                  Icons.call, '108', '108'), // Example Ambulance number
              _buildHelplineIcon(Icons.groups, 'Staff',
                  '0987654321'), // Placeholder for Staff contact
              _buildHelplineIcon(Icons.volunteer_activism, 'NGO',
                  '0123456789'), // Placeholder for NGO contact
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Indicators',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Using the reusable _buildIndicatorCard for Heatwave Indicator
          _buildIndicatorCard(
            title: 'Heatwave Indicator',
            icon: Icons.wb_sunny, // Icon for Heatwave
            gradient: const LinearGradient(
              colors: [Color(0xFFF9D423), Color(0xFFFF4E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: Colors.orange.withOpacity(0.3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeatwavesIndicatorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // The "View All Reports" card (previously commented out, now using _buildIndicatorCard)
          _buildIndicatorCard(
            title: 'View All Reports',
            icon: Icons.bar_chart, // Icon for reports
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: Colors.blue.withOpacity(0.3),
            onTap: widget
                .onNavigateToReports, // Callback to change parent's tab to Reports
          ),
        ],
      ),
    );
  }
}

// screens/app_drawer.dart (part of HomeScreen, but separated for clarity)
/// The application's drawer, providing navigation to various sections and logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // A helper function to show a snackbar for placeholder actions.
    void showComingSoon(String featureName) {
      Navigator.pop(context); // Close the drawer first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$featureName page coming soon!')),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove default top padding
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0d47a1)),
            child: Text(
              'AMMU Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Admin Dashboard'),
            onTap: () => showComingSoon('Admin Dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Academic Follow Up'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AcademicFollowUpScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Health Follow Up'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthFollowUpScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Parent Health Alert'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentHealthAlertsScreen(),
                ),
              );
            },
          ),
          const Divider(), // Separator line
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer first

              // Perform Firebase logout.
              await FirebaseAuth.instance.signOut();

              // Navigate to the SignUpPage and remove all previous routes.
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                  (Route<dynamic> route) =>
                      false, // Removes all previous routes from the stack
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// screens/addallcontactsscreen.dart (Placeholder)
class AddAllContactsScreen extends StatelessWidget {
  const AddAllContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add All Contacts')),
      body: const Center(child: Text('Add all contacts functionality here.')),
    );
  }
}
