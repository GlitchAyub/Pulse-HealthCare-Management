import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';
import '../app_select.dart';

class PatientRegistrationCard extends StatefulWidget {
  const PatientRegistrationCard({
    super.key,
    required this.api,
    required this.onPatientRegistered,
  });

  final HealthReachApi api;
  final Future<void> Function() onPatientRegistered;

  @override
  State<PatientRegistrationCard> createState() =>
      _PatientRegistrationCardState();
}

class _PatientRegistrationCardState extends State<PatientRegistrationCard> {
  static const List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const List<String> _genders = ['male', 'female', 'other'];

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _bloodType;
  bool _createUserAccount = false;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _familyHistoryController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    setState(() {
      _dateOfBirth = picked;
      _dateOfBirthController.text = _formatDate(picked);
    });
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) return;

    final payload = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'createUserAccount': _createUserAccount,
    };
    if (_dateOfBirth != null) {
      payload['dateOfBirth'] = _formatDate(_dateOfBirth!);
    }
    if (_gender != null && _gender!.isNotEmpty) {
      payload['gender'] = _gender;
    }
    if (_bloodType != null && _bloodType!.isNotEmpty) {
      payload['bloodType'] = _bloodType;
    }
    _putIfNotEmpty(payload, 'phone', _phoneController.text);
    _putIfNotEmpty(payload, 'address', _addressController.text);
    _putIfNotEmpty(payload, 'allergies', _allergiesController.text);
    _putIfNotEmpty(payload, 'medicalHistory', _medicalHistoryController.text);
    _putIfNotEmpty(payload, 'familyHistory', _familyHistoryController.text);
    if (_createUserAccount) {
      _putIfNotEmpty(payload, 'email', _emailController.text);
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.api.createPatient(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient registered successfully.')),
      );
      _resetForm();
      await widget.onPatientRegistered();
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : 'Failed to register patient.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fullNameController.clear();
    _dateOfBirthController.clear();
    _phoneController.clear();
    _addressController.clear();
    _allergiesController.clear();
    _medicalHistoryController.clear();
    _familyHistoryController.clear();
    _emailController.clear();
    setState(() {
      _dateOfBirth = null;
      _gender = null;
      _bloodType = null;
      _createUserAccount = false;
    });
  }

  void _putIfNotEmpty(
    Map<String, dynamic> payload,
    String key,
    String rawValue,
  ) {
    final value = rawValue.trim();
    if (value.isNotEmpty) {
      payload[key] = value;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_outlined,
                    color: AppTheme.deepBlue),
                const SizedBox(width: 8),
                Text('Register New Patient',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter patient full name',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final date = TextFormField(
                  controller: _dateOfBirthController,
                  readOnly: true,
                  onTap: _submitting ? null : _pickDateOfBirth,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                );
                final blood = AppDropdownFormField<String>(
                  value: _bloodType,
                  items: _bloodTypes
                      .map(
                        (bloodType) => DropdownMenuItem<String>(
                          value: bloodType,
                          child: Text(bloodType),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _bloodType = value),
                  decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    hintText: 'Select blood type',
                  ),
                );
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: date),
                      const SizedBox(width: 12),
                      Expanded(child: blood),
                    ],
                  );
                }
                return Column(
                  children: [
                    date,
                    const SizedBox(height: 12),
                    blood,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final gender = AppDropdownFormField<String>(
                  value: _gender,
                  items: _genders
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            '${value[0].toUpperCase()}${value.substring(1)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _gender = value),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    hintText: 'Select gender',
                  ),
                );
                final phone = TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: '+1-555-111-2222',
                  ),
                );
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: gender),
                      const SizedBox(width: 12),
                      Expanded(child: phone),
                    ],
                  );
                }
                return Column(
                  children: [
                    gender,
                    const SizedBox(height: 12),
                    phone,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Patient address',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create User Account',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Optional: also create patient login credentials',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _createUserAccount,
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() {
                              _createUserAccount = value;
                              if (!value) {
                                _emailController.clear();
                              }
                            }),
                  ),
                ],
              ),
            ),
            if (_createUserAccount) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'john@example.com',
                ),
                validator: (value) {
                  if (!_createUserAccount) return null;
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergiesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                hintText: 'Known allergies (e.g., Penicillin)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicalHistoryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Medical History',
                hintText: 'Known medical conditions and history',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familyHistoryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Family History',
                hintText: 'Relevant family history',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _submitting ? null : _resetForm,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_rounded),
                    label: Text(
                        _submitting ? 'Registering...' : 'Register Patient'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
