import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/enums.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../components/custom_toast.dart';
import '../../config/routes/route_names.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_exceptions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService.customProvider();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Role _selectedRole = Role.player;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      await Future.delayed(Duration.zero);

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        await _authService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole.toJson(),
        );

        if (mounted) {
          CustomToast.showSuccess(
            message:
                'Account created successfully! Please check your email to verify your account.',
          );

          // Use Future.microtask to schedule navigation after current execution completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.goNamed(RouteNames.emailVerification, queryParameters: {
                'email': _emailController.text.trim(),
              });
            }
          });
        }
      } on EmailAlreadyInUseAuthException {
        if (mounted) {
          CustomToast.showError(
            message:
                'An account with this email already exists. Please try signing in instead.',
          );
        }
      } on InvalidEmailAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'Please enter a valid email address.',
          );
        }
      } on WeakPasswordAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'Password is too weak. Please choose a stronger password.',
          );
        }
      } on NetworkException {
        if (mounted) {
          CustomToast.showError(
            message:
                'Network error. Please check your internet connection and try again.',
          );
        }
      } on ServerException catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: 'Server error: ${e.message}',
          );
        }
      } on GenericAuthException {
        if (mounted) {
          CustomToast.showError(
            message: 'An unexpected error occurred. Please try again.',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(
            message: 'Registration failed. Please try again.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _handleGoogleSignIn() async {
    // Add a small delay to ensure build cycle completes
    await Future.delayed(Duration.zero);

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Sign in with Google using AuthService
      await _authService.signInWithGoogle();
      if (mounted) {
        CustomToast.showSuccess(
          message: 'Successfully signed in with Google!',
        );

        // Use Future.microtask to schedule navigation after current execution completes
        Future.microtask(() {
          if (mounted) {
            context.goNamed(RouteNames.home);
          }
        });
      }
    } on NetworkException {
      if (mounted) {
        CustomToast.showError(
          message:
              'Network error. Please check your internet connection and try again.',
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Server error: ${e.message}',
        );
      }
    } on GenericAuthException {
      if (mounted) {
        CustomToast.showError(
          message: 'Google sign in failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Sign in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      // Back Button
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sports,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please fill in the details to register',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<Role>(
                          segments: const [
                            ButtonSegment<Role>(
                              value: Role.player,
                              label: Text('Player'),
                              icon: Icon(Icons.sports_soccer),
                            ),
                            ButtonSegment<Role>(
                              value: Role.recruiter,
                              label: Text('Recruiter'),
                              icon: Icon(Icons.business),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (Set<Role> newSelection) {
                            setState(() {
                              _selectedRole = newSelection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            selectedForegroundColor: Colors.white,
                            selectedBackgroundColor: AppColors.linkedInBlue,
                            side: const BorderSide(
                              color: AppColors.linkedInBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        isPasswordField: true,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        isPasswordField: true,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Create Account',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                      ),
                      if (_selectedRole == Role.player) ...[
                        const SizedBox(height: 15),
                        Center(
                          child: Text(
                            'Or register with',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: Image.network(
                              'https://img.icons8.com/?size=100&id=17949&format=png&color=000000',
                              height: 24,
                            ),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.goNamed(RouteNames.login),
                            child: const Text('Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
}
