import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/services/auth/auth_user.dart';
import 'package:sportsin/services/db/db_model.dart';
import 'package:sportsin/services/image/image_service.dart';
import 'package:sportsin/utils/image_picker_util.dart';
import 'package:sportsin/models/user.dart';
import 'package:sportsin/models/player.dart';
import 'package:sportsin/models/recruiter.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/components/custom_text_field.dart';
import 'package:sportsin/components/custom_button.dart';
import 'package:sportsin/components/custom_dropdown_field.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/config/routes/route_names.dart';

class CompleteOrUpdateProfileScreen extends StatefulWidget {
  final AuthUser authUser;
  final DbModel dbModel;
  final bool isEditMode;

  const CompleteOrUpdateProfileScreen({
    super.key,
    required this.authUser,
    required this.dbModel,
    this.isEditMode = false,
  });

  @override
  State<CompleteOrUpdateProfileScreen> createState() =>
      _CompleteOrUpdateProfileScreenState();
}

class _CompleteOrUpdateProfileScreenState
    extends State<CompleteOrUpdateProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _aboutController;
  late final TextEditingController _emailController;
  late final TextEditingController _roleController;
  late final TextEditingController _userNameController;
  late final TextEditingController _referralCodeController;
  late final TextEditingController _interestCountryController;

  late final TextEditingController _organizationNameController;
  late final TextEditingController _organizationIdController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _positionController;

  final _formKey = GlobalKey<FormState>();

  Gender? _selectedGender;
  Level? _selectedLevel;
  Level? _selectedInterestLevel;
  bool _isLoading = false;
  DateTime? _selectedDate;
  File? _selectedProfileImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    if (widget.isEditMode) {
      _populateFieldsFromExistingUser();
    }
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dobController = TextEditingController();
    _userNameController = TextEditingController();
    _aboutController = TextEditingController();
    _emailController = TextEditingController(text: widget.authUser.email);
    _roleController = TextEditingController(text: widget.authUser.role.name);
    _referralCodeController = TextEditingController();
    _interestCountryController = TextEditingController();

    _organizationNameController = TextEditingController();
    _organizationIdController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _positionController = TextEditingController();
  }

  void _populateFieldsFromExistingUser() {
    final user = widget.dbModel.cashedUser;
    if (user != null) {
      _firstNameController.text = user.name;
      _lastNameController.text = user.surname;
      _dobController.text = user.dob;
      _userNameController.text = user.userName;
      _selectedGender = user.gender;
      _profileImageUrl = user.profilePicture;

      if (user.middleName != null) {
        _middleNameController.text = user.middleName!;
      }

      if (user.about != null) {
        _aboutController.text = user.about!;
      }

      if (user is Player) {
        _selectedLevel = user.level;
        _selectedInterestLevel = user.interestLevel;
        if (user.interestCountry != null) {
          _interestCountryController.text = user.interestCountry!;
        }
      } else if (user is Recruiter) {
        _organizationNameController.text = user.organizationName;
        _organizationIdController.text = user.organizationId;
        _phoneNumberController.text = user.phoneNumber;
        _positionController.text = user.position;
      }

      try {
        _selectedDate = DateTime.parse(user.dob);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _userNameController.dispose();
    _interestCountryController.dispose();
    _organizationNameController.dispose();
    _organizationIdController.dispose();
    _phoneNumberController.dispose();
    _positionController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = widget.authUser.role == Role.player;
    final isRecruiter = widget.authUser.role == Role.recruiter;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isEditMode ? 'Edit Profile' : 'Complete Your Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Profile Picture Section
              _buildProfilePictureSection(),
              const SizedBox(height: 30),

              // Basic Information Section
              _buildBasicInfoSection(),

              // Role-specific sections
              if (isPlayer) ...[
                const SizedBox(height: 30),
                _buildPlayerSpecificSection(),
              ],

              if (isRecruiter) ...[
                const SizedBox(height: 30),
                _buildRecruiterSpecificSection(),
              ],

              const SizedBox(height: 30),

              // About Field
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(
                  labelText: 'About (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 30),
              if (!widget.isEditMode) ...[
                CustomTextField(
                  controller: _referralCodeController,
                  labelText: 'Referral Code (Optional)',
                ),
                const SizedBox(height: 30),
              ],

              // Submit Button
              CustomButton(
                text: widget.isEditMode ? 'Update Profile' : 'Complete Profile',
                onPressed: _isLoading ? () {} : _submitProfile,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _selectedProfileImage != null
                ? FileImage(_selectedProfileImage!) as ImageProvider
                : (_profileImageUrl != null &&
                        _profileImageUrl!.isNotEmpty &&
                        _profileImageUrl!.startsWith('http'))
                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                    : null,
            child: (_selectedProfileImage == null &&
                    (_profileImageUrl == null ||
                        _profileImageUrl!.isEmpty ||
                        !_profileImageUrl!.startsWith('http')))
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isUploadingImage ? Colors.grey : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field (Read-only)
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.lock, color: Colors.grey),
          ),
          readOnly: true,
        ),

        const SizedBox(height: 16),

        // Role Field (Read-only)
        TextFormField(
          controller: _roleController,
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.lock, color: Colors.grey),
          ),
          readOnly: true,
        ),

        const SizedBox(height: 16),

        // First Name Field
        CustomTextField(
          controller: _firstNameController,
          labelText: 'First Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Middle Name Field (Optional)
        CustomTextField(
          controller: _middleNameController,
          labelText: 'Middle Name (Optional)',
        ),

        const SizedBox(height: 16),

        // Last Name Field
        CustomTextField(
          controller: _lastNameController,
          labelText: 'Last Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _userNameController,
          labelText: 'Username',
          validator: (p0) =>
              p0 == null || p0.isEmpty ? 'Username is required' : null,
        ),
        const SizedBox(height: 16),

        // Date of Birth Field
        TextFormField(
          controller: _dobController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Date of birth is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Gender Dropdown
        CustomDropdownField(
          value: _selectedGender?.value,
          hintText: 'Select your gender',
          items: Gender.values.map((gender) => gender.value).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedGender = Gender.values.firstWhere(
                (gender) => gender.value == value,
                orElse: () => Gender.ratherNotSay,
              );
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Gender is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPlayerSpecificSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Player Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Player Level
        CustomDropdownField(
          value: _selectedLevel?.value,
          hintText: 'Select your current level',
          items: Level.values.map((level) => level.value).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedLevel = Level.values.firstWhere(
                (level) => level.value == value,
                orElse: () => Level.personal,
              );
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Current level is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Interest Level
        CustomDropdownField(
          value: _selectedInterestLevel?.value,
          hintText: 'Select your interest level',
          items: Level.values.map((level) => level.value).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedInterestLevel = Level.values.firstWhere(
                (level) => level.value == value,
                orElse: () => Level.personal,
              );
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Interest level is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Interest Country (Optional)
        CustomTextField(
          controller: _interestCountryController,
          labelText: 'Interest Country (Optional)',
        ),
      ],
    );
  }

  Widget _buildRecruiterSpecificSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Organization Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Organization Name
        CustomTextField(
          controller: _organizationNameController,
          labelText: 'Organization Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Organization name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Organization ID
        CustomTextField(
          controller: _organizationIdController,
          labelText: 'Organization ID',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Organization ID is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Phone Number
        CustomTextField(
          controller: _phoneNumberController,
          labelText: 'Phone Number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Position
        CustomTextField(
          controller: _positionController,
          labelText: 'Position',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Position is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dobController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final File? pickedImage =
          await ImagePickerUtil.showImagePickerDialog(context);

      if (pickedImage != null) {
        setState(() {
          _isUploadingImage = true;
        });

        try {
          final imageUrl =
              await ImageService.instance.uploadProfilePicture(pickedImage);

          if (mounted) {
            setState(() {
              _selectedProfileImage = pickedImage;
              _profileImageUrl = imageUrl;
              _isUploadingImage = false;
            });

            CustomToast.showSuccess(
                message: 'Profile picture uploaded successfully!');
          }
        } catch (e) {
          debugPrint('CompleteProfileScreen: Image upload failed: $e');
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
            });
            CustomToast.showError(
                message: 'Failed to upload profile picture: $e');
          }
        }
      } else {
        debugPrint(
            'CompleteProfileScreen: No image selected or picker cancelled');
      }
    } catch (e) {
      debugPrint('CompleteProfileScreen: Error in _pickProfileImage: $e');
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        CustomToast.showError(message: 'Error selecting image: $e');
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      CustomToast.showError(message: 'Please select your gender');
      return;
    }

    if (widget.authUser.role == Role.player) {
      if (_selectedLevel == null || _selectedInterestLevel == null) {
        CustomToast.showError(
            message: 'Please fill all required player fields');
        return;
      }
    } else if (widget.authUser.role == Role.recruiter) {
      if (_organizationNameController.text.isEmpty ||
          _organizationIdController.text.isEmpty ||
          _phoneNumberController.text.isEmpty ||
          _positionController.text.isEmpty) {
        CustomToast.showError(
            message: 'Please fill all required recruiter fields');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User user;
      final existingUser = widget.isEditMode ? widget.dbModel.cashedUser : null;

      if (widget.authUser.role == Role.player) {
        user = Player(
          id: widget.authUser.id,
          createdAt:
              existingUser?.createdAt ?? DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          userName: _userNameController.text.trim().isEmpty
              ? (existingUser?.userName ?? 'user_${widget.authUser.id}')
              : _userNameController.text.trim(),
          email: widget.authUser.email,
          role: widget.authUser.role,
          name: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          surname: _lastNameController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender!,
          profilePicture: _profileImageUrl,
          about: _aboutController.text.trim().isEmpty
              ? null
              : _aboutController.text.trim(),
          level: _selectedLevel!,
          interestLevel: _selectedInterestLevel!,
          interestCountry: _interestCountryController.text.trim().isEmpty
              ? null
              : _interestCountryController.text.trim(),
          referralCode: _referralCodeController.text.trim().isEmpty
              ? null
              : _referralCodeController.text.trim(),
        );
      } else if (widget.authUser.role == Role.recruiter) {
        user = Recruiter(
          id: widget.authUser.id,
          createdAt:
              existingUser?.createdAt ?? DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          userName: _userNameController.text.trim().isEmpty
              ? (existingUser?.userName ?? 'user_${widget.authUser.id}')
              : _userNameController.text.trim(),
          email: widget.authUser.email,
          role: widget.authUser.role,
          name: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          surname: _lastNameController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender!,
          profilePicture: _profileImageUrl,
          about: _aboutController.text.trim().isEmpty
              ? null
              : _aboutController.text.trim(),
          organizationName: _organizationNameController.text.trim(),
          organizationId: _organizationIdController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          position: _positionController.text.trim(),
          referralCode: _referralCodeController.text.trim().isEmpty
              ? null
              : _referralCodeController.text.trim(),
        );
      } else {
        user = User(
          id: widget.authUser.id,
          createdAt:
              existingUser?.createdAt ?? DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          userName: _userNameController.text.trim().isEmpty
              ? (existingUser?.userName ?? 'user_${widget.authUser.id}')
              : _userNameController.text.trim(),
          email: widget.authUser.email,
          role: widget.authUser.role,
          name: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          surname: _lastNameController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender!,
          profilePicture: _profileImageUrl,
          about: _aboutController.text.trim().isEmpty
              ? null
              : _aboutController.text.trim(),
          referralCode: _referralCodeController.text.trim().isEmpty
              ? null
              : _referralCodeController.text.trim(),
        );
      }

      if (widget.isEditMode) {
        await widget.dbModel.updateUser(user);
        if (mounted) {
          CustomToast.showSuccess(message: 'Profile updated successfully!');
          context.pop();
        }
      } else {
        await widget.dbModel.createUser(user);
        if (mounted) {
          CustomToast.showSuccess(message: 'Profile completed successfully!');
          context.go(RouteNames.homePath);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
            message: widget.isEditMode
                ? 'Error updating profile: $e'
                : 'Error completing profile: $e');
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
