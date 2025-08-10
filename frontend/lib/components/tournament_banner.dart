import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme/app_colors.dart';
import '../models/tournament.dart';
import '../models/enums.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TournamentBanner extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onDetails;
  final VoidCallback onJoin;
  final VoidCallback? onShowParticipants;
  final VoidCallback? onLeave;
  final VoidCallback? onUpdateStatus;
  final bool isHost;
  final bool isEnrolled;
  final ParticipationStatus? participationStatus;

  const TournamentBanner({
    super.key,
    required this.tournament,
    required this.onDetails,
    required this.onJoin,
    this.onShowParticipants,
    this.onLeave,
    this.onUpdateStatus,
    this.isHost = false,
    this.isEnrolled = false,
    this.participationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final formattedStartDate =
        DateFormat('MMM dd, yyyy').format(DateTime.parse(tournament.startDate));
    final formattedEndDate =
        DateFormat('MMM dd, yyyy').format(DateTime.parse(tournament.endDate));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.linkedInBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          children: [
            // Tournament Banner Image with Overlay
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: tournament.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: tournament.bannerUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.linkedInBlue.withOpacity(0.6),
                                  AppColors.linkedInBlue.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.linkedInBlue.withOpacity(0.6),
                                  Colors.purple.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.emoji_events,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.linkedInBlue.withOpacity(0.6),
                                Colors.purple.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                // Gradient overlay for better text readability
                Container(
                  height: 180,
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
                // Tournament Status and Level Badges
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Tournament Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTournamentStatusColor(tournament.status),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getTournamentStatusText(tournament.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tournament Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          tournament.level?.name ?? 'Open',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Participation Status Badge (for enrolled users)
                if (isEnrolled && participationStatus != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            _getParticipationStatusColor(participationStatus!),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getParticipationStatusIcon(participationStatus!),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getParticipationStatusText(participationStatus!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Tournament Title Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.title,
                        style: const TextStyle(
                          fontSize: 24.0,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$formattedStartDate - $formattedEndDate',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white70,
                              shadows: [
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
                    ],
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.location_on,
                          'Location',
                          tournament.location,
                          AppColors.linkedInBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.people,
                          'Age Group',
                          '${tournament.minAge ?? 'N/A'}-${tournament.maxAge ?? 'N/A'}',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tags Section
                  if (tournament.gender != null ||
                      tournament.country != null) ...[
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        if (tournament.gender != null)
                          _buildTag(tournament.gender!.name, Colors.teal),
                        if (tournament.country != null)
                          _buildTag(tournament.country!, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 4),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildActionButton(
                          'View Details',
                          Icons.info_outline,
                          onDetails,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildMainActionButton(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, VoidCallback onPressed, bool isPrimary,
      {bool isDestructive = false,
      bool isSecondary = false,
      bool isDisabled = false,
      double? customHeight}) {
    return SizedBox(
      height: customHeight ?? 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              gradient: isPrimary && !isDisabled
                  ? const LinearGradient(
                      colors: [
                        AppColors.linkedInBlue,
                        AppColors.linkedInBlueLight
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : isDestructive && !isDisabled
                      ? LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.8),
                            Colors.red.withOpacity(0.6)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
              color: isPrimary || isDestructive || isDisabled
                  ? null
                  : isSecondary
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.3)
                    : isPrimary
                        ? AppColors.linkedInBlue.withOpacity(0.5)
                        : isDestructive
                            ? Colors.red.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: isPrimary && !isDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.linkedInBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : isDestructive && !isDisabled
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isDisabled ? Colors.grey : Colors.white,
                  size: customHeight != null && customHeight < 45 ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.white,
                    fontSize: customHeight != null && customHeight < 45
                        ? (isPrimary || isDestructive ? 12 : 11)
                        : (isPrimary || isDestructive ? 14 : 13),
                    fontWeight: isPrimary || isDestructive
                        ? FontWeight.bold
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    if (isHost) {
      // For hosts, use a column layout to prevent overflow
      return Column(
        children: [
          if (onUpdateStatus != null)
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                'Update Status',
                Icons.settings,
                onUpdateStatus!,
                false,
                isSecondary: true,
                customHeight: 40,
              ),
            ),
          if (onUpdateStatus != null) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              'Show Participants',
              Icons.group,
              onShowParticipants ?? () {},
              true,
              customHeight: 40,
            ),
          ),
        ],
      );
    } else if (isEnrolled) {
      return _buildActionButton(
        'Leave Tournament',
        Icons.exit_to_app,
        onLeave ?? () {},
        false,
        isDestructive: true,
      );
    } else {
      // Check if tournament allows joining
      final canJoin = tournament.status == TournamentStatus.scheduled;
      return _buildActionButton(
        canJoin ? 'Join Tournament' : 'Registration Closed',
        canJoin ? Icons.emoji_events : Icons.block,
        canJoin ? onJoin : () {},
        canJoin,
        isDisabled: !canJoin,
      );
    }
  }

  Color _getTournamentStatusColor(TournamentStatus? status) {
    switch (status) {
      case TournamentStatus.scheduled:
        return Colors.amber;
      case TournamentStatus.started:
        return Colors.green;
      case TournamentStatus.ended:
        return Colors.grey;
      case TournamentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getTournamentStatusText(TournamentStatus? status) {
    switch (status) {
      case TournamentStatus.scheduled:
        return 'Scheduled';
      case TournamentStatus.started:
        return 'Started';
      case TournamentStatus.ended:
        return 'Ended';
      case TournamentStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  Color _getParticipationStatusColor(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.pending:
        return Colors.orange;
      case ParticipationStatus.accepted:
        return Colors.green;
      case ParticipationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getParticipationStatusIcon(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.pending:
        return Icons.hourglass_empty;
      case ParticipationStatus.accepted:
        return Icons.check_circle;
      case ParticipationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getParticipationStatusText(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.pending:
        return 'Pending';
      case ParticipationStatus.accepted:
        return 'Accepted';
      case ParticipationStatus.rejected:
        return 'Rejected';
    }
  }
}
