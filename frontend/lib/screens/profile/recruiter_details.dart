import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/models/recruiter.dart';
import 'package:sportsin/screens/feed/feed_screen.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import '../../components/custom_button.dart';
import '../../components/profile_info_components.dart';
import '../../config/routes/route_names.dart';

class RecruiterDetailsScreen extends StatefulWidget {
  const RecruiterDetailsScreen({super.key});

  @override
  State<RecruiterDetailsScreen> createState() => _RecruiterDetailsScreenState();
}

class _RecruiterDetailsScreenState extends State<RecruiterDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final recruiter = DbProvider.instance.cashedUser;

    if (recruiter == null) {
      return const Center(
        child: Text('No recruiter data found'),
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
                  backgroundImage: recruiter.profilePicture != null
                      ? NetworkImage(recruiter.profilePicture!)
                      : null,
                  child: recruiter.profilePicture == null
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

          // Recruiter Name
          Text(
            '${recruiter.name} ${recruiter.surname}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Username
          Text(
            '@${recruiter.userName}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Profile Information Cards
          ProfileInfoCard(
            title: 'Personal Information',
            children: [
              ProfileInfoRow(label: 'Email', value: recruiter.email),
              ProfileInfoRow(label: 'Date of Birth', value: recruiter.dob),
              ProfileInfoRow(label: 'Gender', value: recruiter.gender.value),
              if (recruiter.middleName != null)
                ProfileInfoRow(
                    label: 'Middle Name', value: recruiter.middleName!),
            ],
          ),

          const SizedBox(height: 16),

          if (recruiter is Recruiter) ...[
            ProfileInfoCard(
              title: 'Organization Information',
              children: [
                ProfileInfoRow(
                    label: 'Organization', value: recruiter.organizationName),
                ProfileInfoRow(
                    label: 'Organization ID', value: recruiter.organizationId),
                ProfileInfoRow(label: 'Position', value: recruiter.position),
                ProfileInfoRow(
                    label: 'Phone Number', value: recruiter.phoneNumber),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // About Section
          if (recruiter.about != null && recruiter.about!.isNotEmpty)
            ProfileInfoCard(
              title: 'About',
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    recruiter.about!,
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
            child: FeedScreen(userId: recruiter.id),
          ),
        ],
      ),
    );
  }
}
