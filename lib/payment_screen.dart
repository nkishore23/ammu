import 'package:flutter/material.dart';
import 'dart:math'; // For simulating random success/failure
import 'package:url_launcher/url_launcher.dart'; // Uncommented for launching UPI deep links
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter (though removed from card number field)

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // A variable to hold the currently selected payment method.
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    // Initialize with 'Apple Pay' as it appears selected in the screenshot.
    _selectedPaymentMethod = 'Apple Pay';

    // In a real app, if using SDKs with callbacks (like Razorpay, Paytm),
    // you might initialize listeners here:
    // _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose listeners in a real app
    // _razorpay.clear();
  }

  /// This method simulates initiating a payment process for the selected method.
  /// In a real application, this would involve calling respective payment gateway SDKs
  /// and critically interacting with a secure backend server.
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    // Show a loading indicator while simulating payment processing.
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing loading dialog by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0d47a1)),
        );
      },
    );

    // Simulate a network delay for payment processing.
    await Future.delayed(const Duration(seconds: 2));

    // Dismiss the loading indicator.
    if (mounted) {
      Navigator.of(context).pop();
    } else {
      return; // Widget not mounted, exit
    }

    // Simulate random success/failure (for demonstration purposes only).
    final random = Random();
    bool paymentSuccess = random.nextBool(); // 50% chance of success
    String message;

    switch (_selectedPaymentMethod) {
      case 'Paytm':
        print('Simulating Paytm payment initiation...');
        // --- REAL PAYTM INTEGRATION STEPS (Conceptual) ---
        // 1. Add Paytm All-in-One SDK Flutter plugin to pubspec.yaml: paytm_allinonesdk
        // 2. Configure Paytm in native Android/iOS projects (e.g., manifest, Info.plist, Podfile).
        //    This includes adding essential queries for `android.intent.action.VIEW` for Deeplinks in AndroidManifest.
        // 3. From your SECURE BACKEND, generate a transaction token/order ID for the payment.
        //    This step is crucial and must happen on your server.
        // 4. In Flutter, use the Paytm SDK to initiate the payment:
        //    try {
        //      var response = await AllInOneSdk.startTransaction(
        //        MID: "YOUR_MID", // Merchant ID
        //        orderId: "ORDER_ID_FROM_BACKEND",
        //        amount: "999.00", // Amount to be paid
        //        txnToken: "TXN_TOKEN_FROM_BACKEND",
        //        appInvokeEnabled: true, // For app-invoke flow
        //        checksumhash: "CHECKSUM_HASH_FROM_BACKEND", // Important for integrity
        //        callbackUrl: "YOUR_CALLBACK_URL", // URL to receive payment status
        //        isStaging: true, // Set to false for production
        //        restrictPaymode: "CC,DC", // Optional: restrict payment modes
        //        enableAssist: true,
        //      );
        //      // Handle response: response will contain payment status
        //      if (response != null && response['STATUS'] == 'TXN_SUCCESS') {
        //        message = 'Paytm payment successful!';
        //        print('Paytm payment successful.');
        //      } else {
        //        message = 'Paytm payment failed or cancelled.';
        //        print('Paytm payment failed/cancelled: $response');
        //      }
        //    } catch (err) {
        //      message = 'Paytm payment error: ${err.message ?? err.toString()}';
        //      print('Paytm payment error: $err');
        //    }

        if (paymentSuccess) {
          message = 'Simulated Paytm payment successful!';
          print('Simulated Paytm payment successful.');
        } else {
          message = 'Simulated Paytm payment failed. Please try again.';
          print('Simulated Paytm payment failed.');
        }
        break;
      case 'Stripe':
        print('Simulating Stripe payment initiation...');
        // --- REAL STRIPE INTEGRATION STEPS (Conceptual) ---
        // 1. Add Stripe Flutter SDK to pubspec.yaml: flutter_stripe
        // 2. Initialize Stripe in main.dart or app start with your publishable key.
        //    E.g., Stripe.publishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
        // 3. Create a PaymentIntent on your SECURE BACKEND (THIS IS CRITICAL).
        //    The backend sends back a `client_secret`.
        // 4. In Flutter, present Stripe's UI to collect card details or use pre-saved cards.
        //    E.g., final paymentMethod = await Stripe.instance.createPaymentMethod(params: PaymentMethodParams.card());
        // 5. Confirm the payment intent using the `client_secret` received from backend.
        //    E.g., await Stripe.instance.confirmPayment(
        //      paymentIntentClientSecret: 'CLIENT_SECRET_FROM_BACKEND',
        //      params: const PaymentMethodParams.card(), // or .billingDetails, etc.
        //    );
        // 6. Handle the `PaymentIntent` status (success, requires action, failed).
        if (paymentSuccess) {
          message = 'Simulated Stripe payment successful!';
          print('Simulated Stripe payment successful.');
        } else {
          message = 'Simulated Stripe payment declined. Check card details.';
          print('Simulated Stripe payment failed.');
        }
        break;
      case 'UPI':
        print('Attempting to launch UPI app (e.g., GPay)...');
        // --- REAL UPI INTEGRATION STEPS (Conceptual & Partial Implementation) ---
        // 1. Choose a UPI payment gateway/provider (e.g., Razorpay, PhonePe, Google Pay for Business, or directly constructing UPI deep links).
        // 2. Add `url_launcher` to pubspec.yaml (already uncommented above).
        // 3. Generate a UPI deep link string or payment parameters from your SECURE BACKEND.
        //    This often includes: `pa` (payee address), `pn` (payee name), `mc` (merchant code),
        //    `tid` (transaction ID), `am` (amount), `cu` (currency), `tn` (transaction note).
        //    Example for GPay:
        String upiUri =
            "upi://pay?pa=test@okicici&pn=TestMerchant&mc=1234&tid=YOUR_ORDER_ID&tr=YOUR_TRANSACTION_REF&am=999.00&cu=INR&tn=SchoolPlanPayment&url=https://yourwebsite.com/payment_status";

        try {
          final uri = Uri.parse(upiUri);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            message = 'Opened UPI app. Please complete payment there.';
            print('UPI app launched successfully.');
            // Crucially: In a real app, your backend must verify the payment status via webhooks or polling the payment gateway
            // as payment completion happens outside your app.
          } else {
            message =
                'Could not launch UPI app. Please ensure a UPI app (like GPay) is installed.';
            print('Failed to launch UPI app.');
          }
        } catch (e) {
          message = 'Error launching UPI app: ${e.toString()}';
          print('Error launching UPI app: $e');
        }

        // The simulated success/failure below still applies to the *transaction outcome*,
        // not necessarily the app launch itself.
        if (paymentSuccess) {
          message += '\nSimulated UPI payment successful!';
          print('Simulated UPI payment successful.');
        } else {
          message += '\nSimulated UPI transaction failed or cancelled.';
          print('Simulated UPI payment failed.');
        }
        break;
      case 'Apple Pay':
        print('Simulating Apple Pay payment initiation...');
        // --- REAL APPLE PAY INTEGRATION STEPS (Conceptual) ---
        // 1. Configure Apple Pay merchant ID and capabilities in Xcode and Apple Developer account.
        // 2. Add a Flutter plugin that supports Apple Pay (e.g., pay_apple_and_google_pay or flutter_stripe).
        // 3. Build a PaymentRequest with amount, currency, and line items.
        // 4. Present the Apple Pay sheet to the user.
        // 5. On success, receive an encrypted payment token from Apple.
        // 6. Send this token to your SECURE BACKEND to process the charge with your payment gateway.
        if (paymentSuccess) {
          message = 'Simulated Apple Pay payment successful!';
          print('Simulated Apple Pay payment successful.');
        } else {
          message = 'Simulated Apple Pay payment cancelled or failed.';
          print('Simulated Apple Pay payment failed.');
        }
        break;
      case 'Add New Card':
        // This is handled by the _showAddNewCardDialog directly,
        // so the main proceed button for 'Add New Card' just confirms intention.
        message = 'Please fill out the card details to add a new card.';
        break;
      default:
        message = 'Unknown payment method selected.';
        break;
    }

    // Show a snackbar with the outcome message.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              paymentSuccess && _selectedPaymentMethod != 'Add New Card'
                  ? Colors.green
                  : Colors.red,
          duration: const Duration(seconds: 4), // Longer duration for more info
        ),
      );
    }
  }

  /// Simulates showing a dialog for adding new card details.
  /// In a real app, this would be a dedicated secure form or an SDK's UI.
  void _showAddNewCardDialog() {
    // Using TextEditingController to reliably get input from TextField
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryDateController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Add New Card', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cardNumberController, // Assign controller
                  keyboardType: TextInputType
                      .text, // Changed to text to allow hyphens/spaces
                  // Removed inputFormatters to allow free typing of hyphens/spaces,
                  // relying solely on post-input cleaning for validation.
                  maxLength:
                      19, // Max length for "XXXX-XXXX-XXXX-XXXX" (16 digits + 3 hyphens)
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'XXXX-XXXX-XXXX-XXXX or XXXXXXXXXXXXXXXX',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryDateController, // Assign controller
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: cvvController, // Assign controller
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Retrieve values from controllers
                    final rawCardNumber = cardNumberController.text;
                    final expiryDate = expiryDateController.text;
                    final cvv = cvvController.text;

                    // Add print statements for debugging
                    print('--- Card Validation Debug ---');
                    print('Raw Card Number: "$rawCardNumber"');

                    // --- Card Number Validation ---
                    // Remove hyphens and spaces before validating
                    final cleanedCardNumber =
                        rawCardNumber.replaceAll(RegExp(r'[- ]'), '');
                    print('Cleaned Card Number: "$cleanedCardNumber"');
                    print('Cleaned length: ${cleanedCardNumber.length}');
                    print(
                        'Is numeric only (cleaned): ${RegExp(r'^[0-9]+$').hasMatch(cleanedCardNumber)}');

                    if (cleanedCardNumber.length != 16 ||
                        !RegExp(r'^[0-9]+$').hasMatch(cleanedCardNumber)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Invalid Card Number. Must be 16 digits and numeric.')),
                      );
                      return;
                    }

                    // Basic client-side validation for expiry and CVV (for simulation)
                    if (expiryDate.isEmpty || cvv.length < 3) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please fill expiry and CVV correctly.')),
                      );
                      return;
                    }

                    // In a real app: Send card details securely to your backend for tokenization/saving.
                    print(
                        'Simulating saving card: $cleanedCardNumber, $expiryDate, $cvv');
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Card added successfully! (Simulated)')),
                    );
                    Navigator.of(dialogContext).pop(); // Close dialog
                    setState(() {
                      _selectedPaymentMethod =
                          'Add New Card (Saved)'; // Update selection to reflect "saved card"
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0d47a1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save Card'),
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
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0d47a1), // Deep blue from your app theme
        foregroundColor: Colors.white, // White icons/text
        elevation: 0, // No shadow
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the payment method you want to use.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Options List
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentMethodCard(
                    context: context,
                    iconPath:
                        'https://placehold.co/40x40/FF5722/FFFFFF?text=P', // Placeholder for Paytm logo
                    methodName: 'Paytm',
                    value: 'Paytm',
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodCard(
                    context: context,
                    iconPath:
                        'https://placehold.co/40x40/673AB7/FFFFFF?text=S', // Placeholder for Stripe logo
                    methodName: 'Stripe',
                    value: 'Stripe',
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodCard(
                    context: context,
                    iconPath:
                        'https://placehold.co/40x40/4CAF50/FFFFFF?text=U', // Placeholder for UPI logo
                    methodName: 'UPI',
                    value: 'UPI',
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodCard(
                    context: context,
                    iconPath:
                        'https://placehold.co/40x40/000000/FFFFFF?text=AP', // Placeholder for Apple Pay logo
                    methodName: 'Apple Pay',
                    value: 'Apple Pay',
                  ),
                  const SizedBox(height: 10),
                  _buildAddNewCard(context), // "Add New Card" option
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Proceed Button
            Center(
              child: ElevatedButton(
                onPressed:
                    _processPayment, // Calls the simulated payment function
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
                  'Proceed',
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

  /// Helper widget to build a single payment method card.
  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String iconPath,
    required String methodName,
    required String value,
  }) {
    bool isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1, // Higher elevation if selected
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0d47a1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? const Color(0xFFE3F2FD)
            : Colors.white, // Light blue if selected
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  iconPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  methodName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? const Color(0xFF0d47a1) : Colors.black87,
                  ),
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                },
                activeColor:
                    const Color(0xFF0d47a1), // Deep blue for selected radio
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for the "Add New Card" option.
  Widget _buildAddNewCard(BuildContext context) {
    bool isSelected = _selectedPaymentMethod == 'Add New Card';
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = 'Add New Card';
        });
        // Instead of just a SnackBar, open the simulated card input dialog.
        _showAddNewCardDialog();
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0d47a1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Add New Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Radio<String>(
                value: 'Add New Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                  // If "Add New Card" is selected via radio, also show the dialog.
                  if (newValue == 'Add New Card') {
                    _showAddNewCardDialog();
                  }
                },
                activeColor: const Color(0xFF0d47a1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
