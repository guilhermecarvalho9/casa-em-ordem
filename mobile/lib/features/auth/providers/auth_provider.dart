import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/auth_models.dart';

class AuthState {
  final User? user;
  final UserProfile? profile;
  final House? currentHouse;
  final HouseMember? houseMembership;
  final bool loading;
  final bool accessExpired;

  const AuthState({
    this.user,
    this.profile,
    this.currentHouse,
    this.houseMembership,
    this.loading = true,
    this.accessExpired = false,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    House? currentHouse,
    HouseMember? houseMembership,
    bool? loading,
    bool? accessExpired,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearUser ? null : (profile ?? this.profile),
      currentHouse: clearUser ? null : (currentHouse ?? this.currentHouse),
      houseMembership:
          clearUser ? null : (houseMembership ?? this.houseMembership),
      loading: loading ?? this.loading,
      accessExpired: clearUser ? false : (accessExpired ?? this.accessExpired),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _fetchUserData(user);
      } else {
        state = const AuthState(loading: false);
      }
    });
  }

  Future<void> _fetchUserData(User user) async {
    state = state.copyWith(user: user, loading: true);
    await Future.wait([
      _fetchProfile(user.uid),
      _fetchHouseMembership(user.uid),
    ]);
    state = state.copyWith(loading: false);
  }

  Future<void> _fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        state = state.copyWith(
          profile: UserProfile.fromMap(uid, doc.data()!),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchHouseMembership(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final houseId = userDoc.data()?['houseId'] as String?;

      if (houseId == null || houseId.isEmpty) {
        state = AuthState(user: state.user, profile: state.profile, loading: false);
        return;
      }

      final houseDoc = await _db.collection('houses').doc(houseId).get();
      if (!houseDoc.exists) {
        state = AuthState(user: state.user, profile: state.profile, loading: false);
        return;
      }

      final memberDoc = await _db
          .collection('houses')
          .doc(houseId)
          .collection('members')
          .doc(uid)
          .get();

      if (!memberDoc.exists) {
        state = AuthState(user: state.user, profile: state.profile, loading: false);
        return;
      }

      final membership = HouseMember.fromMap(uid, houseId, memberDoc.data()!);

      if (membership.isExpired) {
        state = AuthState(
          user: state.user,
          profile: state.profile,
          loading: false,
          accessExpired: true,
        );
        return;
      }

      state = state.copyWith(
        currentHouse: House.fromMap(houseId, houseDoc.data()!),
        houseMembership: membership,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String name, String countryCode) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'color': '#2A9D90',
        'countryCode': countryCode,
        'houseId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(loading: false);
  }

  Future<String?> createHouse(String name, {String? address}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Usuário não autenticado';

      final inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
      final houseRef = _db.collection('houses').doc();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final normalizedAddress = (address != null && address.isNotEmpty) ? address : null;

      final batch = _db.batch();

      batch.set(houseRef, {
        'name': name,
        if (normalizedAddress != null) 'address': normalizedAddress,
        'inviteCode': inviteCode,
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(houseRef.collection('members').doc(uid), {
        'userId': uid,
        'role': 'admin',
        'entryDate': today,
        'name': state.profile?.name ?? '',
        'color': state.profile?.color ?? '#2A9D90',
        if (state.profile?.countryCode != null) 'countryCode': state.profile!.countryCode,
      });

      batch.update(_db.collection('users').doc(uid), {
        'houseId': houseRef.id,
      });

      await batch.commit();

      // Update state directly from data we just wrote — avoids Firestore cache
      // timing issues on Android where a subsequent get() may return stale data.
      state = state.copyWith(
        currentHouse: House(
          id: houseRef.id,
          name: name,
          address: normalizedAddress,
          inviteCode: inviteCode,
        ),
        houseMembership: HouseMember(
          id: uid,
          houseId: houseRef.id,
          userId: uid,
          role: 'admin',
          entryDate: today,
        ),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> joinHouse(String inviteCode) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Usuário não autenticado';

      final query = await _db
          .collection('houses')
          .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 'Código de convite inválido';

      final houseDoc = query.docs.first;
      final houseId = houseDoc.id;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Enforce free-plan member limit of 2 using memberCount field (no extra query needed)
      final isPro = houseDoc.data()['isPro'] as bool? ?? false;
      if (!isPro) {
        final memberCount = houseDoc.data()['memberCount'] as int? ?? 0;
        if (memberCount >= 2) {
          return 'Limite de 2 membros atingido. Faça upgrade para o plano PRO.';
        }
      }

      final batch = _db.batch();

      batch.set(houseDoc.reference.collection('members').doc(uid), {
        'userId': uid,
        'role': 'member',
        'entryDate': today,
        'name': state.profile?.name ?? '',
        'color': state.profile?.color ?? '#2A9D90',
        if (state.profile?.countryCode != null) 'countryCode': state.profile!.countryCode,
      });

      batch.update(_db.collection('users').doc(uid), {
        'houseId': houseId,
      });

      batch.update(houseDoc.reference, {
        'memberCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Update state directly — avoids Android Firestore cache timing issues.
      state = state.copyWith(
        currentHouse: House.fromMap(houseId, houseDoc.data()),
        houseMembership: HouseMember(
          id: uid,
          houseId: houseId,
          userId: uid,
          role: 'member',
          entryDate: today,
        ),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refreshHouse() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) await _fetchHouseMembership(uid);
  }

  Future<void> updateProfile({String? name, String? countryCode}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (countryCode != null) updates['countryCode'] = countryCode;

      await _db.collection('users').doc(uid).update(updates);

      final memberUpdates = <String, dynamic>{};
      if (name != null) memberUpdates['name'] = name;
      if (countryCode != null) memberUpdates['countryCode'] = countryCode;

      if (memberUpdates.isNotEmpty && state.currentHouse != null) {
        await _db
            .collection('houses')
            .doc(state.currentHouse!.id)
            .collection('members')
            .doc(uid)
            .update(memberUpdates);
      }

      await _fetchProfile(uid);
    } catch (_) {}
  }

  Future<String?> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return 'Usuário não autenticado';

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;
      final houseId = state.currentHouse?.id;

      final batch = _db.batch();
      if (houseId != null && houseId.isNotEmpty) {
        batch.delete(
            _db.collection('houses').doc(houseId).collection('members').doc(uid));
      }
      batch.delete(_db.collection('users').doc(uid));
      await batch.commit();

      await user.delete();

      state = const AuthState(loading: false);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateHouseAddress(String address) async {
    final houseId = state.currentHouse?.id;
    final uid = _auth.currentUser?.uid;
    if (houseId == null || uid == null) return 'Erro: casa não encontrada';
    try {
      await _db.collection('houses').doc(houseId).update({'address': address});
      await _fetchHouseMembership(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateHouseDetails(Map<String, dynamic> data) async {
    final houseId = state.currentHouse?.id;
    final uid = _auth.currentUser?.uid;
    if (houseId == null || uid == null) return 'Erro: casa não encontrada';
    try {
      await _db.collection('houses').doc(houseId).update(data);
      await _fetchHouseMembership(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateAvatar(File file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Usuário não autenticado';
    try {
      final ext = file.path.split('.').last;
      final ref = FirebaseStorage.instance.ref('users/$uid/avatar.$ext');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _db.collection('users').doc(uid).update({'avatarUrl': url});
      if (state.currentHouse != null) {
        await _db
            .collection('houses')
            .doc(state.currentHouse!.id)
            .collection('members')
            .doc(uid)
            .update({'avatarUrl': url});
      }
      await _fetchProfile(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateColor(String hex) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Usuário não autenticado';
    try {
      await _db.collection('users').doc(uid).update({'color': hex});
      if (state.currentHouse != null) {
        await _db
            .collection('houses')
            .doc(state.currentHouse!.id)
            .collection('members')
            .doc(uid)
            .update({'color': hex});
      }
      await _fetchProfile(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateHouseName(String name) async {
    final houseId = state.currentHouse?.id;
    final uid = _auth.currentUser?.uid;
    if (houseId == null || uid == null) return 'Erro: casa não encontrada';
    try {
      await _db.collection('houses').doc(houseId).update({'name': name});
      await _fetchHouseMembership(uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-credential':
        return 'Email ou senha inválidos';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'Email inválido';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Erro de autenticação: $code';
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
