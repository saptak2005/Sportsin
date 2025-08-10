import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/components/job_banner.dart';
import '../../config/routes/route_names.dart';
import '../../models/enums.dart';
import '../../models/camp_openning.dart';

class CampPostOpenningScreen extends StatefulWidget {
  const CampPostOpenningScreen({super.key});

  @override
  State<CampPostOpenningScreen> createState() => _CampPostOpenningScreenState();
}

class _CampPostOpenningScreenState extends State<CampPostOpenningScreen> {
  List<CampOpenning> _openings = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  final int _limit = 10;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadOpenings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreOpenings();
      }
    }
  }

  Future<void> _loadOpenings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final user = DbProvider.instance.cashedUser;
      final isRecruiter = user?.role == Role.recruiter;
      List<CampOpenning> openings;

      if (isRecruiter) {
        // Recruiters only see their own openings
        openings = await DbProvider.instance.getMyOpenings(
          limit: _limit,
          offset: _currentOffset,
        );
      } else {
        // Players see all available openings
        openings = await DbProvider.instance.getOpenings(
          limit: _limit,
          offset: _currentOffset,
        );
      }

      if (mounted) {
        setState(() {
          _openings = openings;
          _currentOffset = openings.length;
          _hasMoreData = openings.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.showError(message: 'Failed to load camp openings');
      }
    }
  }

  Future<void> _loadMoreOpenings() async {
    if (!mounted || _isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      final user = DbProvider.instance.cashedUser;
      final isRecruiter = user?.role == Role.recruiter;
      List<CampOpenning> moreOpenings;

      if (isRecruiter) {
        // Recruiters only see their own openings
        moreOpenings = await DbProvider.instance.getMyOpenings(
          limit: _limit,
          offset: _currentOffset,
        );
      } else {
        // Players see all available openings
        moreOpenings = await DbProvider.instance.getOpenings(
          limit: _limit,
          offset: _currentOffset,
        );
      }

      if (mounted) {
        setState(() {
          _openings.addAll(moreOpenings);
          _currentOffset += moreOpenings.length;
          _hasMoreData = moreOpenings.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.showError(message: 'Failed to load more openings');
      }
    }
  }

  Future<void> _applyToOpening(String openingId, String applicantId) async {
    try {
      await DbProvider.instance.applyToOpening(openingId);
      CustomToast.showSuccess(message: 'Application submitted successfully!');
      _loadOpenings();
    } catch (e) {
      CustomToast.showError(message: 'Failed to apply to opening');
    }
  }

  /*Future<void> _withdrawApplication(
      String openingId, String applicantId) async {
    try {
      await DbProvider.instance.withdrawApplication(openingId, applicantId);
      CustomToast.showSuccess(message: 'Application withdrawn successfully!');
      _loadOpenings(); // Refresh the list
    } catch (e) {
      CustomToast.showError(message: 'Failed to withdraw application');
    }
  }*/

  Future<void> _viewApplicants(String openingId, String openingTitle) async {
    context.pushNamed(
      RouteNames.openingApplicants,
      queryParameters: {
        'openingId': openingId,
        'openingTitle': openingTitle,
      },
    );
  }

  Future<void> _updateOpeningStatus(
      CampOpenning opening, OpeningStatus newStatus) async {
    try {
      setState(() => _isLoading = true);

      final updatedOpening = await DbProvider.instance.updateOpeningStatus(
        openingId: opening.id,
        status: newStatus,
      );

      final index = _openings.indexWhere((o) => o.id == opening.id);
      if (index != -1) {
        setState(() {
          _openings[index] = updatedOpening;
        });
      }

      final statusText = newStatus == OpeningStatus.open ? 'opened' : 'closed';
      CustomToast.showSuccess(message: 'Opening $statusText successfully!');
    } catch (e) {
      CustomToast.showError(message: 'Failed to update opening status');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildOpeningCard(CampOpenning opening) {
    final user = DbProvider.instance.cashedUser;
    final isRecruiter = user?.role == Role.recruiter;

    return JobBanner(
      opening: opening,
      onApply: () =>
          _applyToOpening(opening.id, DbProvider.instance.cashedUser!.id),
      onViewApplicants: () => _viewApplicants(opening.id, opening.title),
      onUpdateStatus: isRecruiter
          ? (newStatus) => _updateOpeningStatus(opening, newStatus)
          : null,
      showApplyButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = DbProvider.instance.cashedUser;
    final isRecruiter = user?.role == Role.recruiter;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Create Job Post Header (only for recruiters)
          if (isRecruiter) ...[
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
                        Icons.work_rounded,
                        color: Colors.red,
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
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
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
                          'Create Opening',
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
          // Openings List
          Expanded(
            child: _isLoading && _openings.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0A66C2),
                    ),
                  )
                : _openings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isRecruiter
                                  ? 'No openings created yet'
                                  : 'No openings available',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            if (isRecruiter) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.pushNamed(RouteNames.jobCreation);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                ),
                                child: const Text('Create Your First Opening'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOpenings,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _openings.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _openings.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0A66C2),
                                  ),
                                ),
                              );
                            }
                            return _buildOpeningCard(_openings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
