import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tournament.dart';
import '../../models/enums.dart';
import '../../config/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/db/db_provider.dart';
import '../../components/custom_toast.dart';
import 'package:go_router/go_router.dart';
import 'tournament_participants_screen.dart';
import 'tournament_edit_screen.dart';
import '../../services/db/repositories/tournament_repository.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final Tournament tournament;
  final TournamentDetails? tournamentDetails;

  const TournamentDetailsScreen({
    super.key,
    required this.tournament,
    this.tournamentDetails,
  });

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  late TournamentDetails? tournamentDetails;

  @override
  void initState() {
    super.initState();
    tournamentDetails = widget.tournamentDetails;
  }

  bool get isEnrolled => tournamentDetails?.isEnrolled ?? false;

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = DateFormat('MMM dd, yyyy')
        .format(DateTime.parse(widget.tournament.startDate));
    final formattedEndDate = DateFormat('MMM dd, yyyy')
        .format(DateTime.parse(widget.tournament.endDate));

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: CustomScrollView(
        slivers: [
          // App Bar with Tournament Banner
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_canEditTournament())
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF1E1E1E),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TournamentEditScreen(
                            tournament: widget.tournament,
                          ),
                        ),
                      );
                      if (updated is Tournament && mounted) {
                        setState(() {
                          // Replace fields by creating new reference
                          // (widget.tournament is final so cannot reassign; for simplicity we ignore in-place update)
                        });
                        CustomToast.showInfo(message: 'Tournament updated');
                        Navigator.of(context).pop(true); // notify parent list
                      }
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.white70),
                        title: Text('Edit',
                            style: TextStyle(color: Colors.white70)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                        title: Text('Delete',
                            style: TextStyle(color: Colors.redAccent)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Tournament Banner Image
                  if (widget.tournament.bannerUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.tournament.bannerUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E1E1E),
                              AppColors.linkedInBlue.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E1E1E),
                              AppColors.linkedInBlue.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E1E1E),
                            AppColors.linkedInBlue.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Tournament Title Overlay
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tournament.title,
                          style: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedStartDate - $formattedEndDate',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white.withOpacity(0.9),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickInfoCard(
                          Icons.location_on,
                          'Location',
                          widget.tournament.location,
                          AppColors.linkedInBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickInfoCard(
                          Icons.people,
                          'Age Group',
                          '${widget.tournament.minAge ?? 'N/A'}-${widget.tournament.maxAge ?? 'N/A'}',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickInfoCard(
                          Icons.flag,
                          'Level',
                          widget.tournament.level?.name ?? 'N/A',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickInfoCard(
                          Icons.person,
                          'Gender',
                          widget.tournament.gender?.name ?? 'N/A',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  if (widget.tournament.description != null) ...[
                    _buildSectionCard(
                      'About Tournament',
                      Icons.description,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tournament.description!,
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tournament Details Section
                  _buildSectionCard(
                    'Tournament Details',
                    Icons.info_outline,
                    Column(
                      children: [
                        _buildDetailRow(Icons.location_pin, 'Location',
                            widget.tournament.location),
                        _buildDetailRow(Icons.calendar_today, 'Duration',
                            '$formattedStartDate - $formattedEndDate'),
                        _buildDetailRow(Icons.group, 'Age Range',
                            '${widget.tournament.minAge ?? 'N/A'} - ${widget.tournament.maxAge ?? 'N/A'} years'),
                        _buildDetailRow(Icons.public, 'Country',
                            widget.tournament.country ?? 'N/A'),
                        _buildDetailRow(Icons.star, 'Competition Level',
                            widget.tournament.level?.name ?? 'N/A'),
                        _buildDetailRow(Icons.person, 'Gender Category',
                            widget.tournament.gender?.name ?? 'N/A'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Join Tournament Button / Show Participants Button / Leave Tournament Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _isCurrentUserHost()
                          ? const LinearGradient(
                              colors: [
                                AppColors.linkedInBlue,
                                AppColors.linkedInBlueLight
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : isEnrolled
                              ? LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.8),
                                    Colors.red.withOpacity(0.6)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : _canJoinTournament()
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.linkedInBlue,
                                        AppColors.linkedInBlueLight
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.withOpacity(0.8),
                                        Colors.grey.withOpacity(0.6)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final currentUser = DbProvider.instance.cashedUser;
                          final isHost =
                              currentUser?.id == widget.tournament.hostId;

                          if (isHost) {
                            debugPrint(
                                'Show participants for tournament: ${widget.tournament.title}');
                            _showParticipantsDialog(context);
                          } else if (isEnrolled) {
                            _showLeaveDialog(context);
                          } else if (_canJoinTournament()) {
                            _showRegistrationDialog(context);
                          } else {
                            CustomToast.showInfo(
                                message:
                                    'Registration is closed for this tournament');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCurrentUserHost()
                                    ? Icons.group
                                    : isEnrolled
                                        ? Icons.exit_to_app
                                        : _canJoinTournament()
                                            ? Icons.emoji_events
                                            : Icons.block,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isCurrentUserHost()
                                    ? 'Show Participants'
                                    : isEnrolled
                                        ? 'Leave Tournament'
                                        : _canJoinTournament()
                                            ? 'Join Tournament'
                                            : 'Registration Closed',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canEditTournament() {
    final currentUser = DbProvider.instance.cashedUser;
    if (currentUser == null) return false;

    // Only recruiters can edit tournaments
    if (currentUser.role.value != 'recruiter') return false;

    // Recruiters can only edit their own tournaments
    return widget.tournament.hostId == currentUser.id;
  }
  // Removed legacy popup menu implementation; replaced by AppBar PopupMenuButton

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Delete Tournament',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${widget.tournament.title}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTournament(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTournament(BuildContext context) async {
    try {
      await TournamentRepository.instance
          .deleteTournament(widget.tournament.id);

      CustomToast.showSuccess(message: 'Tournament deleted successfully');

      // Navigate back to previous screen
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      CustomToast.showError(
          message: 'Failed to delete tournament: ${e.toString()}');
    }
  }

  Widget _buildQuickInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.linkedInBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  void _showRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Dark dialog background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.linkedInBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Join Tournament',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to register for "${widget.tournament.title}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.linkedInBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.linkedInBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive confirmation details via email.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.linkedInBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _joinTournament(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.linkedInBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.linkedInBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.linkedInBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentUserHost() {
    final currentUser = DbProvider.instance.cashedUser;
    return currentUser?.id == widget.tournament.hostId;
  }

  bool _canJoinTournament() {
    return widget.tournament.status == TournamentStatus.scheduled;
  }

  Future<void> _joinTournament(BuildContext context) async {
    try {
      CustomToast.showInfo(message: 'Joining tournament...');

      final message = await TournamentRepository.instance
          .joinTournament(widget.tournament.id);

      CustomToast.showSuccess(
        message:
            message.isNotEmpty ? message : 'Successfully joined tournament!',
      );

      // Update local state to reflect enrollment
      setState(() {
        if (tournamentDetails != null) {
          tournamentDetails = tournamentDetails!.copyWith(isEnrolled: true);
        }
      });

      // Wait a moment for UI to update, then return to parent
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop(true);
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to join tournament: ${e.toString()}',
      );
    }
  }

  Future<void> _leaveTournament(BuildContext context) async {
    try {
      CustomToast.showInfo(message: 'Leaving tournament...');

      final message = await TournamentRepository.instance
          .leaveTournament(widget.tournament.id);

      CustomToast.showSuccess(
        message: message.isNotEmpty ? message : 'Successfully left tournament!',
      );

      // Update local state to reflect leaving the tournament
      setState(() {
        if (tournamentDetails != null) {
          tournamentDetails = tournamentDetails!.copyWith(isEnrolled: false);
        }
      });

      // Wait a moment for UI to update, then return to parent
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop(true);
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to leave tournament: ${e.toString()}',
      );
    }
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Leave Tournament',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to leave "${widget.tournament.title}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _leaveTournament(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  void _showParticipantsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentParticipantsScreen(
          tournament: widget.tournament,
        ),
      ),
    );
  }
}
