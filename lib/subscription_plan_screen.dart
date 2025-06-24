import 'package:flutter/material.dart';

// Import the PaymentScreen
import 'payment_screen.dart'; // Assuming payment_screen.dart is in the same directory or adjust path

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  // Variable to hold the currently selected plan.
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    // Initialize with "School Plan" as it appears selected in the image.
    _selectedPlan = 'School Plan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0d47a1), // Deep blue from your app theme
        foregroundColor: Colors.white, // White icons/text
        elevation: 0, // No shadow
        title: const Text(
          'Subscription Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and School Plan Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100], // Light grey background for the card
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://placehold.co/600x200/F0F0F0/000000?text=Subscription+Image', // Placeholder image from your screenshot
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Add error and loading builders for robustness
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
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
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'School Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint('Limit upto track 1000 students'),
                  const SizedBox(height: 5),
                  _buildBulletPoint('Past month location records are shown'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Choose Plan Section
            const Text(
              'Choose Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 15),

            // Parents Plan Card
            _buildPlanCard(
              title: 'Parents Plan',
              price: '₹199',
              duration: '/ per month',
              value: 'Parents Plan',
            ),
            const SizedBox(height: 15),

            // School Plan Card
            _buildPlanCard(
              title: 'School Plan',
              price: '₹999',
              duration: '/ per month',
              value: 'School Plan',
            ),
            const SizedBox(height: 15),

            // University Plan Card
            _buildPlanCard(
              title: 'University Plan',
              price: '₹3999',
              duration: '/ per month',
              value: 'University Plan',
            ),
            const SizedBox(height: 30),

            // Buy Now Button (Main button)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPlan != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Buying $_selectedPlan! Proceeding to payment...')),
                    );
                    print('Buy Now tapped for: $_selectedPlan');
                    // Navigate to PaymentScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PaymentScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a plan first!')),
                    );
                  }
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
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for bullet points
  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Aligned to center
      children: [
        Icon(
          Icons.circle,
          size: 14.0, // Increased size for better alignment
          color: Colors.grey[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for building plan selection cards
  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required String value,
  }) {
    // Determine if this card is currently selected
    bool isSelected = _selectedPlan == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE3F2FD)
              : Colors.white, // Light blue if selected, white otherwise
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF0d47a1) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0d47a1).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Custom radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF0d47a1) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0d47a1) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0d47a1), // Deep blue for price
                        ),
                      ),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "Buy Now" button for the selected School Plan, if applicable
            // This button also navigates to PaymentScreen
            if (value == 'School Plan' && isSelected)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Buying $_selectedPlan! Proceeding to payment...')),
                  );
                  print('Buy Now tapped for: $_selectedPlan (from card)');
                  // Navigate to PaymentScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d47a1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  elevation: 3,
                ),
                child: const Text('Buy Now'),
              ),
          ],
        ),
      ),
    );
  }
}
