import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/components/custom_toast.dart';
import '../../config/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../services/db/db_provider.dart';
import '../../services/db/db_exceptions.dart';
import '../../utils/image_picker_util.dart';

class TournamentCreationScreen extends StatefulWidget {
  const TournamentCreationScreen({super.key});

  @override
  State<TournamentCreationScreen> createState() =>
      _TournamentCreationScreenState();
}

class _TournamentCreationScreenState extends State<TournamentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController sportIdController =
      TextEditingController(text: '9b1477e2-e9d3-43b1-a4f4-63a130c5cc47');
  final TextEditingController minAgeController = TextEditingController();
  final TextEditingController maxAgeController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  Level? selectedLevel;
  Gender? selectedGender;
  File? bannerImage;
  bool isLoading = false;

  final DbProvider _dbProvider = DbProvider.instance;

  void _createTournament() async {
    if (_formKey.currentState!.validate()) {
      final dateValidation = _validateDateRange();
      if (dateValidation != null) {
        CustomToast.showError(message: dateValidation);
        return;
      }

      if (bannerImage == null) {
        CustomToast.showError(message: 'Please upload a banner image');
        return;
      }

      if (minAgeController.text.isNotEmpty &&
          maxAgeController.text.isNotEmpty) {
        final minAge = int.tryParse(minAgeController.text);
        final maxAge = int.tryParse(maxAgeController.text);

        if (minAge != null && maxAge != null && minAge > maxAge) {
          CustomToast.showError(
            message: 'Minimum age cannot be greater than maximum age',
          );
          return;
        }
      }

      setState(() {
        isLoading = true;
      });

      try {
        final user = _dbProvider.cashedUser;
        if (user == null) {
          CustomToast.showError(message: 'User not authenticated');
          setState(() {
            isLoading = false;
          });
          return;
        }

        final tournament = Tournament(
          id: '',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          hostId: user.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          location: locationController.text.trim(),
          sportId: sportIdController.text.trim(),
          minAge: minAgeController.text.trim().isEmpty
              ? null
              : int.tryParse(minAgeController.text.trim()),
          maxAge: maxAgeController.text.trim().isEmpty
              ? null
              : int.tryParse(maxAgeController.text.trim()),
          level: selectedLevel,
          gender: selectedGender,
          country: countryController.text.trim().isEmpty
              ? null
              : countryController.text.trim(),
          status: TournamentStatus.scheduled,
          startDate: startDateController.text.trim(),
          endDate: endDateController.text.trim(),
          bannerUrl: null,
        );

        await _dbProvider.createTournament(tournament, bannerImage!);

        setState(() {
          isLoading = false;
        });

        CustomToast.showSuccess(message: 'Tournament created successfully!');
        _resetForm();
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        String errorMessage = 'Failed to create tournament';
        if (e is DbExceptions) {
          errorMessage = e.message ?? 'Unknown error occurred';
        }
        CustomToast.showError(message: errorMessage);
      }
    }
  }

  void _resetForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    sportIdController.clear();
    minAgeController.clear();
    maxAgeController.clear();
    startDateController.clear();
    endDateController.clear();
    countryController.clear();
    setState(() {
      selectedLevel = null;
      selectedGender = null;
      bannerImage = null;
      isLoading = false;
    });
  }

  void _pickBannerImage() async {
    final File? image = await ImagePickerUtil.showImagePickerDialog(context);
    if (image != null) {
      setState(() {
        bannerImage = image;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text =
            pickedDate.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  String? _validateAge(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number for $fieldName';
    }

    if (age < 1 || age > 150) {
      return '$fieldName must be between 1 and 150';
    }

    return null;
  }

  String? _validateDateRange() {
    if (startDateController.text.isEmpty || endDateController.text.isEmpty) {
      return null;
    }

    final startDate = DateTime.tryParse(startDateController.text);
    final endDate = DateTime.tryParse(endDateController.text);

    if (startDate == null || endDate == null) {
      return null;
    }

    if (startDate.isBefore(DateTime.now())) {
      return 'Start date cannot be in the past';
    }

    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }

    return null;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    sportIdController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: AppColors.linkedInBlue),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.linkedInBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.linkedInBlue, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.linkedInBlue, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? label : controller.text,
                style: TextStyle(
                  color: controller.text.isNotEmpty
                      ? Colors.white
                      : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            ...Level.values.map((level) => ListTile(
                  title: Text(
                    level.toString().split('.').last,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: selectedLevel == level
                      ? Icon(Icons.check, color: AppColors.linkedInBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedLevel = level;
                    });
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Gender',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            ...Gender.values.map((gender) => ListTile(
                  title: Text(
                    gender.toString().split('.').last,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: selectedGender == gender
                      ? Icon(Icons.check, color: AppColors.linkedInBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedGender = gender;
                    });
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          'Create Tournament',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: AppColors.linkedInBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.linkedInBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: AppColors.linkedInBlue,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tournament Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fill in the information to create your tournament',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),

                // Banner Image Section
                _buildSectionTitle('Tournament Banner'),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickBannerImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.linkedInBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: bannerImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(
                              bannerImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: AppColors.linkedInBlue,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Add Tournament Banner',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Tap to select image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 25),

                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                SizedBox(height: 15),

                _buildTextField(
                  controller: titleController,
                  label: 'Tournament Name',
                  icon: Icons.sports,
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                SizedBox(height: 15),

                _buildTextField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                SizedBox(height: 25),

                // Location Section
                _buildSectionTitle('Location Details'),
                SizedBox(height: 15),

                _buildTextField(
                  controller: locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                  validator: (value) =>
                      value!.isEmpty ? 'Location is required' : null,
                ),
                SizedBox(height: 15),

                _buildTextField(
                  controller: countryController,
                  label: 'Country',
                  icon: Icons.public,
                ),
                SizedBox(height: 25),

                // Tournament Settings Section
                _buildSectionTitle('Tournament Settings'),
                SizedBox(height: 15),

                _buildTextField(
                  controller: sportIdController,
                  label: 'Sport ID',
                  icon: Icons.sports_soccer,
                  validator: (value) =>
                      value!.isEmpty ? 'Sport ID is required' : null,
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Level',
                        value: selectedLevel?.toString().split('.').last,
                        icon: Icons.bar_chart,
                        onTap: () => _showLevelPicker(),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Gender',
                        value: selectedGender?.toString().split('.').last,
                        icon: Icons.people,
                        onTap: () => _showGenderPicker(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: minAgeController,
                        label: 'Min Age',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validateAge(value, 'Minimum Age'),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildTextField(
                        controller: maxAgeController,
                        label: 'Max Age',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validateAge(value, 'Maximum Age'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),

                // Date Section
                _buildSectionTitle('Tournament Schedule'),
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        controller: startDateController,
                        label: 'Start Date',
                        icon: Icons.event_available,
                        onTap: () => _selectDate(context, startDateController),
                        validator: (value) =>
                            value!.isEmpty ? 'Start Date is required' : null,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildDateField(
                        controller: endDateController,
                        label: 'End Date',
                        icon: Icons.event_busy,
                        onTap: () => _selectDate(context, endDateController),
                        validator: (value) =>
                            value!.isEmpty ? 'End Date is required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createTournament,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.linkedInBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Create Tournament',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
