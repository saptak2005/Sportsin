import 'package:flutter/material.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/db/repositories/camp_opening_repository.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/services/db/db_provider.dart';

class OpeningApplicantsScreen extends StatefulWidget {
  final String openingId;
  final String openingTitle;

  const OpeningApplicantsScreen({
    super.key,
    required this.openingId,
    required this.openingTitle,
  });

  @override
  State<OpeningApplicantsScreen> createState() =>
      _OpeningApplicantsScreenState();
}

class _OpeningApplicantsScreenState extends State<OpeningApplicantsScreen> {
  List<ApplicantResponse> applicants = [];
  bool isLoading = true;
  String? errorMessage;
  bool isRecruiter = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadApplicants();
  }

  void _checkUserRole() {
    final currentUser = DbProvider.instance.cashedUser;
    isRecruiter = currentUser?.role == Role.recruiter;
  }

  Future<void> _loadApplicants() async {
    try {
      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result = await CampOpeningRepository.instance
          .getOpeningApplicants(widget.openingId);

      if (!mounted) return; // Check again after async operation

      setState(() {
        applicants = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Check again before setState

      setState(() {
        isLoading = false;
        errorMessage = _getErrorMessage(e.toString());
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Opening ID is required')) {
      return 'Invalid opening ID';
    } else if (error.contains('not found')) {
      return 'Opening not found';
    } else if (error.contains('unauthorized')) {
      return 'You are not authorized to view applicants for this opening';
    } else if (error.contains('forbidden')) {
      return 'Access denied - you can only view applicants for your own openings';
    }
    return 'Failed to load applicants';
  }

  Future<void> _acceptApplication(String applicantId) async {
    await _performAction(
      action: () => CampOpeningRepository.instance.acceptApplication(
        widget.openingId,
        applicantId,
      ),
      successMessage: 'Application accepted successfully!',
      errorMessage: 'Failed to accept application',
    );
  }

  Future<void> _rejectApplication(String applicantId) async {
    await _performAction(
      action: () => CampOpeningRepository.instance.rejectApplication(
        widget.openingId,
        applicantId,
      ),
      successMessage: 'Application rejected successfully!',
      errorMessage: 'Failed to reject application',
    );
  }

  Future<void> _performAction({
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      await action();

      CustomToast.showSuccess(message: successMessage);

      _loadApplicants();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      CustomToast.showError(message: errorMessage);
      debugPrint(e.toString());
    }
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(ApplicationStatus status) {
    final List<PopupMenuEntry<String>> items = [];

    // Only show accept option if the application is pending or rejected
    if (status == ApplicationStatus.pending ||
        status == ApplicationStatus.rejected) {
      items.add(
        const PopupMenuItem(
          value: 'accept',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Accept Application', 
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Only show reject option if the application is pending or accepted
    if (status == ApplicationStatus.pending ||
        status == ApplicationStatus.accepted) {
      items.add(
        const PopupMenuItem(
          value: 'reject',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Reject Application', 
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If no actions are available, show a disabled info item
    if (items.isEmpty) {
      items.add(
        PopupMenuItem(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'No actions available',
                  style: TextStyle(color: Colors.grey[400]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  Map<String, dynamic> _getStatusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return {
          'text': 'PENDING',
          'color': Colors.orange,
          'backgroundColor': Colors.orange.withOpacity(0.2),
        };
      case ApplicationStatus.accepted:
        return {
          'text': 'ACCEPTED',
          'color': Colors.green,
          'backgroundColor': Colors.green.withOpacity(0.2),
        };
      case ApplicationStatus.rejected:
        return {
          'text': 'REJECTED',
          'color': Colors.red,
          'backgroundColor': Colors.red.withOpacity(0.2),
        };
      case ApplicationStatus.withdrawn:
        return {
          'text': 'WITHDRAWN',
          'color': Colors.grey,
          'backgroundColor': Colors.grey.withOpacity(0.2),
        };
    }
  }

  String _formatDateOfBirth(String dob) {
    try {
      // Parse the date assuming it's in ISO format or other standard format
      DateTime parsedDate = DateTime.parse(dob);
      
      // Format to "19th July 2004" style
      String day = parsedDate.day.toString();
      String suffix = _getDaySuffix(parsedDate.day);
      String month = _getMonthName(parsedDate.month);
      String year = parsedDate.year.toString();
      
      return '$day$suffix $month $year';
    } catch (e) {
      // If parsing fails, return the original string
      return dob;
    }
  }

  String _formatAppliedDate(String appliedDate) {
    try {
      DateTime parsedDate = DateTime.parse(appliedDate);
      DateTime now = DateTime.now();
      
      // Calculate the difference
      Duration difference = now.difference(parsedDate);
      
      if (difference.inDays == 0) {
        // Same day - show time
        String hour = parsedDate.hour.toString().padLeft(2, '0');
        String minute = parsedDate.minute.toString().padLeft(2, '0');
        return 'Today at $hour:$minute';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        // Within a week - show day name
        List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return weekdays[parsedDate.weekday - 1];
      } else {
        // More than a week - show formatted date
        String day = parsedDate.day.toString();
        String suffix = _getDaySuffix(parsedDate.day);
        String month = _getMonthName(parsedDate.month);
        String year = parsedDate.year.toString();
        
        // Show year only if it's not current year
        if (parsedDate.year == now.year) {
          return '$day$suffix $month';
        } else {
          return '$day$suffix $month $year';
        }
      }
    } catch (e) {
      // If parsing fails, return the original string
      return appliedDate;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildApplicantCard(ApplicantResponse applicant, int index) {
    final applicantId = applicant.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161B22),
            const Color(0xFF1C2128),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.linkedInBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: applicant.profilePicture != null &&
                          applicant.profilePicture!.isNotEmpty
                      ? Image.network(
                          applicant.profilePicture!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.linkedInBlue.withOpacity(0.2),
                              child: Center(
                                child: Text(
                                  applicant.name.isNotEmpty
                                      ? applicant.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: AppColors.linkedInBlue,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.linkedInBlue.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.linkedInBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.linkedInBlue.withOpacity(0.2),
                          child: Center(
                            child: Text(
                              applicant.name.isNotEmpty
                                  ? applicant.name[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: AppColors.linkedInBlue,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${applicant.name} ${applicant.surname}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      applicant.email,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getStatusInfo(applicant.status)['backgroundColor'],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusInfo(applicant.status)['color'],
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
                              color: _getStatusInfo(applicant.status)['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _getStatusInfo(applicant.status)['text'],
                              style: TextStyle(
                                color: _getStatusInfo(applicant.status)['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isRecruiter)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  color: const Color(0xFF21262D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'accept':
                        await _acceptApplication(applicantId);
                        break;
                      case 'reject':
                        await _rejectApplication(applicantId);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      _buildPopupMenuItems(applicant.status),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                Row(
                  children: [
                    Icon(
                      Icons.send_outlined,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applied: ${_formatAppliedDate(applicant.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DOB: ${_formatDateOfBirth(applicant.dob)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Level: ${applicant.level.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Interest: ${applicant.interestLevel.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRecruiter ? 'Applicants' : 'My Application',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.openingTitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.linkedInBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.linkedInBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.linkedInBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  '${applicants.length}',
                  style: const TextStyle(
                    color: AppColors.linkedInBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplicants,
        color: AppColors.linkedInBlue,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.linkedInBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Loading applicants...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadApplicants,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.linkedInBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecruiter ? Icons.people_outline : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isRecruiter ? 'No applicants yet' : 'No application found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRecruiter
                  ? 'When players apply to this opening,\nthey will appear here.'
                  : 'You haven\'t applied to this opening yet.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: applicants.length,
      itemBuilder: (context, index) {
        return _buildApplicantCard(applicants[index], index);
      },
    );
  }
}
