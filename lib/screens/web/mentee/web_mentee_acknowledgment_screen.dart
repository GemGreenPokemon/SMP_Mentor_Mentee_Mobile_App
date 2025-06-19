import 'package:flutter/material.dart';
import 'web_mentee_dashboard_screen.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';

class WebMenteeAcknowledgmentScreen extends StatefulWidget {
  const WebMenteeAcknowledgmentScreen({super.key});

  @override
  State<WebMenteeAcknowledgmentScreen> createState() => _WebMenteeAcknowledgmentScreenState();
}

class _WebMenteeAcknowledgmentScreenState extends State<WebMenteeAcknowledgmentScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAcknowledged = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the acknowledgment box')),
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // TODO: Save acknowledgment to database
    
    // Navigate to mentee dashboard
    Navigator.pushReplacementNamed(context, '/mentee');
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2D52).withOpacity(0.1),
              Colors.white,
              Colors.white,
              const Color(0xFF0F2D52).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left side decorative panel - only visible on desktop/tablet
              if (isDesktop || isTablet)
                Expanded(
                  flex: isDesktop ? 4 : 3,
                  child: Container(
                    height: MediaQuery.of(context).size.height - 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2D52),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/My_SMP_Logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Mentee Acknowledgment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Complete your acknowledgment form to finalize your registration as a mentee in the Student Mentorship Program.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ Understand program expectations',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '✓ Acknowledge orientation completion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '✓ Confirm WCONLINE registration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '✓ Accept program guidelines',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Right side acknowledgment form
              Expanded(
                flex: isDesktop ? 3 : (isTablet ? 4 : 1),
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop || isTablet ? double.infinity : 500,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop || isTablet ? 48 : 24,
                      vertical: 32
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!(isDesktop || isTablet))
                            Center(
                              child: Image.asset(
                                'assets/images/My_SMP_Logo.png',
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (!(isDesktop || isTablet))
                            const SizedBox(height: 40),
                          
                          const Text(
                            'Mentee Acknowledgment Form',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2D52),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please review and complete the acknowledgment',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          const Text(
                            'Please read and acknowledge the following:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2D52),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF0F2D52).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I acknowledge that I have watched and attended the Mentee Orientation and understand how to achieve and maintain "Active Status" in the program each semester.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'I understand that if I end my program membership or take a brief leave, I must submit the Mentee Leave form.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'I will register for the Success Mentor Program in WCONLINE using the steps presented in Orientation and will use the SMP WCONLINE portal to book and edit appointments with my mentor(s).',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'I also acknowledge that SMP mentors are fellow students—just as they respect my time and boundaries, I will respect theirs—and that they follow FERPA guidelines and are mandated reporters (for more information, see UC Merced\'s FERPA page).',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Acknowledgment checkbox
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isAcknowledged = !_isAcknowledged;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isAcknowledged 
                                    ? const Color(0xFF0F2D52).withOpacity(0.1)
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: _isAcknowledged 
                                      ? const Color(0xFF0F2D52)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isAcknowledged 
                                        ? Icons.check_box 
                                        : Icons.check_box_outline_blank,
                                    color: _isAcknowledged 
                                        ? const Color(0xFF0F2D52)
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'I have read and agree to the statements above',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Full name signature field
                          const Text(
                            'Please type your full name to complete the Mentee Acknowledgment Form:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2D52),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Type your full legal name here',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.trim().split(' ').length < 2) {
                                return 'Please enter your full name (first and last name)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Date field (current date displayed)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF0F2D52),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Date: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2D52),
                                  ),
                                ),
                                Text(
                                  DateTime.now().toString().split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F2D52),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'SUBMIT & REGISTER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}