import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get userStream => firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> resetPassword(String code, String newPassword) async {
    try {
      await firebaseAuth.verifyPasswordResetCode(code);
      await firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> updateUserProfile(String displayName, String photoURL) async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updateProfile(displayName: displayName, photoURL: photoURL);
        await user.reload(); // Reload the user to get the updated info
      }
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> deleteUser() async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> verifyEmail() async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> resetPasswordFromCurrentUser(String newPassword) async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
      }
    } catch (e) {
      rethrow; // Handle error appropriately in your app
    }
  }
}
