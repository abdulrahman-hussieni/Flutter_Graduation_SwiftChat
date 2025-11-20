// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/controllers/AuthController.dart';
import 'package:graduation_swiftchat/widgets/PrimaryButton.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _autoValidate = false;
  String? selectedGender;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name required';
    }
    if (value.length < 3) {
      return 'Minimum 3 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password required';
    }
    if (value.length < 6) {
      return 'Minimum 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.put(AuthController());

    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          const SizedBox(height: 30),
          TextFormField(
            controller: nameController,
            validator: validateName,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person, size: 20),
              errorStyle: TextStyle(fontSize: 14, height: 0.5),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            validator: validateEmail,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              errorStyle: TextStyle(fontSize: 14, height: 0.5),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: passwordController,
            validator: validatePassword,
            obscureText: true,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.password_outlined, size: 20),
              errorStyle: TextStyle(fontSize: 14, height: 0.5),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedGender == null && _autoValidate
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Male',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: 'Male',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Female',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: 'Female',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Obx(
            () => authController.isLoading.value
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PrimaryButton(
                        onTap: () {
                          if (_formKey.currentState!.validate() &&
                              selectedGender != null) {
                            authController.createUser(
                              emailController.text.trim(),
                              passwordController.text,
                              nameController.text.trim(),
                              selectedGender!,
                            );
                          } else {
                            setState(() {
                              _autoValidate = true;
                            });
                            if (selectedGender == null) {
                              Get.snackbar(
                                'Error',
                                'Please select your gender',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: Duration(seconds: 2),
                              );
                            }
                          }
                        },

                        butName: "SIGN UP",
                        butIcon: Icons.lock_open_sharp,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
