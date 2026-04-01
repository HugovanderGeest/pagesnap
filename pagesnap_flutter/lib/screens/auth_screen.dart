import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error occurred')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (res.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email for the login link!')));
        }
      }
    } on AuthException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error occurred')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('Could not securely retrieve Apple ID Token.');

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple Sign In Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'one.peruse.app://login-callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign In Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              Colors.transparent,
            ],
          )
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
              'PERUSE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'READ AT THE SPEED OF THOUGHT.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                hintText: 'Email',
                hintStyle: const TextStyle(color: AppTheme.textDim),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                hintText: 'Password',
                hintStyle: const TextStyle(color: AppTheme.textDim),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SIGN IN', style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
               onPressed: _isLoading ? null : _signUpWithEmail,
               style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: AppTheme.border),
               ),
               child: const Text('CREATE ACCOUNT', style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR CONTINUE WITH', style: TextStyle(color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
            const SizedBox(height: 24),
            SignInWithAppleButton(
              onPressed: _isLoading ? null : _signInWithApple,
              style: SignInWithAppleButtonStyle.black,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
               onPressed: _isLoading ? null : _signInWithGoogle,
               style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: AppTheme.border),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Image.network('https://www.google.com/favicon.ico', height: 20),
                    const SizedBox(width: 12),
                    const Text('Continue with Google', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                 ],
               ),
            ),
          ],
        ),
              ),
            ),
          ),
      ),
    );
  }
}
