import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/models/sport.dart';
import 'package:sportsin/models/address.dart';

import '../../models/camp_openning.dart';
import '../../services/db/repositories/camp_opening_repository.dart';

class OpeningCreationScreen extends StatefulWidget {
  const OpeningCreationScreen({super.key});

  @override
  State<OpeningCreationScreen> createState() => _OpeningCreationScreenState();
}

class _OpeningCreationScreenState extends State<OpeningCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _countryRestrictionController = TextEditingController();

  // Address controllers
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String? _selectedSport;
  String? _selectedMinLevel;
  OpeningStatus _status = OpeningStatus.open;

  List<Sport> _sports = [];
  bool _isLoadingSports = false;

  final List<String> _levelOptions = [
    'District',
    'State',
    'Country',
    'International'
  ];

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  Future<void> _loadSports() async {
    setState(() {
      _isLoadingSports = true;
    });

    try {
      final sports = await DbProvider.instance.getSports();
      if (mounted) {
        setState(() {
          _sports = sports;
          _isLoadingSports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSports = false;
        });
        CustomToast.showError(message: 'Failed to load sports');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _countryRestrictionController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _createJobOpening() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final address = Address(
          id: '',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          country: _countryController.text.trim(),
          state: _stateController.text.trim(),
          city: _cityController.text.trim(),
          street: _streetController.text.trim(),
          building: _buildingController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        );

        final campOpening = CampOpenning(
          id: '',
          title: _titleController.text.trim(),
          sportName: _selectedSport!.trim(),
          position: _positionController.text.trim(),
          companyName: _companyController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          address: address,
          minAge: _minAgeController.text.isEmpty
              ? null
              : int.tryParse(_minAgeController.text),
          maxAge: _maxAgeController.text.isEmpty
              ? null
              : int.tryParse(_maxAgeController.text),
          minLevel: _selectedMinLevel?.toLowerCase().trim(),
          minSalary: _minSalaryController.text.isEmpty
              ? null
              : int.tryParse(_minSalaryController.text),
          maxSalary: _maxSalaryController.text.isEmpty
              ? null
              : int.tryParse(_maxSalaryController.text),
          countryRestriction: _countryRestrictionController.text.isEmpty
              ? null
              : _countryRestrictionController.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          stats: {},
        );

        final createdOpening =
            await CampOpeningRepository.instance.createOpening(campOpening);

        if (mounted) {
          CustomToast.showSuccess(message: 'Job opening created successfully!');
          Navigator.pop(context, createdOpening);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Failed to create job opening';

          if (e.toString().contains('Opening title is required')) {
            errorMessage = 'Job title is required';
          } else if (e.toString().contains('Sport name is required')) {
            errorMessage = 'Please select a sport';
          } else if (e.toString().contains('Position is required')) {
            errorMessage = 'Position is required';
          } else if (e.toString().contains('Company name is required')) {
            errorMessage = 'Company name is required';
          } else if (e.toString().contains('Complete address is required')) {
            errorMessage = 'Complete address is required';
          }

          CustomToast.showError(message: errorMessage);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Create Job Opening',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.linkedInBlue.withOpacity(0.1),
                      const Color(0xFF21262D),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.linkedInBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.linkedInBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: AppColors.linkedInBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post a New Job Opening',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fill out the details to attract the best candidates',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Information
              _buildTextField(
                controller: _titleController,
                label: 'Job Title',
                hint: 'e.g., Youth Football Coach',
                icon: Icons.work_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Job title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _companyController,
                label: 'Company/Organization',
                hint: 'e.g., Manchester United FC',
                icon: Icons.business,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _positionController,
                      label: 'Position',
                      hint: 'e.g., Head Coach',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Position is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedSport,
                      label: 'Sports',
                      hint: 'Sport',
                      icon: Icons.sports,
                      items: _sports,
                      onChanged: (value) =>
                          setState(() => _selectedSport = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a sport';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Address Section
              const Text(
                'Address Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _countryController,
                label: 'Country',
                hint: 'e.g., United Kingdom',
                icon: Icons.public,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Country is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State/Province',
                      hint: 'e.g., England',
                      icon: Icons.map_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'State/Province is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'e.g., Manchester',
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _streetController,
                      label: 'Street',
                      hint: 'e.g., Old Trafford',
                      icon: Icons.streetview,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _buildingController,
                      label: 'Building',
                      hint: 'e.g., Building A',
                      icon: Icons.business,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _postalCodeController,
                label: 'Postal Code',
                hint: 'e.g., M16 0RA',
                icon: Icons.markunread_mailbox,
              ),

              const SizedBox(height: 20),

              // Country Restriction
              _buildTextField(
                controller: _countryRestrictionController,
                label: 'Country Restriction (Optional)',
                hint: 'e.g., UK, EU, Worldwide',
                icon: Icons.travel_explore,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _descriptionController,
                label: 'Job Description',
                hint:
                    'Describe the role, responsibilities, and requirements...',
                icon: Icons.description,
                maxLines: 5,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Job description is required';
                  }
                  if (value!.length < 50) {
                    return 'Description should be at least 50 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Salary Range
              const Text(
                'Salary Range (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minSalaryController,
                      label: '',
                      hint: 'Min Salary',
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxSalaryController,
                      label: '',
                      hint: 'Max Salary',
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Age Requirements
              const Text(
                'Age Requirements (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minAgeController,
                      label: '',
                      hint: 'Min Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxAgeController,
                      label: '',
                      hint: 'Max Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildStringDropdownField(
                value: _selectedMinLevel,
                label: 'Minimum Level/Experience',
                hint: 'Select minimum level',
                icon: Icons.star_outline,
                items: _levelOptions,
                onChanged: (value) => setState(() => _selectedMinLevel = value),
              ),

              const SizedBox(height: 24),

              // Status
              const Text(
                'Opening Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusOption(
                      'Open',
                      'Accept applications',
                      OpeningStatus.open,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusOption(
                      'Draft',
                      'Save as draft',
                      OpeningStatus.closed,
                      Colors.orange,
                      Icons.edit,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createJobOpening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isLoading ? Colors.grey[600] : AppColors.linkedInBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isLoading ? 0 : 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Create Job Opening',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.linkedInBlue, size: 20)
                : null,
            filled: true,
            fillColor: const Color(0xFF21262D),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.linkedInBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<Sport> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          decoration: InputDecoration(
            hintText: _isLoadingSports ? 'Sport' : hint,
            hintStyle: const TextStyle(color: Colors.white),
            prefixIcon: Icon(icon, color: AppColors.linkedInBlue, size: 20),
            filled: true,
            fillColor: const Color(0xFF21262D),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.linkedInBlue,
                width: 2,
              ),
            ),
          ),
          dropdownColor: const Color(0xFF21262D),
          style: const TextStyle(color: Colors.white),
          items: _isLoadingSports
              ? null
              : items.map((Sport sport) {
                  return DropdownMenuItem<String>(
                    value: sport.name,
                    child: Text(
                      sport.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
          onChanged: _isLoadingSports ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildStringDropdownField({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[100]),
            prefixIcon: Icon(icon, color: AppColors.linkedInBlue, size: 20),
            filled: true,
            fillColor: const Color(0xFF21262D),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.linkedInBlue,
                width: 2,
              ),
            ),
          ),
          dropdownColor: const Color(0xFF21262D),
          style: const TextStyle(color: Colors.white),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatusOption(
    String title,
    String subtitle,
    OpeningStatus status,
    Color color,
    IconData icon,
  ) {
    final isSelected = _status == status;

    return GestureDetector(
      onTap: () => setState(() => _status = status),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
