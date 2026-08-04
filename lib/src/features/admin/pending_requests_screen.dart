import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/service_locator.dart';
import 'admin_requests_screen.dart';
import 'cubit/admin_requests_cubit.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminRequestsCubit>(),
      child: const AdminRequestsScreen(),
    );
  }
}
