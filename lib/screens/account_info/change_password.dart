import 'package:crypt/crypt.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int userId;
  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccessMessage = false;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final db = DatabaseConnection();

  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _notificationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _notificationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showNotification(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<bool> _verifyCurrentPassword(String currentPassword) async {
    try {
      await db.connect();

      final hashedCurrentPassword = await db.executeQuery(
        "SELECT check_passwd_current(@user_id, @password_current)",
        substitutionValues: {
          "user_id": widget.userId,
          "password_current": currentPassword
        },
      );

      return hashedCurrentPassword[0][0] == true;
    } catch (e) {
      return false;
    } finally {
      await db.close();
    }
  }

  void _validateAndChangePassword() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Check if passwords match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'New password does not match';
          _animationController.reset();
          _animationController.forward();
        });
        _showNotification('New password does not match', true);
        return;
      }

      // Show loading state
      setState(() {
        _isLoading = true;
      });

      try {
        await db.connect();

        final result = await db.executeQuery(
          "SELECT username FROM accounts WHERE id = @id",
          substitutionValues: {"id": widget.userId},
        );

        if (result.isEmpty) {
          setState(() {
            _errorMessage = "Not found account";
            _isLoading = false;
          });
          _showNotification("Not found account", true);
          return;
        }

        // Verify current password
        final isCurrentPasswordValid =
            await _verifyCurrentPassword(_currentPasswordController.text);

        if (!isCurrentPasswordValid) {
          setState(() {
            _errorMessage = "Password current is not correct";
            _isLoading = false;
          });
          _showNotification("Password current is not correct", true);
          return;
        }

        // Hash mật khẩu mới trước khi lưu
        await db.executeQuery(
          "UPDATE accounts SET passwd = crypt(@newPassword, gen_salt('bf')) WHERE id = @id",
          substitutionValues: {
            "newPassword": _newPasswordController.text,
            "id": widget.userId,
          },
        );

        // Show success message
        setState(() {
          _showSuccessMessage = true;
          _isLoading = false;

          // Reset form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          // Reset animation to show success message with animation
          _animationController.reset();
          _animationController.forward();
        });

        _showNotification("Change password is done!", false);
      } catch (e) {
        setState(() {
          _errorMessage = "Database error: $e";
          _isLoading = false;
        });
        _showNotification("Database error: $e", true);
      } finally {
        await db.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFF4B5B98),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main', arguments: widget.userId),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Security Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B5B98).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF4B5B98),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Center(
                        child: Text(
                          'Create a new password for your account',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Success Message
                      if (_showSuccessMessage) ...[
                        ScaleTransition(
                          scale: _notificationAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thành công!',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mật khẩu của bạn đã được cập nhật thành công.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showSuccessMessage = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Password Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error Message
                            if (_errorMessage != null) ...[
                              ScaleTransition(
                                scale: _notificationAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red[700],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lỗi!',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _errorMessage!,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red[700],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _errorMessage = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Current Password
                            _buildPasswordField(
                              label: 'Current Password',
                              controller: _currentPasswordController,
                              showPassword: _showCurrentPassword,
                              toggleVisibility: () {
                                setState(() {
                                  _showCurrentPassword = !_showCurrentPassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu hiện tại';
                                }
                                return null;
                              },
                              hasError:
                                  _errorMessage?.contains('hiện tại') ?? false,
                            ),
                            const SizedBox(height: 24),

                            // New Password
                            _buildPasswordField(
                              label: 'New Password',
                              controller: _newPasswordController,
                              showPassword: _showNewPassword,
                              toggleVisibility: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu mới';
                                }
                                if (value.length < 8) {
                                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                                }
                                return null;
                              },
                              hasError: _errorMessage?.contains('mới') ?? false,
                            ),
                            const SizedBox(height: 24),

                            // Confirm New Password
                            _buildPasswordField(
                              label: 'Confirm New Password',
                              controller: _confirmPasswordController,
                              showPassword: _showConfirmPassword,
                              toggleVisibility: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng xác nhận mật khẩu mới';
                                }
                                return null;
                              },
                              hasError: _errorMessage?.contains('không khớp') ??
                                  false,
                            ),

                            // Password Requirements
                            const SizedBox(height: 24),
                            Text(
                              'Password Requirements:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRequirementItem(
                              'At least 8 characters',
                              _newPasswordController.text.length >= 8,
                            ),
                            _buildRequirementItem(
                              'Contains uppercase letters',
                              _newPasswordController.text
                                  .contains(RegExp(r'[A-Z]')),
                            ),
                            _buildRequirementItem(
                              'Contains numbers',
                              _newPasswordController.text
                                  .contains(RegExp(r'[0-9]')),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Change Password Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _validateAndChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B5B98),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 8,
                            shadowColor:
                                const Color(0xFF4B5B98).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  'Change Password',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red[700] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_rounded,
              color: hasError ? Colors.red[400] : const Color(0xFF4B5B98),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey[500],
              ),
              onPressed: toggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red[300]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red[400]! : const Color(0xFF4B5B98),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            filled: true,
            fillColor: hasError ? Colors.red[50] : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isMet ? Colors.green[600] : Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isMet ? Colors.green[600] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
