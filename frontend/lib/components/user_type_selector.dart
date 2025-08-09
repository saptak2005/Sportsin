import 'package:flutter/material.dart';
import '../config/constants/app_constants.dart';

/// A reusable component for selecting user type (Player or Recruiter)
class UserTypeSelector extends StatelessWidget {
  final String? selectedUserType;
  final ValueChanged<String?> onUserTypeSelected;

  const UserTypeSelector({
    super.key,
    required this.selectedUserType,
    required this.onUserTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Player Option
          _buildUserTypeOption(
            context: context,
            userType: AppConstants.userTypePlayer,
            title: AppConstants.playerLabel,
            description: AppConstants.playerDescription,
            icon: Icons.sports,
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
          // Recruiter Option
          _buildUserTypeOption(
            context: context,
            userType: AppConstants.userTypeRecruiter,
            title: AppConstants.recruiterLabel,
            description: AppConstants.recruiterDescription,
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption({
    required BuildContext context,
    required String userType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedUserType == userType;

    return InkWell(
      onTap: () => onUserTypeSelected(userType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: userType,
              groupValue: selectedUserType,
              onChanged: onUserTypeSelected,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
