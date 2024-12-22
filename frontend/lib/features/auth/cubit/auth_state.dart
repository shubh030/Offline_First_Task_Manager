part of 'auth_cubit.dart';

@immutable
sealed class AuthState {}

final class AuthUserInitial extends AuthState {}

final class AuthUserLoding extends AuthState {}

final class AuthUserSignUp extends AuthState {}

final class AuthUserLogedIn extends AuthState {
  final UserModel user;

  AuthUserLogedIn(this.user);
}

final class AuthUserError extends AuthState {
  final String error;

  AuthUserError(this.error);
}
