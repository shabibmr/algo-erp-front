import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/features/employee_leave_request/cubit/leave_request_action_cubit.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_repository.dart';
import 'package:algo_erp_front/features/employee_leave_request/domain/leave_request.dart';
import 'package:algo_erp_front/features/employee_leave_request/leave_request_di.dart';
import 'package:algo_erp_front/features/employee_leave_request/leave_request_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create uses MasterFormSurface. Edit is a read-only detail + status actions.
class LeaveRequestFormPage extends StatelessWidget {
  const LeaveRequestFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    if (mode == FormMode.create) {
      return RepositoryProvider<Repository<LeaveRequest, int>>(
        create: (_) => createLeaveRequestRepository(getIt<DioClient>()),
        child: Builder(
          builder: (context) {
            void refreshListAndReturn() {
              leaveRequestCrudBloc(context).add(const CrudRefreshRequested());
              context.go(leaveRequestManifest.resourcePath);
            }

            return AdaptiveLayout(
              child: MasterFormSurface<LeaveRequest, int>(
                manifest: leaveRequestManifest,
                mode: FormMode.create,
                idOf: (r) => r.id,
                onSaved: (_) => refreshListAndReturn(),
                onDeleted: refreshListAndReturn,
                onCancel: () => context.go(leaveRequestManifest.resourcePath),
              ),
            );
          },
        ),
      );
    }

    return RepositoryProvider<LeaveRequestRepository>(
      create: (_) => createLeaveRequestRepository(getIt<DioClient>()),
      child: AdaptiveLayout(child: _LeaveRequestDetail(entityId: entityId!)),
    );
  }
}

class _LeaveRequestDetail extends StatelessWidget {
  const _LeaveRequestDetail({required this.entityId});

  final int entityId;

  void _refreshListAndReturn(BuildContext context) {
    leaveRequestCrudBloc(context).add(const CrudRefreshRequested());
    context.go(leaveRequestManifest.resourcePath);
  }

  Future<void> _reject(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject leave request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Optional rejection reason',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    await context.read<LeaveRequestActionCubit>().setStatus(
      'Rejected',
      reason: reason.isEmpty ? null : reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final repo = context.read<LeaveRequestRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              DetailBloc<LeaveRequest, int>(repository: repo, id: entityId)
                ..add(const DetailLoadRequested()),
        ),
        BlocProvider(
          create: (_) =>
              LeaveRequestActionCubit(repository: repo, entityId: entityId),
        ),
      ],
      child: BlocListener<LeaveRequestActionCubit, LeaveRequestActionState>(
        listenWhen: (p, c) => !p.done && c.done,
        listener: (context, state) => _refreshListAndReturn(context),
        child:
            BlocBuilder<
              DetailBloc<LeaveRequest, int>,
              DetailState<LeaveRequest>
            >(
              builder: (context, state) {
                return AsyncStateView<LeaveRequest>(
                  state: state.toViewState(),
                  onRetry: () => context
                      .read<DetailBloc<LeaveRequest, int>>()
                      .add(const DetailLoadRequested()),
                  builder: (context, request) {
                    return BlocBuilder<
                      LeaveRequestActionCubit,
                      LeaveRequestActionState
                    >(
                      builder: (context, action) {
                        final pending = request.status == 'Pending';
                        final empLabel =
                            request.employeeName ?? '#${request.employeeId}';
                        final policyLabel =
                            request.policyName ?? '#${request.leavePolicyId}';
                        final cubit = context.read<LeaveRequestActionCubit>();
                        return ListView(
                          children: [
                            PageHeader(
                              eyebrow: leaveRequestManifest.eyebrowText,
                              title: 'Leave request #${request.id}',
                              actions: [
                                TextButton(
                                  onPressed: () => context.go(
                                    leaveRequestManifest.resourcePath,
                                  ),
                                  child: const Text('Back to list'),
                                ),
                              ],
                            ),
                            SizedBox(height: tokens.spacing.md),
                            if (action.error != null) ...[
                              Text(
                                action.error!,
                                style: TextStyle(
                                  color: tokens.semanticColors.danger,
                                ),
                              ),
                              SizedBox(height: tokens.spacing.sm),
                            ],
                            Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: FieldWidths.formContent,
                                ),
                                child: WorkSheet(
                                  fill: false,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tokens.spacing.md,
                                    vertical: tokens.spacing.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _row(context, 'Employee', empLabel),
                                      _row(context, 'Policy', policyLabel),
                                      _row(
                                        context,
                                        'From',
                                        request.fromDate
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                      ),
                                      _row(
                                        context,
                                        'To',
                                        request.toDate
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                      ),
                                      _row(
                                        context,
                                        'Days',
                                        request.numberOfDays.toString(),
                                      ),
                                      _row(context, 'Status', request.status),
                                      if (request.reason != null &&
                                          request.reason!.isNotEmpty)
                                        _row(
                                          context,
                                          'Reason',
                                          request.reason!,
                                        ),
                                      if (request.rejectionReason != null &&
                                          request.rejectionReason!.isNotEmpty)
                                        _row(
                                          context,
                                          'Rejection reason',
                                          request.rejectionReason!,
                                        ),
                                      if (pending) ...[
                                        SizedBox(height: tokens.spacing.md),
                                        PermissionGate(
                                          module:
                                              leaveRequestManifest.rbacModule,
                                          action: PermissionAction.update,
                                          child: Wrap(
                                            spacing: tokens.spacing.sm,
                                            runSpacing: tokens.spacing.sm,
                                            children: [
                                              FilledButton(
                                                onPressed: action.busy
                                                    ? null
                                                    : () => cubit.setStatus(
                                                        'Approved',
                                                      ),
                                                child: Text(
                                                  action.busy
                                                      ? 'Working…'
                                                      : 'Approve',
                                                ),
                                              ),
                                              OutlinedButton(
                                                onPressed: action.busy
                                                    ? null
                                                    : () => _reject(context),
                                                child: const Text('Reject'),
                                              ),
                                              TextButton(
                                                onPressed: action.busy
                                                    ? null
                                                    : () => cubit.setStatus(
                                                        'Cancelled',
                                                      ),
                                                child: const Text(
                                                  'Cancel request',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.tokens.brand.inkMuted,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
