import 'dart:convert';

import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/services/sp_service.dart';
import 'package:frontend/features/auth/repository/auth_local_repo.dart';
import 'package:frontend/models/user_model.dart';
import 'package:http/http.dart' as http;

class AuthRemoteRepo {
  final spService = SpService();
  final authLocalRepo = AuthLocalRepo();
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res =
          await http.post(Uri.parse("${Constants.backEndUri}/auth/signup"),
              body: jsonEncode({
                'name': name,
                'email': email,
                'password': password,
              }),
              headers: {
            'Content-Type': 'application/json',
          });
      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['msg'];
      }
      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res =
          await http.post(Uri.parse("${Constants.backEndUri}/auth/login"),
              body: jsonEncode({
                'email': email,
                'password': password,
              }),
              headers: {
            'Content-Type': 'application/json',
          });
      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['msg'];
      }
      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final token = await spService.getToken();
      if (token == null) {
        return null;
      }
      final res = await http.post(
          Uri.parse("${Constants.backEndUri}/auth/tokenIsValid"),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token,
          });
      if (res.statusCode != 200 || jsonDecode(res.body) == false) {
        return null;
      }
      final userResponse =
          await http.get(Uri.parse("${Constants.backEndUri}/auth"), headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      });
      if (userResponse.statusCode != 200) {
        throw jsonDecode(userResponse.body)['msg'];
      }
      return UserModel.fromJson(userResponse.body);
    } catch (e) {
      final user = await authLocalRepo.getUser();
      print(user);
      return user;
    }
  }
}
