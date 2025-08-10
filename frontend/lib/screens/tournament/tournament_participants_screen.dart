import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportsin/models/models.dart';

import '../../config/theme/app_colors.dart';
import '../../services/db/db_provider.dart';
import '../../services/db/repositories/tournament_repository.dart';
import '../../components/custom_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TournamentParticipantsScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentParticipantsScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentParticipantsScreen> createState() =>
      _TournamentParticipantsScreenState();
}

class _TournamentParticipantsScreenState
    extends State<TournamentParticipantsScreen> {
  List<TournamentParticipants> participants = [];
  bool isLoading = true;
  String? error;
  ParticipationStatus? filterStatus;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Bulk update functionality
  Set<String> selectedParticipants = {};
  bool isBulkMode = false;
  bool isBulkUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Use the new detailed participants method
      final fetchedParticipants = await TournamentRepository.instance
          .getTournamentParticipantsWithDetails(widget.tournament.id);

      setState(() {
        participants = fetchedParticipants;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshParticipants() async {
    await _loadParticipants();
    CustomToast.showInfo(message: 'Participants list refreshed');
  }

  // Bulk update functionality
  void _toggleBulkMode() {
    setState(() {
      isBulkMode = !isBulkMode;
      if (!isBulkMode) {
        selectedParticipants.clear();
      }
    });
  }

  void _toggleParticipantSelection(String participantId) {
    setState(() {
      if (selectedParticipants.contains(participantId)) {
        selectedParticipants.remove(participantId);
      } else {
        selectedParticipants.add(participantId);
      }
    });
  }

  void _selectAllParticipants() {
    setState(() {
      selectedParticipants = filteredParticipants
          .where((p) => p.status == ParticipationStatus.pending)
          .map((p) => p.id)
          .toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      selectedParticipants.clear();
    });
  }

  Future<void> _bulkUpdateStatus(ParticipationStatus newStatus) async {
    if (selectedParticipants.isEmpty) {
      CustomToast.showError(message: 'No participants selected');
      return;
    }

    setState(() {
      isBulkUpdating = true;
    });

    try {
      final updates = selectedParticipants
          .map((participantId) => {
                'participant_id': participantId,
                'status': newStatus.toJson(),
              })
          .toList();

      await TournamentRepository.instance.bulkUpdateParticipantStatus(
        tournamentId: widget.tournament.id,
        participantUpdates: updates,
      );

      CustomToast.showSuccess(
        message:
            'Updated ${selectedParticipants.length} participants successfully',
      );

      setState(() {
        selectedParticipants.clear();
        isBulkMode = false;
      });

      await _refreshParticipants();
    } catch (e) {
      CustomToast.showError(
        message: 'Failed to update participants: ${e.toString()}',
      );
    } finally {
      setState(() {
        isBulkUpdating = false;
      });
    }
  }

  Future<User?> _getUserById(String userId) async {
    return await DbProvider.instance.getUserById(userId);
  }

  List<TournamentParticipants> get filteredParticipants {
    return participants.where((participant) {
      // Filter by status
      if (filterStatus != null && participant.status != filterStatus) {
        return false;
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        return participant.userId
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Bulk mode toggle
              if (!isBulkMode)
                IconButton(
                  onPressed: _toggleBulkMode,
                  icon: const Icon(Icons.checklist, color: Colors.white),
                  tooltip: 'Bulk Select',
                ),
              // Bulk mode controls
              if (isBulkMode) ...[
                IconButton(
                  onPressed: _selectAllParticipants,
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  tooltip: 'Select All Pending',
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  tooltip: 'Clear Selection',
                ),
                IconButton(
                  onPressed: () => _toggleBulkMode(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Exit Bulk Mode',
                ),
              ],
              // Refresh button
              IconButton(
                onPressed: _refreshParticipants,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Tournament Banner
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
                  // Title Overlay
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.group,
                              color: AppColors.linkedInBlue,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tournament Participants',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tournament.title,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search and Filter Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search participants...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Filter Chips
                      Row(
                        children: [
                          Text(
                            'Filter by status:',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All', null),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                      'Pending', ParticipationStatus.pending),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                      'Accepted', ParticipationStatus.accepted),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                      'Rejected', ParticipationStatus.rejected),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Statistics Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          participants.length.toString(),
                          Icons.people,
                          AppColors.linkedInBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Accepted',
                          participants
                              .where((p) =>
                                  p.status == ParticipationStatus.accepted)
                              .length
                              .toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pending',
                          participants
                              .where((p) =>
                                  p.status == ParticipationStatus.pending)
                              .length
                              .toString(),
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Participants List
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.linkedInBlue),
                    SizedBox(height: 16),
                    Text(
                      'Loading participants...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading participants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadParticipants,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.linkedInBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredParticipants.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      searchQuery.isNotEmpty || filterStatus != null
                          ? Icons.search_off
                          : Icons.people_outline,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      searchQuery.isNotEmpty || filterStatus != null
                          ? 'No participants found'
                          : 'No participants yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                    Text(
                      searchQuery.isNotEmpty || filterStatus != null
                          ? 'Try adjusting your search or filter'
                          : '',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    if (searchQuery.isNotEmpty || filterStatus != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                            filterStatus = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.linkedInBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final participant = filteredParticipants[index];
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildParticipantCard(participant),
                  );
                },
                childCount: filteredParticipants.length,
              ),
            ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: isBulkMode && selectedParticipants.isNotEmpty
          ? _buildBulkActionButton()
          : null,
    );
  }

  Widget _buildBulkActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accept button
        FloatingActionButton.extended(
          onPressed: isBulkUpdating
              ? null
              : () => _bulkUpdateStatus(ParticipationStatus.accepted),
          backgroundColor: Colors.green,
          icon: const Icon(Icons.check, color: Colors.white),
          label: Text(
            'Accept (${selectedParticipants.length})',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        // Reject button
        FloatingActionButton.extended(
          onPressed: isBulkUpdating
              ? null
              : () => _bulkUpdateStatus(ParticipationStatus.rejected),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.close, color: Colors.white),
          label: Text(
            'Reject (${selectedParticipants.length})',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, ParticipationStatus? status) {
    final isSelected = filterStatus == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          filterStatus = selected ? status : null;
        });
      },
      backgroundColor: const Color(0xFF2A2A2A),
      selectedColor: AppColors.linkedInBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color:
            isSelected ? AppColors.linkedInBlue : Colors.grey.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(TournamentParticipants participant) {
    final isSelected = selectedParticipants.contains(participant.id);
    final canSelect =
        isBulkMode && participant.status == ParticipationStatus.pending;

    return Card(
      color: isSelected
          ? AppColors.linkedInBlue.withOpacity(0.1)
          : const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.linkedInBlue
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canSelect
            ? () => _toggleParticipantSelection(participant.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox in bulk mode
              if (isBulkMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: canSelect
                      ? (value) => _toggleParticipantSelection(participant.id)
                      : null,
                  activeColor: AppColors.linkedInBlue,
                ),
                const SizedBox(width: 8),
              ],

              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    participant.userId.length >= 2
                        ? participant.userId.substring(0, 2).toUpperCase()
                        : participant.userId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.linkedInBlue,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Participant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<User?>(
                            future: _getUserById(participant.userId),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  'User ${participant.userId}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              } else {
                                final user = snapshot.data;
                                return Text(
                                  user?.name != null && user!.name.isNotEmpty
                                      ? '${user.name} ${user.surname}'.trim()
                                      : 'User ${participant.userId}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                            },
                          ),
                        ),
                        _buildStatusBadge(participant.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Joined: ${DateFormat('MMM dd').format(DateTime.parse(participant.createdAt))}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated: ${DateFormat('MMM dd').format(DateTime.parse(participant.updatedAt))}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button (only show when not in bulk mode)
              if (!isBulkMode)
                IconButton(
                  onPressed: () => _showParticipantDetails(participant),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ParticipationStatus status) {
    Color color = _getStatusColor(status);
    String text = status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.accepted:
        return Colors.green;
      case ParticipationStatus.pending:
        return Colors.orange;
      case ParticipationStatus.rejected:
        return Colors.red;
    }
  }

  void _showParticipantDetails(TournamentParticipants participant) {
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
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    participant.userId.length >= 2
                        ? participant.userId.substring(0, 2).toUpperCase()
                        : participant.userId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.linkedInBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participant Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<User?>(
                      future: _getUserById(participant.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final user = snapshot.data;
                          return Text(
                            user?.name != null && user!.name.isNotEmpty
                                ? '${user.name} ${user.surname}'.trim()
                                : 'User ${participant.userId}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', participant.status.name.toUpperCase()),
              _buildDetailRow(
                  'Joined Date',
                  DateFormat('MMMM dd, yyyy at HH:mm')
                      .format(DateTime.parse(participant.createdAt))),
              _buildDetailRow(
                  'Last Updated',
                  DateFormat('MMMM dd, yyyy at HH:mm')
                      .format(DateTime.parse(participant.updatedAt))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (participant.status == ParticipationStatus.pending)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showStatusUpdateDialog(participant);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.linkedInBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Update Status'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(TournamentParticipants participant) {
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
          title: const Text(
            'Update Participation Status',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update status for User ${participant.userId}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateParticipantStatus(
                            participant, ParticipationStatus.accepted);
                      },
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateParticipantStatus(
                            participant, ParticipationStatus.rejected);
                      },
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
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
          ],
        );
      },
    );
  }

  Future<void> _updateParticipantStatus(
      TournamentParticipants participant, ParticipationStatus newStatus) async {
    try {
      CustomToast.showInfo(message: 'Updating status...');

      await TournamentRepository.instance.updateTournamentParticipationStatus(
        tournamentId: participant.tournamentId,
        userId: participant.userId,
        status: newStatus,
      );

      CustomToast.showSuccess(message: 'Status updated successfully');
      await _refreshParticipants();
    } catch (e) {
      CustomToast.showError(
          message: 'Failed to update status: ${e.toString()}');
    }
  }
}
