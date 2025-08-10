import 'package:flutter/material.dart';
import 'package:sportsin/models/camp_openning.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/enums.dart';

class OpeningDetailsScreen extends StatefulWidget {
  final CampOpenning opening;

  const OpeningDetailsScreen({
    super.key,
    required this.opening,
  });

  @override
  State<OpeningDetailsScreen> createState() => _OpeningDetailsScreenState();
}

class _OpeningDetailsScreenState extends State<OpeningDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildMainInfo(),
                    const SizedBox(height: 32),
                    _buildDescription(),
                    const SizedBox(height: 32),
                    _buildDetails(),
                    const SizedBox(height: 32),
                    //_buildApplyButton(),
                    //const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isOpen = widget.opening.status == OpeningStatus.open;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.linkedInBlue.withOpacity(0.8),
                const Color(0xFF161B22),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Company Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.opening.companyName.isNotEmpty
                        ? widget.opening.companyName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.linkedInBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Company Name
              Text(
                widget.opening.companyName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'Open Position' : 'Position Closed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.opening.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.work_outline, 'Position', widget.opening.position),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.sports, 'Sport', widget.opening.sportName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.business, 'Company', widget.opening.companyName),
          if (widget.opening.countryRestriction != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Location',
                widget.opening.countryRestriction!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.linkedInBlue,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.linkedInBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Job Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.opening.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[300],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        Expanded(child: _buildSalaryCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildRequirementsCard()),
      ],
    );
  }

  Widget _buildSalaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.monetization_on,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Salary',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSalaryRange(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checklist,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Age Range',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getAgeRange(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /*Widget _buildApplyButton() {
    final isOpen = widget.opening.status == OpeningStatus.open;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isOpen
            ? LinearGradient(
                colors: [
                  AppColors.linkedInBlue,
                  AppColors.linkedInBlue.withOpacity(0.8)
                ],
              )
            : LinearGradient(
                colors: [Colors.grey[600]!, Colors.grey[700]!],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppColors.linkedInBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isOpen ? _handleApply : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOpen ? Icons.send : Icons.block,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              isOpen ? 'Apply Now' : 'Position Closed',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  /*void _handleApply() {
    CustomToast.showSuccess(
      message: 'Application submitted to ${widget.opening.companyName}!',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Your application has been submitted successfully!',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }*/

  String _getAgeRange() {
    if (widget.opening.minAge != null && widget.opening.maxAge != null) {
      return '${widget.opening.minAge}-${widget.opening.maxAge} years';
    } else if (widget.opening.minAge != null) {
      return '${widget.opening.minAge}+ years';
    } else if (widget.opening.maxAge != null) {
      return 'Up to ${widget.opening.maxAge} years';
    }
    return 'Any age';
  }

  String _getSalaryRange() {
    if (widget.opening.minSalary != null && widget.opening.maxSalary != null) {
      return '\$${_formatSalary(widget.opening.minSalary!)} - \$${_formatSalary(widget.opening.maxSalary!)}';
    } else if (widget.opening.minSalary != null) {
      return '\$${_formatSalary(widget.opening.minSalary!)}+';
    } else if (widget.opening.maxSalary != null) {
      return 'Up to \$${_formatSalary(widget.opening.maxSalary!)}';
    }
    return 'Negotiable';
  }

  String _formatSalary(int salary) {
    if (salary >= 1000000) {
      return '${(salary / 1000000).toStringAsFixed(1)}M';
    } else if (salary >= 1000) {
      return '${(salary / 1000).toStringAsFixed(0)}K';
    }
    return salary.toString();
  }
}
