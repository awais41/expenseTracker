import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/auth_models.dart';
import '../bloc/profile_setup_cubit.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.session,
    required this.cubit,
    required this.onCompleted,
  });

  final AuthSession session;
  final ProfileSetupCubit cubit;
  final VoidCallback onCompleted;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.emerald),
    ),
  );
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_handleUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cubit,
      builder: (context, _) {
        final usernameLabel = widget.cubit.isCheckingUsername
            ? 'Checking username...'
            : widget.cubit.usernameAvailable == true
            ? 'Username available'
            : widget.cubit.usernameAvailable == false
            ? 'Username unavailable'
            : 'Choose a unique username';
        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.screenGradientEnd],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete your profile',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'People will find you by username when inviting you into shared groups.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _displayNameController,
                            decoration: _inputDecoration('Display name'),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _usernameController,
                            decoration: _inputDecoration('Username'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            usernameLabel,
                            style: TextStyle(
                              color: widget.cubit.usernameAvailable == false
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.cubit.error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.cubit.error!.message,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.cubit.isSubmitting ? null : _submit,
                              child: const Text('Continue'),
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
      },
    );
  }

  void _handleUsernameChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final value = _usernameController.text.trim();
      if (value.length >= 3) {
        widget.cubit.checkUsername(value);
      }
    });
  }

  Future<void> _submit() async {
    final result = await widget.cubit.createProfile(
      userId: widget.session.userId,
      email: widget.session.email,
      displayName: _displayNameController.text,
      username: _usernameController.text,
      avatarColorValue: 0xFF10B981,
    );
    result.when(
      success: (_) => widget.onCompleted(),
      failure: (_) {},
    );
  }
}
