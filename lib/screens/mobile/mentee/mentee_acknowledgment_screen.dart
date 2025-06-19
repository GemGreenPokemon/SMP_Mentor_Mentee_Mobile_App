import 'package:flutter/material.dart';
import 'mentee_dashboard_screen.dart';

class MenteeAcknowledgmentScreen extends StatefulWidget {
  const MenteeAcknowledgmentScreen({super.key});

  @override
  State<MenteeAcknowledgmentScreen> createState() => _MenteeAcknowledgmentScreenState();
}

class _MenteeAcknowledgmentScreenState extends State<MenteeAcknowledgmentScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentee Acknowledgment'),
        backgroundColor: const Color(0xFF005487),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mentee Acknowledgment Form',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Please read and acknowledge the following:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I acknowledge that I have watched and attended the Mentee Orientation and understand how to achieve and maintain "Active Status" in the program each semester.',
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'I understand that if I end my program membership or take a brief leave, I must submit the Mentee Leave form.',
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'I will register for the Success Mentor Program in WCONLINE using the steps presented in Orientation and will use the SMP WCONLINE portal to book and edit appointments with my mentor(s).',
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'I also acknowledge that SMP mentors are fellow students—just as they respect my time and boundaries, I will respect theirs—and that they follow FERPA guidelines and are mandated reporters (for more information, see UC Merced\'s FERPA page).',
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Acknowledgment checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isAcknowledged,
                      activeColor: const Color(0xFF005487),
                      onChanged: (value) {
                        setState(() {
                          _isAcknowledged = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'I have read and agree to the statements above',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Full name signature field
                const Text(
                  'Please type your full name to complete the Mentee Acknowledgment Form:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Type your full legal name here',
                    border: OutlineInputBorder(),
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
                const Text(
                  'Date:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateTime.now().toString().split(' ')[0],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005487),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
    );
  }
}