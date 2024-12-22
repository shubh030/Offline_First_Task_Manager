import 'package:flutter/material.dart';
import 'package:frontend/core/services/sp_service.dart';
import 'package:frontend/features/auth/repository/auth_local_repo.dart';
import 'package:frontend/features/auth/repository/auth_remote_repo.dart';
import 'package:frontend/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthUserInitial());

  final authRemoterepo = AuthRemoteRepo();
  final authLocalRepo = AuthLocalRepo();
  final spService = SpService();

  void getUserData() async {
    try {
      emit(AuthUserLoding());

      final userModel = await authRemoterepo.getUserData();

      if (userModel != null) {
        await authLocalRepo.insertUser(userModel);

        emit(AuthUserLogedIn(userModel));
      } else {
        emit(AuthUserInitial());
      }
    } catch (e) {
      emit(AuthUserInitial());
    }
  }

  void signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthUserLoding());

      await authRemoterepo.signUp(
        name: name,
        email: email,
        password: password,
      );
      emit(AuthUserSignUp());
    } catch (e) {
      emit(AuthUserError(e.toString()));
    }
  }

  void login({required String email, required String password}) async {
    try {
      emit(AuthUserLoding());

      final userModel = await authRemoterepo.login(
        email: email,
        password: password,
      );
      if (userModel.token.isNotEmpty) {
        await spService.setToken(userModel.token);
      }
      await authLocalRepo.insertUser(userModel);
      emit(AuthUserLogedIn(userModel));
    } catch (e) {
      emit(AuthUserError(e.toString()));
    }
  }
}
