import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart';

class AuthState {
  final User? user;
  final UserProfile? profile;
  final House? currentHouse;
  final HouseMember? houseMembership;
  final bool loading;

  const AuthState({
    this.user,
    this.profile,
    this.currentHouse,
    this.houseMembership,
    this.loading = true,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    House? currentHouse,
    HouseMember? houseMembership,
    bool? loading,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearUser ? null : (profile ?? this.profile),
      currentHouse: clearUser ? null : (currentHouse ?? this.currentHouse),
      houseMembership: clearUser ? null : (houseMembership ?? this.houseMembership),
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await _fetchUserData(user);
      } else {
        state = const AuthState(loading: false);
      }
    });

    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _fetchUserData(currentUser);
    } else {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _fetchUserData(User user) async {
    state = state.copyWith(user: user, loading: true);
    await Future.wait([
      _fetchProfile(user.id),
      _fetchHouseMembership(user.id),
    ]);
    state = state.copyWith(loading: false);
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        state = state.copyWith(profile: UserProfile.fromMap(data));
      }
    } catch (_) {}
  }

  Future<void> _fetchHouseMembership(String userId) async {
    try {
      final memberData = await _supabase
          .from('house_members')
          .select()
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (memberData != null) {
        final membership = HouseMember.fromMap(memberData);
        final houseData = await _supabase
            .from('houses')
            .select()
            .eq('id', membership.houseId)
            .single();
        state = state.copyWith(
          houseMembership: membership,
          currentHouse: House.fromMap(houseData),
        );
      } else {
        state = AuthState(
          user: state.user,
          profile: state.profile,
          loading: false,
        );
      }
    } catch (_) {}
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AuthState(loading: false);
  }

  Future<String?> createHouse(String name, {String? address}) async {
    try {
      await _supabase.rpc('create_house_with_admin', params: {
        '_name': name,
        '_address': address,
      });
      if (state.user != null) {
        await _fetchHouseMembership(state.user!.id);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> joinHouse(String inviteCode) async {
    try {
      final houseData = await _supabase
          .from('houses')
          .select('id')
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (houseData == null) return 'Código de convite inválido';

      await _supabase.from('house_members').insert({
        'house_id': houseData['id'],
        'user_id': state.user!.id,
        'role': 'member',
      });

      await _fetchHouseMembership(state.user!.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refreshHouse() async {
    if (state.user != null) {
      await _fetchHouseMembership(state.user!.id);
    }
  }

  Future<void> updateProfile({String? name, String? phone, String? birthDate, String? occupation}) async {
    if (state.user == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (birthDate != null) updates['birth_date'] = birthDate;
      if (occupation != null) updates['occupation'] = occupation;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', state.user!.id);

      await _fetchProfile(state.user!.id);
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
