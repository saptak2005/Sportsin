import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/services/db/db_provider.dart';

import '../../components/job_banner.dart';
import '../../config/routes/route_names.dart';
import '../../models/camp_openning.dart';
import '../../models/enums.dart';
import 'opening_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    // Example 1: Open Football Coach Position
    final jobOpening1 = CampOpenning(
      id: '1',
      createdAt: '2025-01-15T10:00:00Z',
      updatedAt: '2025-01-20T14:30:00Z',
      sportId: 'football_001',
      recruiterId: 'recruiter_123',
      companyName: 'Manchester United FC',
      status: OpeningStatus.open,
      title: 'Youth Football Coach',
      description: 'We are looking for a passionate and experienced youth football coach to join our academy. The ideal candidate will have experience working with children aged 8-16 and a strong understanding of football fundamentals.',
      position: 'Head Coach',
      minAge: 25,
      maxAge: 45,
      minLevel: 'UEFA B License',
      minSalary: 45000,
      maxSalary: 65000,
      countryRestriction: 'United Kingdom',
      addressId: 'addr_manchester_001',
      stats: {'applications': 24, 'views': 156},
    );

    // Example 2: Closed Basketball Position
    final jobOpening2 = CampOpenning(
      id: '2',
      createdAt: '2025-01-10T09:00:00Z',
      updatedAt: '2025-01-22T16:45:00Z',
      sportId: 'basketball_002',
      recruiterId: 'recruiter_456',
      companyName: 'LA Lakers',
      status: OpeningStatus.closed,
      title: 'Assistant Basketball Coach',
      description: 'Join our professional coaching staff as an assistant coach. Responsibilities include player development, game analysis, and supporting the head coach during practices and games.',
      position: 'Assistant Coach',
      minAge: 30,
      maxAge: 50,
      minLevel: 'NCAA Experience',
      minSalary: 80000,
      maxSalary: 120000,
      countryRestriction: 'United States',
      addressId: 'addr_la_001',
      stats: {'applications': 89, 'views': 445},
    );

    // Example 3: Tennis Academy Position
    final jobOpening3 = CampOpenning(
      id: '3',
      createdAt: '2025-01-18T11:30:00Z',
      updatedAt: '2025-01-23T12:00:00Z',
      sportId: 'tennis_003',
      recruiterId: 'recruiter_789',
      companyName: 'Wimbledon Tennis Academy',
      status: OpeningStatus.open,
      title: 'Junior Tennis Instructor',
      description: 'Teach tennis fundamentals to junior players aged 6-18. Create engaging lesson plans, conduct group and individual sessions, and help young athletes develop their skills.',
      position: 'Tennis Instructor',
      minAge: 22,
      maxAge: 40,
      minLevel: 'LTA Level 2',
      minSalary: 35000,
      maxSalary: 50000,
      countryRestriction: 'United Kingdom',
      addressId: 'addr_wimbledon_001',
      stats: {'applications': 12, 'views': 78},
    );

    // Example 4: High-paying Swimming Position
    final jobOpening4 = CampOpenning(
      id: '4',
      createdAt: '2025-01-20T14:00:00Z',
      updatedAt: '2025-01-23T10:15:00Z',
      sportId: 'swimming_004',
      recruiterId: 'recruiter_012',
      companyName: 'Olympic Training Center',
      status: OpeningStatus.open,
      title: 'Elite Swimming Coach',
      description: 'Lead our elite swimming program for Olympic hopefuls. Develop training programs, analyze performance data, and guide athletes to international competitions.',
      position: 'Head Swimming Coach',
      minAge: 35,
      maxAge: 55,
      minLevel: 'Olympic Experience',
      minSalary: 150000,
      maxSalary: 250000,
      countryRestriction: 'United States',
      addressId: 'addr_colorado_001',
      stats: {'applications': 5, 'views': 234},
    );

    // Example 5: Cricket Academy Position
    final jobOpening5 = CampOpenning(
      id: '5',
      createdAt: '2025-01-22T08:45:00Z',
      updatedAt: '2025-01-23T09:30:00Z',
      sportId: 'cricket_005',
      recruiterId: 'recruiter_345',
      companyName: 'Royal Cricket Academy',
      status: OpeningStatus.open,
      title: 'Cricket Development Coach',
      description: 'Join our world-class cricket academy to develop the next generation of cricket stars. Focus on technique development, match strategy, and player mentorship.',
      position: 'Development Coach',
      minAge: 28,
      maxAge: 50,
      minLevel: 'Level 3 ECB',
      minSalary: 55000,
      maxSalary: 75000,
      countryRestriction: 'India',
      addressId: 'addr_mumbai_001',
      stats: {'applications': 18, 'views': 92},
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Create Job Post Header (only for recruiters)
          if (DbProvider.instance.cashedUser?.role == Role.recruiter) ...[
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
                        Icons.work_outline,
                        color: Color(0xFF0A66C2),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Post Your Job Opening',
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
                    'Find the perfect candidates for your sports organization',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to job creation screen
                      context.pushNamed(RouteNames.jobCreation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A66C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                          'Create Job Post',
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
          ],
          
          // Job List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
          JobBanner(
            opening: jobOpening1,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OpeningDetailsScreen(opening: jobOpening1),
                ),
              );
            },
            onApply: () {
              debugPrint('Applied to Manchester United job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted to Manchester United FC!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onViewApplicants: () {
              debugPrint('Viewing applicants for Manchester United job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing applicants for this position'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          
          JobBanner(
            opening: jobOpening2,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OpeningDetailsScreen(opening: jobOpening2),
                ),
              );
            },
            onApply: () {
              debugPrint('Tried to apply to closed position');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This position is currently closed'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            onViewApplicants: () {
              debugPrint('Viewing applicants for LA Lakers job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing applicants for this position'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          
          JobBanner(
            opening: jobOpening3,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OpeningDetailsScreen(opening: jobOpening3),
                ),
              );
            },
            onApply: () {
              debugPrint('Applied to Wimbledon job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted to Wimbledon Academy!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onViewApplicants: () {
              debugPrint('Viewing applicants for Wimbledon job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing applicants for this position'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          
          JobBanner(
            opening: jobOpening4,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OpeningDetailsScreen(opening: jobOpening4),
                ),
              );
            },
            onApply: () {
              debugPrint('Applied to Olympic Training Center job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted to Olympic Training Center!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onViewApplicants: () {
              debugPrint('Viewing applicants for Olympic Training Center job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing applicants for this position'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          
          JobBanner(
            opening: jobOpening5,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OpeningDetailsScreen(opening: jobOpening5),
                ),
              );
            },
            onApply: () {
              debugPrint('Applied to Royal Cricket Academy job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted to Royal Cricket Academy!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onViewApplicants: () {
              debugPrint('Viewing applicants for Royal Cricket Academy job');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Viewing applicants for this position'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
