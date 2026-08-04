import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/profile_response.dart';
import '../repository/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  Future<void> fetchProfile() async {
    if (isClosed) return;
    try {
      emit(ProfileLoading());
      final profile = await _profileRepository.getProfile();
      if (isClosed) return;
      emit(ProfileLoaded(profile));
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? email,
    String? fullName,
    String? phoneNumber,
    int? departmentId,
    String? jobTitle,
    String? startDate,
    String? companyPhoneNumber,
    String? companyEmail,
    File? image,
  }) async {
    if (isClosed) return;
    try {
      emit(ProfileUpdating());
      await _profileRepository.updateProfile(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        departmentId: departmentId,
        jobTitle: jobTitle,
        startDate: startDate,
        companyPhoneNumber: companyPhoneNumber,
        companyEmail: companyEmail,
        image: image,
      );
      if (isClosed) return;
      emit(ProfileUpdateSuccess());
      // Re-fetch profile to get updated data
      await fetchProfile();
    } catch (e) {
      if (isClosed) return;
      emit(ProfileUpdateError(e.toString()));
    }
  }
}