import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/mixins/keyboard_dismiss_mixin.dart';
import 'create_mission_controller.dart';
import 'widgets/sections/mission_basic_info_section.dart';
import 'widgets/sections/mission_notes_section.dart';
import 'widgets/sections/mission_schedule_section.dart';
import 'widgets/sections/mission_submit_bar.dart';
import 'widgets/sections/mission_time_slot_section.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen>
    with KeyboardDismissMixin {
  late final CreateMissionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateMissionController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'تسجيل مأمورية جديدة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _controller.formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                MissionBasicInfoSection(controller: _controller),
                const SizedBox(height: 24),
                MissionNotesSection(controller: _controller),
                const SizedBox(height: 24),
                MissionScheduleSection(controller: _controller),
                const SizedBox(height: 24),
                MissionTimeSlotSection(controller: _controller),
                const SizedBox(height: 32),
                MissionSubmitBar(
                  isSubmitting: _controller.isSubmitting,
                  onSubmit: () => _controller.submitMission(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
