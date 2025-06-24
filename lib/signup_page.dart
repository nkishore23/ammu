import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In

import 'login_page.dart'; // Import the login page

// database_helper.dart is not directly used for user authentication with Firebase Auth.
// If it contains other app-specific data logic, keep its import.
// If it ONLY contained user authentication, you can remove this comment and the import.
// import 'database_helper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Initialize GoogleSignIn with the webClient Id for web support.
  // This clientId is essential for web and can be beneficial for other platforms too.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Added const
    clientId:
        '591533067808-m9cnoj8bqng1p18bv014t9djdajk1iig.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation regex (Firebase Auth also validates, but good for immediate UI feedback).
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Mobile number validation (for UI validation; Firebase Auth primarily uses email/password
  // for direct sign-up, though phone auth is a separate Firebase service).
  bool _isValidMobile(String mobile) {
    return RegExp(r'^[0-9]{10}$').hasMatch(mobile);
  }

  // Password validation (Firebase Auth requires a minimum of 6 characters by default).
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Handles the email/password sign-up process using Firebase Authentication.
  Future<void> _handleEmailPasswordSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator.
      });

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // User successfully created in Firebase Auth.
        // If you need to store additional user data (like the mobile number)
        // in a database like Firestore, you would do it here.
        // Example (requires 'cloud_firestore' package):
        // import 'package:cloud_firestore/cloud_firestore.dart';
        // if (userCredential.user != null) {
        //   await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        //     'email': _emailController.text.trim(),
        //     'mobileNumber': _mobileController.text.trim(), // Store mobile if needed
        //     'createdAt': FieldValue.serverTimestamp(),
        //   });
        // }

        setState(() {
          _isLoading = false; // Hide loading indicator.
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              // Added const
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the login page after successful registration.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const LoginPage()), // Added const
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false; // Hide loading indicator on error.
        });

        String errorMessage;
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'An account already exists for that email.';
        } else {
          errorMessage = 'Registration failed: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Removed const due to dynamic content
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false; // Hide loading indicator on unexpected error.
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Removed const due to dynamic content
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handles Google Sign-Up using Firebase Authentication.
  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true; // Show loading indicator.
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the Google sign-in process.
        setState(() {
          _isLoading = false; // Hide loading indicator.
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // User successfully signed up/in with Google via Firebase Auth.
      // You can store additional user data (like mobile number) to Firestore or Realtime Database here
      // if needed, similar to the email/password sign-up.

      setState(() {
        _isLoading = false; // Hide loading indicator.
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // Added const
            content: Text('Signed up with Google successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginPage()), // Added const
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator on error.
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Removed const due to dynamic content
            content: Text('Google Sign-up failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator on unexpected error.
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Removed const due to dynamic content
            content: Text(
                'An unexpected error during Google Sign-up: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Launches a URL using `url_launcher` package.
  /// Includes error handling for cases where the URL cannot be launched.
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Removed const due to dynamic content
            content: Text('Could not open link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Screen background fills edge to edge.
      body: SafeArea(
        child: Column(
          // Use Column to stack the top illustration and the scrollable form.
          children: [
            // Top Illustration: Designed to be edge-to-edge horizontally.
            ClipPath(
              clipper: const CurveClipper(), // Added const
              child: Container(
                color: const Color(0xFF003366), // Added const
                height: 200,
                // `width: double.infinity` is implicit as Column child expands horizontally.
                child: const Center(
                  // Added const to Center and its content.
                  child: SizedBox(
                    // Use SizedBox for fixed size for the inner icon container.
                    width: 100,
                    height: 100,
                    child: DecoratedBox(
                      // More efficient for simple decorations than Container.
                      decoration: BoxDecoration(
                        // Added const
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                            Radius.circular(50)), // Consistent borderRadius
                      ),
                      child: Icon(
                        // Added const
                        Icons.person_add,
                        size: 50,
                        color: Color(0xFF003366), // Added const
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Form Content: This section gets the horizontal padding.
            Expanded(
              // Takes up the remaining vertical space.
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal:
                        20.0), // Padding applied to the entire form group.
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                          height: 20), // Spacing below the top illustration.

                      // Title
                      const Text(
                        // Added const
                        'Welcome to AMMU!',
                        style: TextStyle(
                          // Added const
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 8), // Added const

                      const Text(
                        // Added const
                        'Create your account to get started',
                        style: TextStyle(
                          // Added const
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 30), // Added const

                      // Mobile Number Field
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          // Removed const due to dynamic properties like labelText, hintText
                          labelText: 'Mobile Number',
                          hintText: 'Enter your 10-digit mobile number',
                          prefixIcon: const Icon(Icons.phone), // Added const
                          border: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF003366)), // Added const
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (!_isValidMobile(value)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15), // Added const

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          // Removed const due to dynamic properties like labelText, hintText
                          labelText: 'E-mail',
                          hintText: 'Enter your email address',
                          prefixIcon: const Icon(Icons.email), // Added const
                          border: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF003366)), // Added const
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!_isValidEmail(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15), // Added const

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          // Removed const due to dynamic properties like labelText, hintText, suffixIcon
                          labelText: 'Password',
                          hintText: 'Enter your password (min 6 characters)',
                          prefixIcon: const Icon(Icons.lock), // Added const
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Removed const due to dynamic icon
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Removed const due to dynamic borderRadius
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF003366)), // Added const
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!_isValidPassword(value)) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20), // Added const

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _handleEmailPasswordSignUp,
                          style: ElevatedButton.styleFrom(
                            // Removed const due to dynamic backgroundColor
                            backgroundColor:
                                const Color(0xFF003366), // Added const
                            padding: const EdgeInsets.symmetric(
                                vertical: 16), // Added const
                            shape: const RoundedRectangleBorder(
                              // Added const
                              borderRadius: BorderRadius.all(Radius.circular(
                                  10)), // Consistent borderRadius
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  // Added const
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    // Removed const due to dynamic valueColor
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  // Added const
                                  'Sign Up',
                                  style: TextStyle(
                                    // Added const
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20), // Added const

                      // Log In link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                              "Already have an account? "), // Added const
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginPage()), // Added const
                              );
                            },
                            child: const Text(
                              // Added const
                              'Log In',
                              style: TextStyle(
                                // Added const
                                color: Color(0xFF003366),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30), // Added const

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: Colors.grey[
                                      300])), // Removed const due to dynamic color
                          const Padding(
                            // Added const
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              // Added const
                              'Or Sign Up with',
                              style: TextStyle(
                                  color: Colors
                                      .grey), // Removed const due to dynamic color
                            ),
                          ),
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: Colors.grey[
                                      300])), // Removed const due to dynamic color
                        ],
                      ),

                      const SizedBox(height: 20), // Added const

                      // Google and Facebook Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: SocialButton(
                              // Removed const as it's not a const constructor currently
                              imageUrl:
                                  'https://img.icons8.com/color/48/google-logo.png',
                              label: 'Google',
                              onTap: _handleGoogleSignUp,
                            ),
                          ),
                          const SizedBox(width: 12), // Added const
                          Expanded(
                            child: SocialButton(
                              // Removed const
                              imageUrl:
                                  'https://img.icons8.com/color/48/facebook-new.png',
                              label: 'Facebook',
                              onTap: () {
                                _launchURL("https://www.facebook.com/login");
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20), // Added const

                      // Terms and Privacy
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20), // Added const
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            // Added const
                            text: 'By signing up, you agree to our ',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize:
                                    12), // Removed const due to dynamic color/fontSize
                            children: [
                              TextSpan(
                                // Added const
                                text: 'Terms of Service',
                                style: TextStyle(
                                  // Added const
                                  color: Color(0xFF003366),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '), // Added const
                              TextSpan(
                                // Added const
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  // Added const
                                  color: Color(0xFF003366),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Added const
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable widget for social login buttons.
class SocialButton extends StatelessWidget {
  final String imageUrl;
  final String label;
  final VoidCallback onTap;

  const SocialButton({
    // Added const constructor
    super.key,
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Image.network(
        imageUrl,
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            // Removed const due to dynamic icon based on label
            label == 'Google' ? Icons.g_mobiledata : Icons.facebook,
            size: 20,
            color: const Color(0xFF003366), // Added const
          );
        },
      ),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF003366)), // Added const
      ),
      style: OutlinedButton.styleFrom(
        // Removed const due to dynamic properties like padding, shape, side
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 16), // Added const
        shape: const RoundedRectangleBorder(
          // Added const
          borderRadius:
              BorderRadius.all(Radius.circular(8)), // Consistent borderRadius
        ),
        side: const BorderSide(color: Color(0xFF003366)), // Added const
      ),
    );
  }
}

/// Custom Clipper for creating a curved shape at the top of the screen.
class CurveClipper extends CustomClipper<Path> {
  const CurveClipper(); // Added const constructor

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
