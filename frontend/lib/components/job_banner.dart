import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/models/camp_openning.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/services/db/repositories/camp_opening_repository.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/config/routes/route_names.dart';

class JobBanner extends StatelessWidget {
  final CampOpenning opening;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onViewApplicants;
  final Function(OpeningStatus)? onUpdateStatus;
  final bool showApplyButton;

  const JobBanner({
    super.key,
    required this.opening,
    this.onTap,
    this.onApply,
    this.onViewApplicants,
    this.onUpdateStatus,
    this.showApplyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed(
              RouteNames.openingDetails,
              extra: opening,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildJobDetails(),
                const SizedBox(height: 16),
                _buildRequirementsAndSalary(),
                if (showApplyButton) ...[
                  const SizedBox(height: 20),
                  _buildActionButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Company Logo/Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.linkedInBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              opening.companyName.isNotEmpty
                  ? opening.companyName.substring(0, 1).toUpperCase()
                  : 'C',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.linkedInBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Job Title and Company
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                opening.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                opening.companyName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opening.position,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.linkedInBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Status Badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isOpen = opening.status == OpeningStatus.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 12,
              color: isOpen ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Description',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            opening.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsAndSalary() {
    return Row(
      children: [
        // Requirements Section
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requirements',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (opening.minAge != null || opening.maxAge != null)
                _buildRequirementChip(
                  Icons.cake,
                  _getAgeRange(),
                ),
              if (opening.minLevel != null)
                _buildRequirementChip(
                  Icons.star,
                  opening.minLevel!,
                ),
              if (opening.countryRestriction != null)
                _buildRequirementChip(
                  Icons.location_on,
                  opening.countryRestriction!,
                ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Salary Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Salary Range',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.linkedInBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getSalaryRange(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.linkedInBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final isOpen = opening.status == OpeningStatus.open;
    final currentUser = DbProvider.instance.cashedUser;
    final isRecruiter = currentUser?.role == Role.recruiter;
    final isOpeningCreator = onUpdateStatus !=
        null; // If status update callback is provided, user is the creator

    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (context) {
          // For opening creators (recruiters viewing their own openings), show status management
          if (isRecruiter && isOpeningCreator) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (onViewApplicants != null) {
                      onViewApplicants!();
                    } else {
                      viewOpeningApplicants(opening.id, context,
                          openingTitle: opening.title);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.linkedInBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'View Applicants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status toggle button
                OutlinedButton(
                  onPressed: () {
                    final newStatus =
                        isOpen ? OpeningStatus.closed : OpeningStatus.open;
                    onUpdateStatus!(newStatus);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isOpen ? Colors.red : Colors.green,
                    side: BorderSide(
                      color: isOpen ? Colors.red : Colors.green,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOpen ? Icons.close : Icons.check_circle,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOpen ? 'Close Opening' : 'Reopen Opening',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // For recruiters viewing all openings (not their own), show regular View Applicants button
          if (isRecruiter) {
            return ElevatedButton(
              onPressed: () {
                if (onViewApplicants != null) {
                  onViewApplicants!();
                } else {
                  viewOpeningApplicants(opening.id, context,
                      openingTitle: opening.title);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.linkedInBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'View Applicants',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          // For players, show different buttons based on application status
          if (!isOpen) {
            return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Position Closed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Check if user has applied and their application status
          if (opening.isApplied && opening.applicationStatus != null) {
            switch (opening.applicationStatus!) {
              case ApplicationStatus.pending:
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Application Pending',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _withdrawApplication(opening.id, currentUser!.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Withdraw Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              case ApplicationStatus.accepted:
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Application Accepted',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              case ApplicationStatus.rejected:
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Application Rejected',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              case ApplicationStatus.withdrawn:
                return ElevatedButton(
                  onPressed: isOpen
                      ? () {
                          if (onApply != null) {
                            onApply!();
                          } else {
                            applyToOpening(opening.id, context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOpen ? AppColors.linkedInBlue : Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isOpen ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isOpen ? Icons.send : Icons.block, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isOpen ? 'Apply Again' : 'Position Closed',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
            }
          }

          // Default case: user hasn't applied yet
          return ElevatedButton(
            onPressed: isOpen
                ? () {
                    if (onApply != null) {
                      onApply!();
                    } else {
                      applyToOpening(opening.id, context);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isOpen ? AppColors.linkedInBlue : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isOpen ? 2 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isOpen ? Icons.send : Icons.block, size: 18),
                const SizedBox(width: 8),
                Text(
                  isOpen ? 'Apply Now' : 'Position Closed',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getAgeRange() {
    if (opening.minAge != null && opening.maxAge != null) {
      return '${opening.minAge}-${opening.maxAge} years';
    } else if (opening.minAge != null) {
      return '${opening.minAge}+ years';
    } else if (opening.maxAge != null) {
      return 'Up to ${opening.maxAge} years';
    }
    return 'Any age';
  }

  String _getSalaryRange() {
    if (opening.minSalary != null && opening.maxSalary != null) {
      return '\$${_formatSalary(opening.minSalary!)} - \$${_formatSalary(opening.maxSalary!)}';
    } else if (opening.minSalary != null) {
      return '\$${_formatSalary(opening.minSalary!)}+';
    } else if (opening.maxSalary != null) {
      return 'Up to \$${_formatSalary(opening.maxSalary!)}';
    }
    return 'Negotiable';
  }

  String _formatSalary(int salary) {
    if (salary >= 1000000) {
      return '${(salary / 1000000).toStringAsFixed(1)}M';
    } else if (salary >= 1000) {
      return '${(salary / 1000).toStringAsFixed(0)}K';
    }
    return salary.toString();
  }
}

/// Function for players to withdraw from a job opening
Future<void> _withdrawApplication(String openingId, String applicantId) async {
  try {
    await DbProvider.instance.withdrawApplication(openingId, applicantId);
    CustomToast.showSuccess(message: 'Application withdrawn successfully!');
  } catch (e) {
    CustomToast.showError(message: 'Failed to withdraw application');
  }
}

/// Function for players to apply to a job opening
Future<void> applyToOpening(String openingId, BuildContext context) async {
  try {
    if (openingId.isEmpty) {
      CustomToast.showError(message: 'Invalid opening ID');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.linkedInBlue,
          ),
        );
      },
    );

    await CampOpeningRepository.instance.applyToOpening(openingId);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    CustomToast.showSuccess(message: 'Application submitted successfully!');
  } catch (e) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    String errorMessage = 'Failed to submit application';

    if (e.toString().contains('Opening ID is required')) {
      errorMessage = 'Invalid opening ID';
    } else if (e.toString().contains('already applied')) {
      errorMessage = 'You have already applied to this opening';
    } else if (e.toString().contains('not found')) {
      errorMessage = 'Opening not found or no longer available';
    } else if (e.toString().contains('closed')) {
      errorMessage = 'This opening is no longer accepting applications';
    } else if (e.toString().contains('unauthorized')) {
      errorMessage = 'You must be logged in to apply';
    }

    CustomToast.showError(message: errorMessage);
  }
}

/// Function for recruiters to view applicants for their job opening
Future<void> viewOpeningApplicants(String openingId, BuildContext context,
    {String? openingTitle}) async {
  try {
    if (openingId.isEmpty) {
      CustomToast.showError(message: 'Invalid opening ID');
      return;
    }

    context.pushNamed(
      RouteNames.openingApplicants,
      queryParameters: {
        'openingId': openingId,
        'openingTitle': openingTitle ?? 'Job Opening',
      },
    );
  } catch (e) {
    CustomToast.showError(message: 'Failed to open applicants screen');
  }
}
