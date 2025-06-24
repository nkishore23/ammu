import 'package:flutter/material.dart';

class ParentHealthAlertsScreen extends StatelessWidget {
  const ParentHealthAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d47a1), // Deep blue theme color
        foregroundColor: Colors.white, // White icons and text
        elevation: 0, // No shadow
        title: const Text(
          'Parent Health Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Valid Medication Details:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // Dark grey for text
              ),
            ),
            const SizedBox(height: 20),

            // Input Fields
            _buildTextField(hintText: 'Student name'),
            const SizedBox(height: 15),
            _buildTextField(
                hintText: 'Roll No', keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(hintText: 'Class'),
            const SizedBox(height: 15),
            _buildTextField(hintText: 'Parent name'),
            const SizedBox(height: 15),
            _buildTextField(hintText: 'Staff Name'),
            const SizedBox(height: 15),
            _buildTextField(
              hintText: 'Medication details',
              maxLines: 5, // Make it a multi-line input field
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 40),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Medication details submitted! (Placeholder)')),
                  );
                  print('Submit button tapped for Parent Health Alerts.');
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

  // Helper widget to build TextFields with common styling
  Widget _buildTextField(
      {required String hintText,
      TextInputType keyboardType = TextInputType.text,
      int maxLines = 1}) {
    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
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
