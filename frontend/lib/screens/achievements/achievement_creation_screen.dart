import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/models/achievement.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/screens/achievements/helpers/build_stat_text_field.dart';
import 'package:sportsin/screens/achievements/helpers/stat_controller.dart';
import 'package:sportsin/services/db/repositories/acheivement_repository.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import '../../components/custom_toast.dart';
import '../../utils/image_picker_util.dart';

class AchievementCreationScreen extends StatefulWidget {
  final String? achievementId;

  const AchievementCreationScreen({
    super.key,
    this.achievementId,
  });

  @override
  State<AchievementCreationScreen> createState() =>
      _AchievementCreationScreenState();
}

class _AchievementCreationScreenState extends State<AchievementCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _sportIdController =
      TextEditingController(text: '9b1477e2-e9d3-43b1-a4f4-63a130c5cc47');
  final List<StatControllerPair> _statsControllers = [];

  Level _selectedLevel = Level.district;
  String? _selectedCertificateUrl;
  bool _isLoading = false;
  bool _isEditing = false;
  Achievement? _currentAchievement;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.achievementId != null;
    if (_isEditing) {
      _loadAchievement();
    } else {
      _addStatField();
    }
  }

  void _addStatField() {
    setState(() {
      _statsControllers.add(StatControllerPair());
    });
  }

  void _removeStatField(int index) {
    setState(() {
      _statsControllers[index].dispose();
      _statsControllers.removeAt(index);
    });
  }

  Future<void> _loadAchievement() async {
    if (widget.achievementId == null) return;

    setState(() => _isLoading = true);
    try {
      final achievement = await AchievementRepository.instance
          .getAchievementById(widget.achievementId!);
      if (achievement != null && mounted) {
        setState(() {
          _currentAchievement = achievement;
          _tournamentController.text = achievement.tournament;
          _descriptionController.text = achievement.description;
          _dateController.text = achievement.date;
          _sportIdController.text = achievement.sportId;

          _selectedLevel = achievement.level;
          _selectedCertificateUrl = achievement.certificateUrl;
          _statsControllers.clear();
          if (achievement.stats.isNotEmpty) {
            try {
              final Map<String, dynamic> statsMap =
                  jsonDecode(achievement.stats);
              if (statsMap.isEmpty) {
                _addStatField();
              } else {
                statsMap.forEach((key, value) {
                  _statsControllers
                      .add(StatControllerPair.fromMap(key, value.toString()));
                });
              }
            } catch (e) {
              debugPrint('Error decoding stats JSON: $e');
              _addStatField();
            }
          } else {
            _addStatField();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(message: 'Failed to load achievement');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCertificate() async {
    final file = await ImagePickerUtil.showImagePickerDialog(context);
    if (file != null) {
      setState(() {
        _selectedCertificateUrl = file.path;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.linkedInBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format date as YYYY-MM-DD which is more standard
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = DbProvider.instance.cashedUser;
      if (currentUser == null) {
        throw Exception('User not found. Please login again.');
      }

      if (_tournamentController.text.trim().isEmpty) {
        throw Exception('Tournament name is required');
      }
      if (_sportIdController.text.trim().isEmpty) {
        throw Exception('Sport is required');
      }
      if (_dateController.text.trim().isEmpty) {
        throw Exception('Date is required');
      }
      final Map<String, String> statsMap = {};
      for (final pair in _statsControllers) {
        final key = pair.keyController.text.trim();
        final value = pair.valueController.text.trim();

        if (key.isNotEmpty) {
          statsMap[key] = value;
        }
      }

      final achievement = Achievement(
        id: _isEditing
            ? _currentAchievement!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id,
        tournament: _tournamentController.text,
        description: _descriptionController.text,
        date: _dateController.text,
        sportId: _sportIdController.text,
        level: _selectedLevel,
        stats: jsonEncode(statsMap),
        certificateUrl: null,
      );

      Achievement createdOrUpdated;
      if (_isEditing) {
        createdOrUpdated =
            await DbProvider.instance.updateAchievement(achievement);
        if (mounted) {
          CustomToast.showSuccess(message: 'Achievement updated successfully');
        }
      } else {
        createdOrUpdated =
            await DbProvider.instance.createAcheivement(achievement);
        if (mounted) {
          CustomToast.showSuccess(message: 'Achievement created successfully');
        }
      }

      if (_selectedCertificateUrl != null &&
          !_selectedCertificateUrl!.startsWith('http')) {
        final file = File(_selectedCertificateUrl!);
        if (await file.exists()) {
          await AchievementRepository.instance.uploadAchievementCertificate(
            achievementId: createdOrUpdated.id,
            certificateFile: file,
          );
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
            message:
                'Failed to \\${_isEditing ? 'update' : 'create'} achievement: \\$e');
      }
      debugPrint('Achievement creation error: \\$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tournamentController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _sportIdController.dispose();
    for (final pair in _statsControllers) {
      pair.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const SizedBox(width: 12),
            Text(
              _isEditing ? 'Edit Achievement' : 'Create Achievement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Container(
              color: const Color(0xFF121212),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.linkedInBlue,
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF121212),
                    Color(0xFF1A1A1A),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2A2A2A),
                              Color(0xFF1E1E1E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: AppColors.linkedInBlue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isEditing
                                  ? 'Update Your Achievement'
                                  : 'Add New Achievement',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEditing
                                  ? 'Make changes to your achievement details'
                                  : 'Share your success with the community',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Certificate Upload Section
                      _buildCertificateSection(),
                      const SizedBox(height: 25),

                      // Form Fields
                      _buildFormSection(),

                      const SizedBox(height: 25),

                      // Action Button
                      _buildActionButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCertificateSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1E1E1E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.linkedInBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Certificate Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickCertificate,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A3A3A),
                    Color(0xFF2A2A2A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedCertificateUrl != null
                      ? AppColors.linkedInBlue.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedCertificateUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _isEditing
                              ? Image.network(
                                  _selectedCertificateUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 60,
                                          color: AppColors.linkedInBlue,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Certificate',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Image.file(
                                  File(_selectedCertificateUrl!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 60,
                                          color: AppColors.linkedInBlue,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Certificate',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 50,
                          color: AppColors.linkedInBlue,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Upload Certificate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to select image',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1E1E1E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.linkedInBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Achievement Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tournament Name
          _buildModernTextField(
            controller: _tournamentController,
            label: 'Tournament/Competition',
            icon: Icons.sports_soccer_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter tournament name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Sport ID
          _buildModernTextField(
            controller: _sportIdController,
            label: 'Sport',
            icon: Icons.sports_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter sport';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Description
          _buildModernTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Date
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: _buildModernTextField(
                controller: _dateController,
                label: 'Date Achieved',
                icon: Icons.calendar_today_rounded,
                readOnly: true,
                suffixIcon: Icons.arrow_drop_down_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select date';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildDynamicStatsInputs(),

          // Level Dropdown
          _buildModernDropdown(),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    IconData? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF3A3A3A),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.grey[400])
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.linkedInBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Competition Level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedLevel.value,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF2A2A2A),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.emoji_events_rounded, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: Level.values.map((level) {
              return DropdownMenuItem(
                value: level.value,
                child: Text(
                  level.value,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLevel = Level.values
                      .firstWhere((level) => level.value == newValue);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicStatsInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats / Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _statsControllers.length,
          itemBuilder: (context, index) {
            final pair = _statsControllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: BuildStatTextField(
                        controller: pair.keyController,
                        hintText: 'Stat Name (e.g., Score)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BuildStatTextField(
                        controller: pair.valueController,
                        hintText: 'Value (e.g., 100)'),
                  ),
                  // Show remove button only if there is more than one stat field
                  if (_statsControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent),
                      onPressed: () => _removeStatField(index),
                    )
                  else
                    const SizedBox(width: 48), // Keep alignment consistent
                ],
              ),
            );
          },
        ),
        // Button to add a new stat field
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.linkedInBlue),
            label: const Text('Add Stat',
                style: TextStyle(color: AppColors.linkedInBlue)),
            onPressed: _addStatField,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.linkedInBlue,
            Colors.blueAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _saveAchievement,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditing ? Icons.update_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing
                            ? 'Update Achievement'
                            : 'Create Achievement',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
