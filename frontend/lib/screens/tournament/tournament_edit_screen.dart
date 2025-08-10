// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../components/custom_toast.dart';
import '../../config/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../services/db/repositories/tournament_repository.dart';
import '../../utils/image_picker_util.dart';

class TournamentEditScreen extends StatefulWidget {
  final Tournament tournament;
  const TournamentEditScreen({super.key, required this.tournament});

  @override
  State<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends State<TournamentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController locationController;
  late final TextEditingController sportIdController;
  late final TextEditingController minAgeController;
  late final TextEditingController maxAgeController;
  late final TextEditingController startDateController;
  late final TextEditingController endDateController;
  late final TextEditingController countryController;

  Level? selectedLevel;
  Gender? selectedGender;
  File? bannerImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    titleController = TextEditingController(text: t.title);
    descriptionController = TextEditingController(text: t.description ?? '');
    locationController = TextEditingController(text: t.location);
    sportIdController = TextEditingController(text: t.sportId);
    minAgeController = TextEditingController(text: t.minAge?.toString() ?? '');
    maxAgeController = TextEditingController(text: t.maxAge?.toString() ?? '');
    startDateController = TextEditingController(text: t.startDate);
    endDateController = TextEditingController(text: t.endDate);
    countryController = TextEditingController(text: t.country ?? '');
    selectedLevel = t.level;
    selectedGender = t.gender;
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

  Future<void> _pickBanner() async {
    final picked = await ImagePickerUtil.pickImageFromGallery();
    if (picked != null) {
      setState(() => bannerImage = picked);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final updated = widget.tournament.copyWith(
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
        startDate: startDateController.text.trim(),
        endDate: endDateController.text.trim(),
      );

      final saved =
          await TournamentRepository.instance.updateTournament(updated);
      CustomToast.showSuccess(message: 'Tournament updated');
      if (context.mounted) context.pop(saved);
    } catch (e) {
      CustomToast.showError(message: 'Update failed: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF30363D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF30363D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.linkedInBlue),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Edit Tournament'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF30363D)),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: bannerImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(bannerImage!, fit: BoxFit.cover),
                        )
                      : (widget.tournament.bannerUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: widget.tournament.bannerUrl!,
                                fit: BoxFit.cover,
                                placeholder: (c, _) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (c, _, __) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 40),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.image_outlined,
                                      color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text('Tap to add banner',
                                      style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                  label: 'Title',
                  controller: titleController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              _buildTextField(
                  label: 'Description',
                  controller: descriptionController,
                  maxLines: 4),
              _buildTextField(
                  label: 'Location',
                  controller: locationController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Start Date',
                      controller: startDateController,
                      readOnly: true,
                      onTap: () => _selectDate(startDateController),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'End Date',
                      controller: endDateController,
                      readOnly: true,
                      onTap: () => _selectDate(endDateController),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Level>(
                      value: selectedLevel,
                      decoration: _dropdownDecoration(),
                      dropdownColor: const Color(0xFF1E1E1E),
                      items: Level.values
                          .map((l) => DropdownMenuItem(
                              value: l,
                              child: Text(l.value,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => selectedLevel = v),
                      iconEnabledColor: Colors.white70,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: selectedGender,
                      decoration: _dropdownDecoration(),
                      dropdownColor: const Color(0xFF1E1E1E),
                      items: Gender.values
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.value,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => selectedGender = v),
                      iconEnabledColor: Colors.white70,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(label: 'Country', controller: countryController),
              _buildTextField(
                  label: 'Sport Id',
                  controller: sportIdController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          label: 'Min Age',
                          controller: minAgeController,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(
                          label: 'Max Age',
                          controller: maxAgeController,
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.linkedInBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.linkedInBlue),
      ),
    );
  }
}
