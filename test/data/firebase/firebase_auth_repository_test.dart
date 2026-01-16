import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hex_buzz/data/firebase/firebase_auth_repository.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockUser extends Mock implements firebase_auth.User {}

class MockUserMetadata extends Mock implements firebase_auth.UserMetadata {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class FakeAuthCredential extends Fake implements firebase_auth.AuthCredential {}

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  group('FirebaseAuthRepository', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late MockGoogleSignIn mockGoogleSignIn;
    late FirebaseAuthRepository repository;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();

      // Default stub for currentUser
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      // Default stub for authStateChanges
      when(
        () => mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      repository = FirebaseAuthRepository(
        firebaseAuth: mockFirebaseAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
      );
    });

    group('signInWithGoogle', () {
      test('succeeds with valid Google account and creates new user', () async {
        // Setup mocks
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('test-uid');
        when(() => mockFirebaseUser.email).thenReturn('test@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Test User');
        when(
          () => mockFirebaseUser.photoURL,
        ).thenReturn('https://example.com/photo.jpg');
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthSuccess>());
        final success = result as AuthSuccess;
        expect(success.user.uid, 'test-uid');
        expect(success.user.email, 'test@example.com');
        expect(success.user.displayName, 'Test User');
        expect(success.user.photoURL, 'https://example.com/photo.jpg');

        // Verify user was created in Firestore
        final userDoc = await fakeFirestore
            .collection('users')
            .doc('test-uid')
            .get();
        expect(userDoc.exists, isTrue);
        expect(userDoc.data()!['email'], 'test@example.com');
      });

      test('updates existing user on sign in', () async {
        // Create existing user in Firestore
        await fakeFirestore.collection('users').doc('existing-uid').set({
          'id': 'existing-uid',
          'username': 'OldUsername',
          'createdAt': DateTime(2023, 1, 1).toIso8601String(),
          'isGuest': false,
          'uid': 'existing-uid',
          'email': 'old@example.com',
          'totalStars': 150,
        });

        // Setup mocks
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('existing-uid');
        when(() => mockFirebaseUser.email).thenReturn('updated@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Updated Name');
        when(
          () => mockFirebaseUser.photoURL,
        ).thenReturn('https://example.com/new.jpg');
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthSuccess>());
        final success = result as AuthSuccess;
        expect(success.user.totalStars, 150); // Preserved from existing user

        // Verify user was updated in Firestore
        final userDoc = await fakeFirestore
            .collection('users')
            .doc('existing-uid')
            .get();
        expect(userDoc.data()!['email'], 'updated@example.com');
        expect(userDoc.data()!['displayName'], 'Updated Name');
        expect(userDoc.data()!['totalStars'], 150); // Unchanged
      });

      test('returns failure when user cancels sign-in', () async {
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthFailure>());
        expect((result as AuthFailure).error, 'Sign-in cancelled by user');
      });

      test('returns failure when Firebase auth fails', () async {
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(() => mockFirebaseAuth.signInWithCredential(any())).thenThrow(
          firebase_auth.FirebaseAuthException(code: 'network-request-failed'),
        );

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthFailure>());
        expect(
          (result as AuthFailure).error,
          'Network error. Please check your connection',
        );
      });

      test('maps Firebase auth error codes correctly', () async {
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenThrow(firebase_auth.FirebaseAuthException(code: 'user-disabled'));

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthFailure>());
        expect((result as AuthFailure).error, 'This account has been disabled');
      });

      test('returns failure when no user returned from credential', () async {
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(null);

        final result = await repository.signInWithGoogle();

        expect(result, isA<AuthFailure>());
        expect(
          (result as AuthFailure).error,
          'Authentication failed: no user returned',
        );
      });
    });

    group('signOut', () {
      test('signs out from both Firebase and Google', () async {
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        await repository.signOut();

        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });

      test('completes even if sign out fails', () async {
        when(
          () => mockFirebaseAuth.signOut(),
        ).thenThrow(Exception('Sign out failed'));
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Should not throw
        await repository.signOut();

        // Verify attempted sign out
        verify(() => mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('returns null when no user is signed in', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        final user = await repository.getCurrentUser();

        expect(user, isNull);
      });

      test('returns user from Firestore when available', () async {
        // Create user in Firestore
        await fakeFirestore.collection('users').doc('test-uid').set({
          'id': 'test-uid',
          'username': 'TestUser',
          'createdAt': DateTime.now().toIso8601String(),
          'isGuest': false,
          'uid': 'test-uid',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'totalStars': 100,
        });

        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('test-uid');
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.uid, 'test-uid');
        expect(user.username, 'TestUser');
        expect(user.totalStars, 100);
      });

      test('syncs from Firebase Auth if not in Firestore', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('new-uid');
        when(() => mockFirebaseUser.email).thenReturn('new@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('New User');
        when(() => mockFirebaseUser.photoURL).thenReturn(null);
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.uid, 'new-uid');
        expect(user.email, 'new@example.com');

        // Verify user was created in Firestore
        final userDoc = await fakeFirestore
            .collection('users')
            .doc('new-uid')
            .get();
        expect(userDoc.exists, isTrue);
      });

      test('returns minimal user if Firestore fails', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('test-uid');
        when(() => mockFirebaseUser.email).thenReturn('test@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Test User');
        when(() => mockFirebaseUser.photoURL).thenReturn(null);
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        // Create invalid Firestore data that will fail to parse
        await fakeFirestore.collection('users').doc('test-uid').set({
          'invalid': 'data',
        });

        final user = await repository.getCurrentUser();

        // Should still return a user based on Firebase Auth
        expect(user, isNotNull);
        expect(user!.uid, 'test-uid');
        expect(user.email, 'test@example.com');
      });
    });

    group('authStateChanges', () {
      test('emits null when user signs out', () async {
        when(
          () => mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.value(null));

        // Create new repository to trigger auth state listener
        final testRepo = FirebaseAuthRepository(
          firebaseAuth: mockFirebaseAuth,
          firestore: fakeFirestore,
          googleSignIn: mockGoogleSignIn,
        );

        final user = await testRepo.authStateChanges().first;
        expect(user, isNull);
      });

      test('emits user when signed in', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseUser.uid).thenReturn('test-uid');
        when(() => mockFirebaseUser.email).thenReturn('test@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('Test User');
        when(() => mockFirebaseUser.photoURL).thenReturn(null);
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        when(
          () => mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.value(mockFirebaseUser));

        // Create new repository to trigger auth state listener
        final testRepo = FirebaseAuthRepository(
          firebaseAuth: mockFirebaseAuth,
          firestore: fakeFirestore,
          googleSignIn: mockGoogleSignIn,
        );

        final user = await testRepo.authStateChanges().first;
        expect(user, isNotNull);
        expect(user!.uid, 'test-uid');
      });
    });

    group('legacy methods', () {
      test('login returns failure', () async {
        final result = await repository.login('user', 'pass');
        expect(result, isA<AuthFailure>());
        expect(
          (result as AuthFailure).error,
          contains('not supported with Firebase'),
        );
      });

      test('register returns failure', () async {
        final result = await repository.register('user', 'pass');
        expect(result, isA<AuthFailure>());
        expect(
          (result as AuthFailure).error,
          contains('not supported with Firebase'),
        );
      });

      test('loginAsGuest returns failure', () async {
        final result = await repository.loginAsGuest();
        expect(result, isA<AuthFailure>());
        expect((result as AuthFailure).error, contains('not supported'));
      });

      test('logout delegates to signOut', () async {
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        await repository.logout();

        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('user profile sync', () {
      test('creates new user profile with all fields', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseUser.uid).thenReturn('new-user-uid');
        when(() => mockFirebaseUser.email).thenReturn('new@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('New User');
        when(
          () => mockFirebaseUser.photoURL,
        ).thenReturn('https://example.com/photo.jpg');
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        // Manually trigger sync through getCurrentUser
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        await repository.getCurrentUser();

        final userDoc = await fakeFirestore
            .collection('users')
            .doc('new-user-uid')
            .get();

        expect(userDoc.exists, isTrue);
        expect(userDoc.data()!['uid'], 'new-user-uid');
        expect(userDoc.data()!['email'], 'new@example.com');
        expect(userDoc.data()!['displayName'], 'New User');
        expect(userDoc.data()!['photoURL'], 'https://example.com/photo.jpg');
        expect(userDoc.data()!['totalStars'], 0);
        expect(userDoc.data()!['isGuest'], false);
      });

      test('updates existing user profile fields on login', () async {
        // Create existing user
        await fakeFirestore.collection('users').doc('existing-uid').set({
          'id': 'existing-uid',
          'username': 'OldUsername',
          'createdAt': DateTime(2023, 1, 1).toIso8601String(),
          'isGuest': false,
          'uid': 'existing-uid',
          'email': 'old@example.com',
          'totalStars': 200,
        });

        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(
          () => mockGoogleUser.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('mock_id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('existing-uid');
        when(() => mockFirebaseUser.email).thenReturn('newemail@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn('New Display Name');
        when(
          () => mockFirebaseUser.photoURL,
        ).thenReturn('https://example.com/new.jpg');
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2023, 1, 1));

        final result = await repository.signInWithGoogle();

        // Check returned user object has updated fields
        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user.email, 'newemail@example.com');
        expect(user.displayName, 'New Display Name');
        expect(user.photoURL, 'https://example.com/new.jpg');
        expect(user.totalStars, 200); // Preserved
        expect(user.username, 'OldUsername'); // Preserved
      });

      test('uses email as username fallback when no displayName', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseUser.uid).thenReturn('email-user-uid');
        when(() => mockFirebaseUser.email).thenReturn('emailuser@example.com');
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        when(() => mockFirebaseUser.photoURL).thenReturn(null);
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        final user = await repository.getCurrentUser();

        expect(user!.username, 'emailuser@example.com');

        final userDoc = await fakeFirestore
            .collection('users')
            .doc('email-user-uid')
            .get();
        expect(userDoc.data()!['username'], 'emailuser@example.com');
      });

      test('uses "User" as fallback when no displayName or email', () async {
        final mockFirebaseUser = MockUser();
        final mockUserMetadata = MockUserMetadata();

        when(() => mockFirebaseUser.uid).thenReturn('anonymous-uid');
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        when(() => mockFirebaseUser.photoURL).thenReturn(null);
        when(() => mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
        when(
          () => mockUserMetadata.creationTime,
        ).thenReturn(DateTime(2024, 1, 1));

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        final user = await repository.getCurrentUser();

        expect(user!.username, 'User');

        final userDoc = await fakeFirestore
            .collection('users')
            .doc('anonymous-uid')
            .get();
        expect(userDoc.data()!['username'], 'User');
      });
    });
  });
}
