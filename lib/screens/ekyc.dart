import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard.dart';
import 'bottom_nav_bar.dart' show activeTabNotifier;
import '../services/api_service.dart';

class EkycScreen extends StatefulWidget {
  final bool isFromProfile;
  const EkycScreen({super.key, this.isFromProfile = false});

  @override
  State<EkycScreen> createState() => _EkycScreenState();
}

class _EkycScreenState extends State<EkycScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  // Animation values for floating/pulsing effects
  late Animation<double> _floatAnim1;
  late Animation<double> _floatAnim2;
  late Animation<double> _pulseAnim;

  // State to track if loading is in progress
  bool _isLoading = false;
  int _loadingStep = 0;
  int _currentStep = 1;
  final TextEditingController _ckycController = TextEditingController();
  bool _isButtonEnabled = false;
  final List<String> _loadingMessages = [
    'Establishing encrypted connection to National Registry...',
    'Retrieving biometric verification records...',
    'Authenticating security tokens and credentials...',
    'Finalizing eKYC secure signature...',
    'Verification successful!',
  ];

  @override
  void initState() {
    super.initState();
    // Animation controller for floating micro-animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnim1 = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _floatAnim2 = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Listener to update verify button status
    _ckycController.addListener(() {
      final isEnabled = _ckycController.text.length == 14;
      if (_isButtonEnabled != isEnabled) {
        setState(() {
          _isButtonEnabled = isEnabled;
        });
      }
    });
    
    // Pre-populate with a valid 14-digit CKYC number for verification/testing
    _ckycController.text = '12345678901234';
  }

  @override
  void dispose() {
    _animController.dispose();
    _ckycController.dispose();
    super.dispose();
  }

  void _startVerification() async {
    setState(() {
      _isLoading = true;
      _loadingStep = 0;
    });

    // Start background API operations to link with backend
    try {
      // 1. Register User
      final regResult = await ApiService.instance.register(
        name: 'Aditya Kumar',
        mobile: '9876543210',
        email: 'aditya.kumar@example.com',
      );
      final uid = regResult['userId'] as String;

      // 2. eKYC Verification
      await ApiService.instance.verifyEkyc(
        uid: uid,
        panLast4: '5678',
        aadhaarLast4: '1234',
      );

      // 3. Register Biometric Credentials
      await ApiService.instance.setupBiometric(uid);

      // 4. Set 6-digit PIN
      await ApiService.instance.setPin('123456');

    } catch (e) {
      debugPrint('eKYC API integration error: $e');
    }

    // Run the timer sequence to display steps in the UI
    Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_loadingStep < _loadingMessages.length - 1) {
        setState(() {
          _loadingStep++;
        });
      } else {
        timer.cancel();
        _completeVerification();
      }
    });
  }

  void _completeVerification() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 4;
      });
    });
  }

  void _redirectToNextScreen() {
    if (widget.isFromProfile) {
      // Return to profile
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'eKYC Verification Completed Successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // Redirection to dashboard and resetting activeTab
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: '/home'),
          pageBuilder: (context, animation, secondaryAnimation) => const HomeDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    }
  }

  void _skipOrGoBack() {
    if (widget.isFromProfile || Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Direct access bypass to dashboard
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: '/home'),
          pageBuilder: (context, animation, secondaryAnimation) => const HomeDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync activeTab when showing this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeTabNotifier.value != 'ekyc') {
        activeTabNotifier.value = 'ekyc';
      }
    });

    Widget activeUI;
    if (_isLoading) {
      activeUI = _buildLoadingUI();
    } else if (_currentStep == 2) {
      activeUI = _buildCkycInputUI();
    } else if (_currentStep == 3) {
      activeUI = _buildAuthenticationUI();
    } else if (_currentStep == 4) {
      activeUI = _buildVerificationSuccessUI();
    } else {
      activeUI = _buildOnboardingUI();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: activeUI,
        ),
      ),
    );
  }

  // --- 1. Main Onboarding UI (Matches Figma 1014-1346) ---
  Widget _buildOnboardingUI() {
    return Column(
      key: const ValueKey('onboarding_ui'),
      children: [
        // Status Bar (Replicated for Figma layout consistency)
        const _StatusBar(),

        // Navbar
        _buildNavbar(),

        // Stepper
        _buildStepper(),

        // Content Area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Animated Illustration Stacking
                _buildAnimatedIllustration(),

                const SizedBox(height: 24),

                // Hero Title
                Text(
                  'Verify Your Identity\nSecurely',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B2545),
                    height: 1.2,
                    letterSpacing: -0.84,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Complete your digital KYC verification securely through your bank's authorised verification process.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 26),

                // Why complete eKYC? Card
                _buildBenefitsCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Footer Section
        _buildFooter(),
      ],
    );
  }

  // --- 2. Custom Navbar ---
  Widget _buildNavbar() {
    final bool isStep2 = _currentStep == 2;
    final bool isStep3 = _currentStep == 3;
    final bool isStep4 = _currentStep == 4;

    String title = 'Complete Your eKYC';
    if (isStep2) {
      title = 'Enter Your CKYC Number';
    } else if (isStep3) {
      title = 'Authenticate Your Identity';
    } else if (isStep4) {
      title = 'Verification Complete';
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // Custom Back Button
          GestureDetector(
            onTap: isStep4
                ? null
                : () {
                    if (isStep3) {
                      setState(() {
                        _currentStep = 2;
                      });
                    } else if (isStep2) {
                      setState(() {
                        _currentStep = 1;
                      });
                    } else {
                      _skipOrGoBack();
                    }
                  },
            child: Opacity(
              opacity: isStep4 ? 0.35 : 1.0,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          
          // Navigation Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 38.0), // Balance the back button
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Stepper Indicator ---
  Widget _buildStepper() {
    final int step = _isLoading ? 4 : _currentStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            'STEP $step OF 4',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final int segmentIndex = index + 1;
                Color segmentColor;
                if (segmentIndex < step) {
                  segmentColor = const Color(0xFF0B2545); // Completed (Navy)
                } else if (segmentIndex == step) {
                  segmentColor = const Color(0xFF2E75B6); // Active (Blue)
                } else {
                  segmentColor = const Color(0xFFE2E8F0); // Inactive (Grey)
                }

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index > 0 ? 6.0 : 0.0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: segmentColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  // --- 4. High-Fidelity Animated Illustration ---
  Widget _buildAnimatedIllustration() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          width: 230,
          height: 158,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Light Blue Document Card (Float 1)
              Positioned(
                left: 12,
                top: 8 + _floatAnim1.value,
                width: 96,
                height: 134,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E3F0), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Text Line 1
                      Container(
                        height: 12,
                        width: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFDDEB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Document Text Line 2
                      Container(
                        height: 8,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE7F2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Document Text Line 3
                      Container(
                        height: 8,
                        width: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE7F2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const Spacer(),
                      // User photo box
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD7E3F0)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Bottom Left Green Badge (Float 2)
              Positioned(
                left: 0,
                bottom: 14 + _floatAnim2.value,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 3. Top Right Fingerprint Box (Float 2)
              Positioned(
                right: 6,
                top: 2 + _floatAnim2.value,
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7E3F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 24,
                      color: Color(0xFF2E75B6),
                    ),
                  ),
                ),
              ),

              // 4. Bottom Right Home Box (Float 1)
              Positioned(
                right: 14,
                bottom: 10 + _floatAnim1.value,
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7E3F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.home_outlined,
                      size: 22,
                      color: Color(0xFF2E75B6),
                    ),
                  ),
                ),
              ),

              // 5. Dark Navy Shield (Pulsing Centerpiece)
              Positioned(
                left: 88,
                top: 26,
                width: 78,
                height: 78,
                child: Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2545),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B2545).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 5. Benefits Card ---
  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
            child: Text(
              'Why complete eKYC?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
                letterSpacing: -0.14,
              ),
            ),
          ),

          // Benefit Row 1
          _buildBenefitRow(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFEEF4FA),
            iconColor: const Color(0xFF2E75B6),
            title: 'Faster account activation',
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),

          // Benefit Row 2
          _buildBenefitRow(
            icon: Icons.eco_outlined,
            iconBg: const Color(0xFF16A34A).withOpacity(0.1),
            iconColor: const Color(0xFF16A34A),
            title: 'Fully paperless verification',
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),

          // Benefit Row 3
          _buildBenefitRow(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFEEF4FA),
            iconColor: const Color(0xFF2E75B6),
            title: 'Required to unlock investing',
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.135,
            ),
          )
        ],
      ),
    );
  }

  // --- 6. Footer Section ---
  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2545),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              debugPrint('Antigravity Debug: Continue button clicked!');
              setState(() {
                _currentStep = 2;
              });
            },
            child: Text(
              'Continue to eKYC',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Footnote
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                'Your information is processed securely, only with your consent.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // --- 7. Loading/Verification Simulation Screen ---
  Widget _buildLoadingUI() {
    final double progress = (_loadingStep + 1) / _loadingMessages.length;
    final bool isSuccess = _loadingStep == _loadingMessages.length - 1;

    return Center(
      key: const ValueKey('loading_ui'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status/Progress Indicator Box
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing Background Circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isSuccess ? const Color(0xFF16A34A) : const Color(0xFF2E75B6)).withOpacity(0.08),
                  ),
                ),
                
                // Rotating Circular Progress Indicator
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: isSuccess ? 1.0 : null, // Indeterminate until success
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSuccess ? const Color(0xFF16A34A) : const Color(0xFF2E75B6),
                    ),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),

                // Center Icon changing with Success
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isSuccess
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('success_icon'),
                          size: 56,
                          color: Color(0xFF16A34A),
                        )
                      : const Icon(
                          Icons.security_rounded,
                          key: ValueKey('lock_icon'),
                          size: 40,
                          color: Color(0xFF0B2545),
                        ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),

            // Loading Header Text
            Text(
              isSuccess ? 'Verification Completed' : 'Verifying Identity',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B2545),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Dynamic Step Message
            SizedBox(
              height: 40, // Avoid layout jumping
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _loadingMessages[_loadingStep],
                  key: ValueKey(_loadingStep),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Progress Bar Indicator
            Container(
              height: 6,
              width: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 180 * progress,
                height: 6,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 180 * progress,
                  decoration: BoxDecoration(
                    color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFF2E75B6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. Step 2 (CKYC Entry Screen) UI ---
  Widget _buildCkycInputUI() {
    return Column(
      key: const ValueKey('ckyc_input_ui'),
      children: [
        // Status Bar
        const _StatusBar(),

        // Navbar
        _buildNavbar(),

        // Stepper
        _buildStepper(),

        // Content Area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Description Text
                Text(
                  'Your 14-digit CKYC Number (KIN) helps retrieve your existing KYC records securely from the Central KYC Records Registry (CKYCR).',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Label
                Text(
                  'CKYC NUMBER / KIN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.66,
                  ),
                ),

                const SizedBox(height: 8),

                // Text Field
                _buildCkycTextField(),

                const SizedBox(height: 24),

                // Help Card
                _buildHelpCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Footer Section
        _buildCkycFooter(),
      ],
    );
  }

  Widget _buildCkycTextField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _ckycController,
        keyboardType: TextInputType.number,
        maxLength: 14,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0A1628),
          letterSpacing: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your 14-digit CKYC Number',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0x400A1628), // 25% opacity
            letterSpacing: 0, // no extra spacing for placeholder text
          ),
          counterText: '', // Hide default counter
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E75B6), width: 2),
          ),
          suffixIcon: _ckycController.text.length == 14
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                )
              : _ckycController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _ckycController.clear();
                          _isButtonEnabled = false;
                        });
                      },
                    )
                  : null,
        ),
        onChanged: (val) {
          setState(() {
            _isButtonEnabled = val.length == 14;
          });
        },
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF2E75B6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Don't know your CKYC Number?",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You can obtain your KIN through these authorised channels:",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Option 1: Contact bank branch
          _buildHelpRow(
            icon: Icons.account_balance_outlined,
            iconBg: const Color(0xFFEEF4FA),
            iconColor: const Color(0xFF2E75B6),
            title: 'Contact your bank branch',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please contact your home branch customer support desk for your CKYC details.',
                    style: GoogleFonts.inter(),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 16, endIndent: 16),

          // Option 2: Missed call
          _buildMissedCallRow(),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 16, endIndent: 16),

          // Option 3: Official portal
          _buildHelpRow(
            icon: Icons.language_rounded,
            iconBg: const Color(0xFFEEF4FA),
            iconColor: const Color(0xFF2E75B6),
            title: 'Visit the official CKYC portal',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening CKYC portal registry link...',
                    style: GoogleFonts.inter(),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Footer info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              'Information based on RBI customer awareness guidelines.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.135,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedCallRow() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dialing missed call helpline number 7799022129...',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.call_outlined,
                size: 18,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1628),
                    letterSpacing: -0.135,
                  ),
                  children: [
                    const TextSpan(text: 'Give a missed call '),
                    TextSpan(
                      text: '7799022129',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2E75B6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCkycFooter() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled 
                  ? const Color(0xFF0B2545) 
                  : const Color(0xFF94A3B8),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isButtonEnabled
                ? () {
                    debugPrint('Antigravity Debug: Verify CKYC button clicked!');
                    setState(() {
                      _currentStep = 3;
                    });
                  }
                : null,
            child: Text(
              'Verify CKYC Number',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Footnote
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                'Your KIN is transmitted over an encrypted channel.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // --- 9. Step 3 (Authenticate Your Identity) UI ---
  Widget _buildAuthenticationUI() {
    return Column(
      key: const ValueKey('authentication_ui'),
      children: [
        // Status Bar
        const _StatusBar(),

        // Navbar
        _buildNavbar(),

        // Stepper
        _buildStepper(),

        // Content Area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // CKYC Integration Card
                _buildIntegrationCard(),

                const SizedBox(height: 12),

                // Security Features Checklist Card
                _buildChecklistCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Footer Section
        _buildAuthFooter(),
      ],
    );
  }

  Widget _buildIntegrationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CKYC 2.0 / eKYC Integration',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  'API SLOT',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E75B6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Diagram Container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDiagramNode(icon: Icons.api_rounded),
                    _buildDiagramLink(),
                    _buildDiagramNode(icon: Icons.lock_person_rounded, isDark: true),
                    _buildDiagramLink(),
                    _buildDiagramNode(icon: Icons.account_balance_rounded),
                  ],
                ),
                const SizedBox(
                  height: 22,
                  child: Center(
                    child: DashedLine(
                      direction: Axis.vertical,
                      height: 1.5,
                      color: Color(0xFFB9CBDD),
                    ),
                  ),
                ),
                _buildDiagramNode(icon: Icons.devices_rounded),
                const SizedBox(height: 8),
                Text(
                  'BANK · SECURE GATEWAY · CKYCR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.55,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Subtext
          Text(
            "The bank's authorised CKYC 2.0/eKYC API are integrated at this step to verify your identity.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // Ready status Badge
          Container(
            decoration: BoxDecoration(
              color: const Color(0x1A16A34A),
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Ready for bank API integration',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramNode({
    required IconData icon,
    bool isDark = false,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B2545) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0B2545) : const Color(0xFFD7E3F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x400B2545) : const Color(0x0A0B2545),
            blurRadius: isDark ? 12 : 6,
            offset: Offset(0, isDark ? 6 : 3),
          )
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white : const Color(0xFF2E75B6),
        ),
      ),
    );
  }

  Widget _buildDiagramLink() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const DashedLine(
            direction: Axis.horizontal,
            height: 1.5,
            color: Color(0xFFB9CBDD),
          ),
          Positioned(
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildCheckRow(
            icon: Icons.api_rounded,
            title: 'Secure API gateway',
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildCheckRow(
            icon: Icons.fact_check_rounded,
            title: 'Consent-based verification',
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildCheckRow(
            icon: Icons.lock_rounded,
            title: 'Encrypted data exchange',
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildCheckRow(
            icon: Icons.schema_rounded,
            title: 'Authentication workflow',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF2E75B6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A1628),
                letterSpacing: -0.135,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthFooter() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2545),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              debugPrint('Antigravity Debug: Start Authentication button clicked!');
              _startVerification();
            },
            child: Text(
              'Start Authentication',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Footnote
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your bank completes this verification using its authorised eKYC services.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // --- 10. Step 4 (Verification Complete) UI ---
  Widget _buildVerificationSuccessUI() {
    return Column(
      key: const ValueKey('verification_success_ui'),
      children: [
        // Status Bar
        const _StatusBar(),

        // Navbar
        _buildNavbar(),

        // Stepper
        _buildStepper(),

        // Content Area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Success Core Circle Rings
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0x1A16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Success Heading Title
                Text(
                  'Identity Verified\nSuccessfully',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF0B2545),
                    height: 1.2,
                    letterSpacing: -0.84,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle Description
                Text(
                  'Your eKYC verification is complete. You can now continue setting up your FINIX profile.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Verification Details Card
                _buildSuccessCard(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Footer Section
        _buildSuccessFooter(),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildSuccessCardRow(
            icon: Icons.verified_user_rounded,
            title: 'Status',
            trailing: Text(
              'Verified',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildSuccessCardRow(
            icon: Icons.check_circle_rounded,
            title: 'CKYC record confirmed',
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildSuccessCardRow(
            icon: Icons.check_circle_rounded,
            title: 'Identity authentication completed',
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0), indent: 20, endIndent: 20),
          _buildSuccessCardRow(
            icon: Icons.check_circle_rounded,
            title: 'KYC details verified',
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCardRow({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    final bool isStatusRow = title == 'Status';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        children: [
          isStatusRow
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x1A16A34A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFF16A34A),
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF16A34A),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A1628),
                letterSpacing: -0.135,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSuccessFooter() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2545),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _redirectToNextScreen,
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Footnote
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A tamper-evident record of this verification has been logged.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Private Dashed Line Custom Widget
// ---------------------------------------------------------------------
class DashedLine extends StatelessWidget {
  final double height;
  final Color color;
  final Axis direction;

  const DashedLine({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFB9CBDD),
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double boxLength = direction == Axis.horizontal 
            ? constraints.constrainWidth() 
            : constraints.constrainHeight();
        const double dashLength = 4.0;
        final double dashThickness = height;
        final int dashCount = (boxLength / (2 * dashLength)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: direction,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: direction == Axis.horizontal ? dashLength : dashThickness,
              height: direction == Axis.horizontal ? dashThickness : dashLength,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Status Bar Widget Replicated
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
