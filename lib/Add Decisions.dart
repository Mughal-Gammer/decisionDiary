import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddDecisionScreen extends StatefulWidget {
  const AddDecisionScreen({super.key});

  @override
  State<AddDecisionScreen> createState() => _AddDecisionScreenState();
}

class _AddDecisionScreenState extends State<AddDecisionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _expectedController = TextEditingController();
  final _finalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveDecision() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;


      final decisionRef = FirebaseDatabase.instance
          .ref('users/${user?.uid}/decisions')
          .push();

      await decisionRef.set({
        'title': _titleController.text.trim(),
        'date': DateFormat('dd-MM-yyyy').format(_selectedDate),
        'reason': _reasonController.text.trim(),
        'expectedOutcome': _expectedController.text.trim(),
        'finalOutcome': _finalController.text.trim(),
        'createdAt': ServerValue.timestamp,
        'decisionId': decisionRef.key,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Decision saved'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return success flag
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${e.message ?? 'Failed to save'}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ An unexpected error occurred'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('Error saving decision: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    _expectedController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Decision'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Decisions'),
                  content: const Text(
                    'Document your choices to track patterns and improve decision-making over time.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            'Decision Title',
                            hint: 'e.g., "Accept job offer at XYZ"',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Decision Date',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _reasonController,
                          decoration: _buildInputDecoration(
                            'Reason for this decision',
                            hint: 'Why are you making this choice?',
                          ),
                          maxLines: 3,
                          style: Theme.of(context).textTheme.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please explain your reasoning';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _expectedController,
                          decoration: _buildInputDecoration(
                            'Expected Outcome',
                            hint: 'What do you hope will happen?',
                          ),
                          maxLines: 3,
                          style: Theme.of(context).textTheme.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please describe expected results';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _finalController,
                          decoration: _buildInputDecoration(
                            'Final Outcome (Optional)',
                            hint: 'If the actual result is not known, please update later!',
                          ),
                          maxLines: 3,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveDecision,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save Decision',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}