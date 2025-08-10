import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/models/player.dart';
import 'package:sportsin/models/achievement.dart';
import 'package:sportsin/screens/feed/feed_screen.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/services/db/repositories/acheivement_repository.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/config/routes/route_names.dart';
import '../../components/custom_button.dart';
import '../../components/profile_info_components.dart';
import '../../components/achievement_banner.dart';
import 'package:flutter/services.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({super.key});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoadingAchievements = false;
  String? _referralCode;
  bool _isLoadingReferralCode = false;

  @override
  void initState() {
    super.initState();
    _loadRecentAchievement();
    _loadOrGenerateReferralCode();
  }

  Future<void> _loadRecentAchievement() async {
    setState(() => _isLoadingAchievements = true);
    try {
      final achievements =
          await AchievementRepository.instance.getMyAchievements();
      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoadingAchievements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAchievements = false);
      }
      debugPrint('Failed to load achievements: $e');
    }
  }

  Future<void> _loadOrGenerateReferralCode() async {
    setState(() => _isLoadingReferralCode = true);
    try {
      final existingCode = DbProvider.instance.cashedUser?.referralCode;
      if (existingCode != null && existingCode.isNotEmpty) {
        if (mounted) {
          setState(() => _referralCode = existingCode);
        }
      } else {
        final newCode = await DbProvider.instance.getMyReferralCode();
        if (mounted) {
          setState(() => _referralCode = newCode);
          DbProvider.instance.updateCachedUser(
            DbProvider.instance.cashedUser!.copyWith(referralCode: newCode),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load or generate referral code: $e');
      if (mounted) {
        CustomToast.showError(
            message: 'Failed to load or generate referral code');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingReferralCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = DbProvider.instance.cashedUser;

    if (player == null) {
      return const Center(
        child: Text('No player data found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Profile Picture Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: player.profilePicture != null
                      ? NetworkImage(player.profilePicture!)
                      : null,
                  child: player.profilePicture == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.linkedInBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Player Name
          Text(
            [
              player.name,
              if (player.middleName != null && player.middleName!.isNotEmpty)
                player.middleName,
              player.surname
            ].join(' '),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Username
          Text(
            '@${player.userName}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ProfileInfoCard(
            title: 'Personal Information',
            children: [
              ProfileInfoRow(label: 'Email', value: player.email),
              ProfileInfoRow(label: 'Date of Birth', value: player.dob),
              ProfileInfoRow(label: 'Gender', value: player.gender.value),
              const Divider(height: 1),
              if (_isLoadingReferralCode)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (_referralCode != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Referral Code',
                          style: TextStyle(color: Colors.grey)),
                      Row(
                        children: [
                          Text(
                            _referralCode!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                size: 18, color: AppColors.linkedInBlue),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _referralCode!));

                              CustomToast.showInfo(
                                  message: 'Referral code copied to clipboard');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (player is Player) ...[
            ProfileInfoCard(
              title: 'Player Information',
              children: [
                ProfileInfoRow(
                    label: 'Current Level', value: player.level.value),
                ProfileInfoRow(
                    label: 'Interest Level', value: player.interestLevel.value),
                if (player.interestCountry != null)
                  ProfileInfoRow(
                      label: 'Interest Country',
                      value: player.interestCountry!),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // About Section
          if (player.about != null && player.about!.isNotEmpty)
            ProfileInfoCard(
              title: 'About',
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    player.about!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 30),

          // Edit Profile Button
          CustomButton(
            text: 'Edit Profile',
            onPressed: () async {
              await context.pushNamed(RouteNames.editProfile);
              if (mounted) {
                setState(() {});
              }
            },
            isLoading: false,
          ),

          const SizedBox(height: 30),

          // Posts Section
          const Divider(thickness: 1),
          const SizedBox(height: 20),

          const Text(
            'My Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // User's Posts Feed
          SizedBox(
            height: 400, // Fixed height for the posts section
            child: FeedScreen(
              userId: player.id,
              fromProfileScreen: true,
            ),
          ),

          const SizedBox(height: 20),

          // Achievements Section
          _buildAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                // Add Achievement Button
                IconButton(
                  onPressed: () => _createNewAchievement(),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.linkedInBlue,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                // View All Button
                if (_achievements.isNotEmpty)
                  TextButton(
                    onPressed: () => _showAllAchievements(),
                    child: const Text('View All'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingAchievements)
          const Center(child: CircularProgressIndicator())
        else if (_achievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'No achievements yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          AchievementBanner(
            achievement: _achievements.first,
            onEdit: () => _updateAchievement(_achievements.first),
            onDelete: () => _deleteAchievement(_achievements.first),
          ),
      ],
    );
  }

  void _showAllAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) => AchievementBanner(
                    achievement: _achievements[index],
                    onEdit: () => _updateAchievement(_achievements[index]),
                    onDelete: () => _deleteAchievement(_achievements[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewAchievement() {
    context.pushNamed(RouteNames.achievementCreation).then((_) {
      _loadRecentAchievement(); // Refresh the list after creating
    });
  }

  void _updateAchievement(Achievement achievement) {
    context.pushNamed(
      RouteNames.achievementCreation,
      queryParameters: {'achievementId': achievement.id},
    ).then((_) {
      _loadRecentAchievement(); // Refresh the list after editing
    });
  }

  void _deleteAchievement(Achievement achievement) async {
    try {
      await AchievementRepository.instance.deleteAchievement(achievement.id);
      await _loadRecentAchievement();
      if (mounted) {
        CustomToast.showInfo(message: 'Achievement deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(message: 'Failed to delete achievement');
      }
      debugPrint('Failed to delete achievement: $e');
    }
  }
}
