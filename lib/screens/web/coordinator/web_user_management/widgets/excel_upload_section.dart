import 'package:flutter/material.dart';
import '../utils/user_management_constants.dart';

class ExcelUploadSection extends StatefulWidget {
  final VoidCallback onFileSelected;
  final bool isLoading;

  const ExcelUploadSection({
    Key? key,
    required this.onFileSelected,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<ExcelUploadSection> createState() => _ExcelUploadSectionState();
}

class _ExcelUploadSectionState extends State<ExcelUploadSection> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: _isHovering ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovering
                      ? [
                          Colors.white,
                          UserManagementConstants.primaryColor.withOpacity(0.02),
                        ]
                      : [Colors.white, Colors.white],
                ),
                border: Border.all(
                  color: _isHovering
                      ? UserManagementConstants.primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onFileSelected,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 64,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Icon Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(_isHovering ? 28 : 24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              UserManagementConstants.primaryColor.withOpacity(0.1),
                              UserManagementConstants.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          boxShadow: _isHovering
                              ? [
                                  BoxShadow(
                                    color: UserManagementConstants.primaryColor
                                        .withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          UserManagementConstants.uploadIcon,
                          size: 56,
                          color: UserManagementConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        UserManagementConstants.importSectionTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F2D52),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      Text(
                        UserManagementConstants.selectFileMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      
                      // Upload Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              UserManagementConstants.primaryColor,
                              UserManagementConstants.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UserManagementConstants.primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: widget.isLoading ? null : widget.onFileSelected,
                          icon: widget.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(UserManagementConstants.uploadIcon),
                          label: Text(
                            widget.isLoading
                                ? UserManagementConstants.processingMessage
                                : UserManagementConstants.uploadButtonLabel,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Info Section with better styling
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[200]!.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Excel File Requirements',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRequirementItem(
                              'File must contain "Mentee Assignments" and "Mentee Info for Matching" sheets',
                            ),
                            _buildRequirementItem(
                              'Mentee Assignments: Name, Mentor, Acknowledgment Status',
                            ),
                            _buildRequirementItem(
                              'Mentee Info: Name, Email, Major, Year, Career Aspiration',
                            ),
                            _buildRequirementItem(
                              'Supported formats: .xlsx, .xls',
                            ),
                          ],
                        ),
                      ),
                      
                      // Drag and Drop Hint
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'or drag and drop your file here',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}