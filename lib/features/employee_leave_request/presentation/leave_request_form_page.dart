import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
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

class _LeaveRequestDetail extends StatefulWidget {
  const _LeaveRequestDetail({required this.entityId});

  final int entityId;

  @override
  State<_LeaveRequestDetail> createState() => _LeaveRequestDetailState();
}

class _LeaveRequestDetailState extends State<_LeaveRequestDetail> {
  bool _busy = false;
  String? _error;

  void _refreshListAndReturn() {
    leaveRequestCrudBloc(context).add(const CrudRefreshRequested());
    context.go(leaveRequestManifest.resourcePath);
  }

  Future<void> _setStatus(String status, {String? reason}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = context.read<LeaveRequestRepository>();
    final result = await repo.updateStatus(
      widget.entityId,
      status,
      reason: reason,
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _busy = false;
        _error = switch (f) {
          NetworkFailure(:final message) => message,
          ValidationFailure(:final message) => message,
          ServerFailure(:final message) => message,
          UnknownFailure(:final message) => message,
          _ => f.toString(),
        };
      }),
      (_) => _refreshListAndReturn(),
    );
  }

  Future<void> _reject() async {
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
    if (reason == null || !mounted) return;
    await _setStatus('Rejected', reason: reason.isEmpty ? null : reason);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final repo = context.read<LeaveRequestRepository>();

    return BlocProvider(
      create: (_) =>
          DetailBloc<LeaveRequest, int>(repository: repo, id: widget.entityId)
            ..add(const DetailLoadRequested()),
      child:
          BlocBuilder<DetailBloc<LeaveRequest, int>, DetailState<LeaveRequest>>(
            builder: (context, state) {
              return AsyncStateView<LeaveRequest>(
                state: state.toViewState(),
                onRetry: () => context
                    .read<DetailBloc<LeaveRequest, int>>()
                    .add(const DetailLoadRequested()),
                builder: (context, request) {
                  final pending = request.status == 'Pending';
                  final empLabel =
                      request.employeeName ?? '#${request.employeeId}';
                  final policyLabel =
                      request.policyName ?? '#${request.leavePolicyId}';
                  return ListView(
                    children: [
                      Text(
                        'Leave request #${request.id}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: tokens.spacing.md),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(color: tokens.semanticColors.danger),
                        ),
                        SizedBox(height: tokens.spacing.sm),
                      ],
                      _row('Employee', empLabel),
                      _row('Policy', policyLabel),
                      _row(
                        'From',
                        request.fromDate.toIso8601String().split('T').first,
                      ),
                      _row(
                        'To',
                        request.toDate.toIso8601String().split('T').first,
                      ),
                      _row('Days', request.numberOfDays.toString()),
                      _row('Status', request.status),
                      if (request.reason != null && request.reason!.isNotEmpty)
                        _row('Reason', request.reason!),
                      if (request.rejectionReason != null &&
                          request.rejectionReason!.isNotEmpty)
                        _row('Rejection reason', request.rejectionReason!),
                      SizedBox(height: tokens.spacing.lg),
                      if (pending)
                        PermissionGate(
                          module: leaveRequestManifest.rbacModule,
                          action: PermissionAction.update,
                          child: Wrap(
                            spacing: tokens.spacing.sm,
                            runSpacing: tokens.spacing.sm,
                            children: [
                              FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _setStatus('Approved'),
                                child: Text(_busy ? 'Working…' : 'Approve'),
                              ),
                              OutlinedButton(
                                onPressed: _busy ? null : _reject,
                                child: const Text('Reject'),
                              ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _setStatus('Cancelled'),
                                child: const Text('Cancel request'),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: tokens.spacing.md),
                      TextButton(
                        onPressed: () =>
                            context.go(leaveRequestManifest.resourcePath),
                        child: const Text('Back to list'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
    );
  }

  Widget _row(String label, String value) {
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
