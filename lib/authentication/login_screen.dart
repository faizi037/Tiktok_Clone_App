import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'registration_screen.dart';
import 'package:tiktok_app/authentication/authentication_controller.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showSpinner = false;
  bool _isPasswordVisible = false;
  final AuthenticationController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Image.asset("images/tiktok.png", width: 100, height: 100),
              const SizedBox(height: 30),

              Text("Welcome",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 5),
              Text("Glad to see you!",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(Icons.email_outlined, "Email"),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.white70),
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: () async {
                  setState(() => showSpinner = true);

                  bool success = await authController.login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );

                  if (mounted) {
                    setState(() => showSpinner = false);
                  }

                  if (success) {
                    Get.off(() => const HomeScreen());
                  } else {
                    Get.snackbar(
                      "Login Failed",
                      "Incorrect email or password",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(12),
                      borderRadius: 10,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text("Login",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showSpinner
                    ? const SimpleCircularProgressBar(
                        key: ValueKey("spinner"),
                        progressColors: [
                          Colors.green,
                          Colors.blueAccent,
                          Colors.red,
                          Colors.amber,
                          Colors.purpleAccent,
                        ],
                      )
                    : const SizedBox(height: 5, key: ValueKey("space")),
              ),
              const SizedBox(height: 10),

              if (!showSpinner)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don’t have an Account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        )),
                    GestureDetector(
                      onTap: () => Get.to(() => const RegistrationScreen()),
                      child: Text("SignUp Now",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }
}
