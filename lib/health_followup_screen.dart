import 'package:flutter/material.dart';

class HealthFollowUpScreen extends StatelessWidget {
  const HealthFollowUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d47a1), // Deep blue theme color
        foregroundColor: Colors.white, // White icons and text
        elevation: 0, // No shadow
        title: const Text(
          'Health Follow Up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped!')),
              );
            },
          ),
          const SizedBox(width: 8), // Padding for the notification icon
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // Dark grey for text
              ),
            ),
            const SizedBox(height: 15),
            // Health Alert Cards
            Row(
              children: [
                Expanded(
                  child: _buildHealthAlertCard(
                    context,
                    imagePath:
                        'https://placehold.co/180x120/E0E0E0/000000?text=Parents', // Placeholder image
                    label: 'Parents Health Alert',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Parents Health Alert tapped!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildHealthAlertCard(
                    context,
                    imagePath:
                        'https://placehold.co/180x120/C0C0C0/000000?text=Staff', // Placeholder image
                    label: 'Staff Health Alert',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Staff Health Alert tapped!')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Diet Sheet for Hostellers Section
            const Text(
              'Diet Sheet for Hostellers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 15),
            // Student Name TextField
            _buildTextField(hintText: 'Student name'),
            const SizedBox(height: 15),
            // Roll No TextField
            _buildTextField(
                hintText: 'Roll No', keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            // Hostel Room No TextField
            _buildTextField(
                hintText: 'Hostel Room No', keyboardType: TextInputType.text),
            const SizedBox(height: 20),

            // Image Selection Area
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Image selection functionality coming soon!')),
                );
              },
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber, // Plus icon color
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Select Your Image here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Diet Sheet Submitted! (Placeholder)')),
                  );
                  print('Submit button tapped for Diet Sheet.');
                  // Add logic to process the form data (e.g., save to a database)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d47a1), // Deep blue
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                      double.infinity, 55), // Full width, fixed height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  // Helper widget to build individual health alert cards
  Widget _buildHealthAlertCard(
    BuildContext context, {
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagePath,
                  width: double.infinity, // Occupy full width of card
                  height: 100, // Fixed height for image
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build TextFields with common styling
  Widget _buildTextField(
      {required String hintText,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: Colors.grey[100],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
