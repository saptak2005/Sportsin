import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/services/db/db_provider.dart';
import '../../components/custom_toast.dart';
import '../../components/tournament_banner.dart';
import '../../config/routes/route_names.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../services/db/repositories/tournament_repository.dart';
import '../posts/tournament_details_screen.dart';
import 'tournament_participants_screen.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  List<Tournament> tournaments = [];
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
      final result = await DbProvider.instance.getTournaments(
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
    CustomToast.showInfo(message: 'Tournament list refreshed');
  }

  Future<void> _joinTournament(Tournament tournament) async {
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

      // Refresh tournaments to update any status changes
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
                    color: Color(0xFF0A66C2),
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
                      color: const Color(0xFF0A66C2).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0A66C2).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF0A66C2),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will receive confirmation details via email.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0A66C2),
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
                    backgroundColor: const Color(0xFF0A66C2),
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

  void _showParticipants(Tournament tournament) {
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
                'Create and manage your own sports tournament',
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
                  backgroundColor: const Color(0xFF0A66C2),
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
                ),
                ...statusOptions.map((status) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(status.value),
                        selected: selectedStatus == status.value,
                        onSelected: (_) => _onStatusSelected(status.value),
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
                      color: const Color(0xFF0A66C2),
                      backgroundColor: const Color(0xFF1E1E1E),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tournaments.length,
                        itemBuilder: (context, index) {
                          final tournament = tournaments[index];
                          return TournamentBanner(
                            tournament: tournament,
                            onDetails: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDetailsScreen(
                                      tournament: tournament),
                                ),
                              );

                              // If tournament was deleted or updated, refresh the list
                              if (result == true) {
                                await _refreshTournaments();
                              }
                            },
                            onJoin: () => _joinTournament(tournament),
                            onShowParticipants: () =>
                                _showParticipants(tournament),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
