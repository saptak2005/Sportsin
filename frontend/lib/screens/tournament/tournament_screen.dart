import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/custom_toast.dart';
import '../../components/tournament_banner.dart';
import '../../config/routes/route_names.dart';
import '../../config/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../services/db/repositories/tournament_repository.dart';
import '../../services/db/db_provider.dart';
import 'tournament_details_screen.dart';
import 'tournament_participants_screen.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  List<TournamentDetails> tournaments = [];
  bool isLoading = true;
  String? selectedStatus;
  final statusOptions = TournamentStatus.values;

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() => isLoading = true);
    try {
      final result = await TournamentRepository.instance.getTournaments(
        status: selectedStatus,
      );
      setState(() {
        tournaments = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Failed to load tournaments: $e');
    }
  }

  void _onStatusSelected(String? status) {
    setState(() {
      selectedStatus = status;
    });
    _fetchTournaments();
  }

  Future<void> _refreshTournaments() async {
    await _fetchTournaments();
  }

  Future<void> _joinTournament(TournamentDetails tournamentDetails) async {
    final tournament = tournamentDetails.tournament;
    final confirmed = await _showJoinConfirmationDialog(tournament);
    if (!confirmed) return;

    try {
      CustomToast.showInfo(message: 'Joining tournament...');

      final message =
          await TournamentRepository.instance.joinTournament(tournament.id);

      CustomToast.showSuccess(
        message:
            message.isNotEmpty ? message : 'Successfully joined tournament!',
      );

      await _refreshTournaments();
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to join tournament: ${e.toString()}',
      );
    }
  }

  Future<bool> _showJoinConfirmationDialog(Tournament tournament) async {
    return await showDialog<bool>(
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
                    'Are you sure you want to register for "${tournament.title}"?',
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
                  const SizedBox(height: 12),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
        ) ??
        false;
  }

  Future<void> _leaveTournament(TournamentDetails tournamentDetails) async {
    final tournament = tournamentDetails.tournament;
    final confirmed = await _showLeaveConfirmationDialog(tournament);
    if (!confirmed) return;

    try {
      CustomToast.showInfo(message: 'Leaving tournament...');

      final message =
          await TournamentRepository.instance.leaveTournament(tournament.id);

      CustomToast.showSuccess(
        message: message.isNotEmpty ? message : 'Successfully left tournament!',
      );

      // Refresh tournaments to update any status changes
      await _refreshTournaments();
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to leave tournament: ${e.toString()}',
      );
    }
  }

  Future<void> _updateTournamentStatus(Tournament tournament) async {
    final newStatus = await _showStatusUpdateDialog(tournament);
    if (newStatus == null) return;

    try {
      await TournamentRepository.instance.updateTournamentStatus(
        tournamentId: tournament.id,
        status: newStatus,
      );

      CustomToast.showSuccess(
        message: 'Tournament status updated successfully',
      );

      await _refreshTournaments();
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to update tournament status: ${e.toString()}',
      );
    }
  }

  Future<TournamentStatus?> _showStatusUpdateDialog(
      Tournament tournament) async {
    return await showDialog<TournamentStatus?>(
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
                Icons.settings,
                color: AppColors.linkedInBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Update Tournament Status',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select new status for "${tournament.title}":',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Status: ${tournament.status?.name.toUpperCase() ?? 'UNKNOWN'}',
                style: TextStyle(
                  fontSize: 14,
                  color: _getStatusColor(tournament.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...TournamentStatus.values.map((status) {
                if (status == tournament.status) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(status),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
          ],
        );
      },
    );
  }

  Color _getStatusColor(TournamentStatus? status) {
    switch (status) {
      case TournamentStatus.scheduled:
        return Colors.blue;
      case TournamentStatus.started:
        return Colors.green;
      case TournamentStatus.ended:
        return Colors.orange;
      case TournamentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.scheduled:
        return Icons.schedule;
      case TournamentStatus.started:
        return Icons.play_arrow;
      case TournamentStatus.ended:
        return Icons.flag;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  Future<bool> _showLeaveConfirmationDialog(Tournament tournament) async {
    return await showDialog<bool>(
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
                    'Are you sure you want to leave "${tournament.title}"?',
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
                  const SizedBox(height: 12),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
        ) ??
        false;
  }

  void _showParticipants(TournamentDetails tournamentDetails) {
    final tournament = tournamentDetails.tournament;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentParticipantsScreen(
          tournament: tournament,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C2C2C), Color(0xFF1C1C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Host Your Tournament',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Create and manage your own sports tournament - open to all players and coaches',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.tournament);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.linkedInBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Tournament',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: selectedStatus == null,
                  onSelected: (_) => _onStatusSelected(null),
                  selectedColor: AppColors.linkedInBlue,
                  backgroundColor: Colors.grey[900],
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedStatus == null
                        ? Colors.white
                        : AppColors.darkSecondary,
                    fontWeight: selectedStatus == null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: selectedStatus == null
                        ? AppColors.linkedInBlue
                        : const Color(0xFF30363D),
                    width: 1,
                  ),
                ),
                ...statusOptions.map((status) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(status.value),
                        selected: selectedStatus == status.value,
                        onSelected: (_) => _onStatusSelected(status.value),
                        selectedColor: AppColors.linkedInBlue,
                        backgroundColor: Colors.grey[900],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selectedStatus == status.value
                              ? Colors.white
                              : AppColors.darkSecondary,
                          fontWeight: selectedStatus == status.value
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: selectedStatus == status.value
                              ? AppColors.linkedInBlue
                              : const Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        // Tournament List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tournaments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tournaments found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Check back later for new tournaments',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshTournaments,
                      color: AppColors.linkedInBlue,
                      backgroundColor: const Color(0xFF1E1E1E),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tournaments.length,
                        itemBuilder: (context, index) {
                          final tournamentDetails = tournaments[index];
                          final tournament = tournamentDetails.tournament;
                          final currentUser = DbProvider.instance.cashedUser;
                          final isHost = currentUser?.id == tournament.hostId;

                          return TournamentBanner(
                            tournament: tournament,
                            onDetails: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDetailsScreen(
                                      tournament: tournament,
                                      tournamentDetails: tournamentDetails),
                                ),
                              );

                              if (result == true) {
                                await _refreshTournaments();
                              }
                            },
                            onJoin: () => _joinTournament(tournamentDetails),
                            onLeave: () => _leaveTournament(tournamentDetails),
                            onShowParticipants: () =>
                                _showParticipants(tournamentDetails),
                            onUpdateStatus: isHost
                                ? () => _updateTournamentStatus(tournament)
                                : null,
                            isHost: isHost,
                            isEnrolled: tournamentDetails.isEnrolled,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
