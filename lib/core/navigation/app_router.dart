import 'dart:async';

import 'package:algo_erp_front/core/navigation/app_shell.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/theme/theme_preview_page.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/widgets/gallery/widget_gallery_page.dart';
import 'package:algo_erp_front/core/widgets/layout/module_hub_page.dart';
import 'package:algo_erp_front/features/accounts_account_group/presentation/account_group_form_page.dart';
import 'package:algo_erp_front/features/accounts_account_group/presentation/account_group_list_page.dart';
import 'package:algo_erp_front/features/accounts_ledger/presentation/ledger_form_page.dart';
import 'package:algo_erp_front/features/accounts_ledger/presentation/ledger_list_page.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/auth/presentation/pages/login_page.dart';
import 'package:algo_erp_front/features/desk/presentation/pages/todays_desk_page.dart';
import 'package:algo_erp_front/features/employee_department/presentation/department_form_page.dart';
import 'package:algo_erp_front/features/employee_department/presentation/department_list_page.dart';
import 'package:algo_erp_front/features/employee_designation/presentation/designation_form_page.dart';
import 'package:algo_erp_front/features/employee_designation/presentation/designation_list_page.dart';
import 'package:algo_erp_front/features/employee_employee/presentation/employee_form_page.dart';
import 'package:algo_erp_front/features/employee_employee/presentation/employee_list_page.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/presentation/leave_allocation_form_page.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/presentation/leave_allocation_list_page.dart';
import 'package:algo_erp_front/features/employee_leave_policy/presentation/leave_policy_form_page.dart';
import 'package:algo_erp_front/features/employee_leave_policy/presentation/leave_policy_list_page.dart';
import 'package:algo_erp_front/features/employee_leave_request/presentation/leave_request_form_page.dart';
import 'package:algo_erp_front/features/employee_leave_request/presentation/leave_request_list_page.dart';
import 'package:algo_erp_front/features/employee_shift/presentation/shift_master_form_page.dart';
import 'package:algo_erp_front/features/employee_shift/presentation/shift_master_list_page.dart';
import 'package:algo_erp_front/features/inventory_batch/presentation/item_batch_form_page.dart';
import 'package:algo_erp_front/features/inventory_batch/presentation/item_batch_list_page.dart';
import 'package:algo_erp_front/features/inventory_brand/presentation/brand_form_page.dart';
import 'package:algo_erp_front/features/inventory_brand/presentation/brand_list_page.dart';
import 'package:algo_erp_front/features/inventory_attribute/presentation/product_attribute_form_page.dart';
import 'package:algo_erp_front/features/inventory_attribute/presentation/product_attribute_list_page.dart';
import 'package:algo_erp_front/features/inventory_category/presentation/category_form_page.dart';
import 'package:algo_erp_front/features/inventory_category/presentation/category_list_page.dart';
import 'package:algo_erp_front/features/inventory_godown/presentation/godown_form_page.dart';
import 'package:algo_erp_front/features/inventory_godown/presentation/godown_list_page.dart';
import 'package:algo_erp_front/features/inventory_group/presentation/inventory_group_form_page.dart';
import 'package:algo_erp_front/features/inventory_group/presentation/inventory_group_list_page.dart';
import 'package:algo_erp_front/features/inventory_item/presentation/inventory_item_form_page.dart';
import 'package:algo_erp_front/features/inventory_item/presentation/inventory_item_list_page.dart';
import 'package:algo_erp_front/features/inventory_item_property/presentation/item_property_form_page.dart';
import 'package:algo_erp_front/features/inventory_item_property/presentation/item_property_list_page.dart';
import 'package:algo_erp_front/features/inventory_pricelist/presentation/price_list_form_page.dart';
import 'package:algo_erp_front/features/inventory_pricelist/presentation/price_list_list_page.dart';
import 'package:algo_erp_front/features/inventory_route/presentation/route_master_form_page.dart';
import 'package:algo_erp_front/features/inventory_route/presentation/route_master_list_page.dart';
import 'package:algo_erp_front/features/inventory_sku/presentation/sku_master_form_page.dart';
import 'package:algo_erp_front/features/inventory_sku/presentation/sku_master_list_page.dart';
import 'package:algo_erp_front/features/inventory_tax_category/presentation/tax_category_form_page.dart';
import 'package:algo_erp_front/features/inventory_tax_category/presentation/tax_category_list_page.dart';
import 'package:algo_erp_front/features/inventory_uom/presentation/uom_form_page.dart';
import 'package:algo_erp_front/features/inventory_uom/presentation/uom_list_page.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/presentation/uom_conversion_form_page.dart';
import 'package:algo_erp_front/features/inventory_uom_conversion/presentation/uom_conversion_list_page.dart';
import 'package:algo_erp_front/features/organization_address_book/presentation/address_book_form_page.dart';
import 'package:algo_erp_front/features/organization_address_book/presentation/address_book_list_page.dart';
import 'package:algo_erp_front/features/organization_audit/presentation/audit_log_list_page.dart';
import 'package:algo_erp_front/features/organization_branch/presentation/branch_form_page.dart';
import 'package:algo_erp_front/features/organization_branch/presentation/branch_list_page.dart';
import 'package:algo_erp_front/features/organization_company/presentation/company_profile_form_page.dart';
import 'package:algo_erp_front/features/organization_company/presentation/company_profile_list_page.dart';
import 'package:algo_erp_front/features/organization_config/presentation/config_setting_form_page.dart';
import 'package:algo_erp_front/features/organization_config/presentation/config_setting_list_page.dart';
import 'package:algo_erp_front/features/organization_currency/presentation/currency_form_page.dart';
import 'package:algo_erp_front/features/organization_currency/presentation/currency_list_page.dart';
import 'package:algo_erp_front/features/organization_currency_rate/presentation/currency_rate_form_page.dart';
import 'package:algo_erp_front/features/organization_currency_rate/presentation/currency_rate_list_page.dart';
import 'package:algo_erp_front/features/organization_error_report/presentation/error_report_form_page.dart';
import 'package:algo_erp_front/features/organization_error_report/presentation/error_report_list_page.dart';
import 'package:algo_erp_front/features/organization_financial_year/presentation/financial_year_form_page.dart';
import 'package:algo_erp_front/features/organization_financial_year/presentation/financial_year_list_page.dart';
import 'package:algo_erp_front/features/organization_project/presentation/project_master_form_page.dart';
import 'package:algo_erp_front/features/organization_project/presentation/project_master_list_page.dart';
import 'package:algo_erp_front/features/organization_user/presentation/user_credentials_form_page.dart';
import 'package:algo_erp_front/features/organization_user/presentation/user_credentials_list_page.dart';
import 'package:algo_erp_front/features/organization_user_role/presentation/role_permissions_page.dart';
import 'package:algo_erp_front/features/organization_user_role/presentation/user_role_form_page.dart';
import 'package:algo_erp_front/features/organization_user_role/presentation/user_role_list_page.dart';
import 'package:algo_erp_front/features/organization_voucher_series/presentation/voucher_series_form_page.dart';
import 'package:algo_erp_front/features/organization_voucher_series/presentation/voucher_series_list_page.dart';
import 'package:algo_erp_front/features/reports/presentation/report_page.dart';
import 'package:algo_erp_front/features/reports/presentation/reports_hub_page.dart';
import 'package:algo_erp_front/features/settings/presentation/settings_page.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/presentation/debit_credit_detail_page.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/presentation/debit_credit_form_page.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/presentation/debit_credit_list_page.dart';
import 'package:algo_erp_front/features/transactions_item_qty/presentation/item_qty_detail_page.dart';
import 'package:algo_erp_front/features/transactions_item_qty/presentation/item_qty_form_page.dart';
import 'package:algo_erp_front/features/transactions_item_qty/presentation/item_qty_list_page.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/presentation/ledger_amount_detail_page.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/presentation/ledger_amount_form_page.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/presentation/ledger_amount_list_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_detail_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_form_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_list_page.dart';
import 'package:algo_erp_front/features/transactions_stock/presentation/stock_voucher_detail_page.dart';
import 'package:algo_erp_front/features/transactions_stock/presentation/stock_voucher_form_page.dart';
import 'package:algo_erp_front/features/transactions_stock/presentation/stock_voucher_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Auth/RBAC redirect guard. Reads [AuthBloc] from the widget tree (provided
/// above `MaterialApp.router`) and steers navigation:
/// - while the boot check is in flight ([AuthInitial]/[AuthLoading]) it returns
///   null so we don't flash `/login` before `/auth/me` resolves;
/// - unauthenticated users are sent to `/login` (and kept there);
/// - authenticated users sitting on `/login` are bounced to `/dashboard`.
///
/// `/403` is a *destination* the app pushes when an API call returns a
/// `ForbiddenFailure` — it is never synthesized here (403s arise from data
/// calls, not from navigation).
String? appRouterRedirect(BuildContext context, GoRouterState state) {
  final authState = context.read<AuthBloc>().state;
  final atLogin = state.matchedLocation == '/login';

  if (authState is AuthInitial || authState is AuthLoading) return null;

  final isAuthed = authState is AuthAuthenticated;
  if (!isAuthed) return atLogin ? null : '/login';
  if (atLogin) return '/dashboard';
  return null;
}

/// Wraps a destination widget in a Material fade-through transition using
/// the shared [MotionTokens], so every route — hub switches, list<->form,
/// login/403 — animates consistently: the outgoing page fades out over the
/// first third of the duration, the incoming page fades and scales in over
/// the remaining two thirds. Hand-rolled rather than pulling in
/// `package:animations` for one transition.
CustomTransitionPage<void> buildPageWithMotion({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.pageTransition,
    reverseTransitionDuration: MotionTokens.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.3, curve: Curves.easeInCubic),
      );
      final incoming = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(fadeOut),
        child: FadeTransition(
          opacity: incoming,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(incoming),
            child: child,
          ),
        ),
      );
    },
  );
}

/// New + detail routes for a Sprint D item-qty voucher kind.
List<RouteBase> _itemQtyRoutes(ItemQtyVoucherKind kind) {
  final base = kind.blueprint.listPath;
  return [
    GoRoute(
      path: '$base/new',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: ItemQtyFormPage(kind: kind),
      ),
    ),
    GoRoute(
      path: '$base/:id',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: ItemQtyDetailPage(
          kind: kind,
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),
  ];
}

/// New + detail routes for Payment / Receipt.
List<RouteBase> _ledgerAmountRoutes(LedgerAmountVoucherKind kind) {
  final base = kind.blueprint.listPath;
  return [
    GoRoute(
      path: '$base/new',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: LedgerAmountFormPage(kind: kind),
      ),
    ),
    GoRoute(
      path: '$base/:id',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: LedgerAmountDetailPage(
          kind: kind,
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),
  ];
}

/// New + detail routes for Journal / Contra.
List<RouteBase> _debitCreditRoutes(DebitCreditVoucherKind kind) {
  final base = kind.blueprint.listPath;
  return [
    GoRoute(
      path: '$base/new',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: DebitCreditFormPage(kind: kind),
      ),
    ),
    GoRoute(
      path: '$base/:id',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: DebitCreditDetailPage(
          kind: kind,
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),
  ];
}

/// New + detail routes for stock vouchers.
List<RouteBase> _stockVoucherRoutes(StockVoucherKind kind) {
  final base = kind.blueprint.listPath;
  return [
    GoRoute(
      path: '$base/new',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: StockVoucherFormPage(kind: kind),
      ),
    ),
    GoRoute(
      path: '$base/:id',
      pageBuilder: (context, state) => buildPageWithMotion(
        state: state,
        child: StockVoucherDetailPage(
          kind: kind,
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),
  ];
}

/// Builds the app router bound to a single [AuthBloc] instance. The same
/// instance is provided above `MaterialApp.router` in `app.dart`, so the
/// redirect guard and the UI observe identical auth state, and
/// [GoRouterRefreshStream] re-runs the guard on every auth transition.
GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  initialLocation: '/dashboard',
  redirect: appRouterRedirect,
  refreshListenable: GoRouterRefreshStream(authBloc.stream),
  routes: [
    // Chrome-less routes: no nav rail/drawer.
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          buildPageWithMotion(state: state, child: const LoginPage()),
    ),
    GoRoute(
      path: '/403',
      pageBuilder: (context, state) =>
          buildPageWithMotion(state: state, child: const _ForbiddenPage()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Binder hubs + hub-tile masters (masters are not in the rail).
        for (final item in AppMenu.allShellListItems)
          GoRoute(
            path: item.route,
            pageBuilder: (context, state) => buildPageWithMotion(
              state: state,
              child: shellListPageFor(item.route, fallbackTitle: item.label),
            ),
          ),
        // Report viewer (hub is AppMenu `/reports`).
        GoRoute(
          path: '/reports/:reportId',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ReportPage(reportId: state.pathParameters['reportId']!),
          ),
        ),
        // Manifest create/edit routes — not menu items, so registered
        // directly rather than through the AppMenu shell list loop above.
        GoRoute(
          path: '/transactions/sales-invoices/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const SalesInvoiceFormPage(),
          ),
        ),
        GoRoute(
          path: '/transactions/sales-invoices/:id/edit',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: SalesInvoiceFormPage(
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/transactions/sales-invoices/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: SalesInvoiceDetailPage(
              id: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        ..._itemQtyRoutes(ItemQtyKinds.quotation),
        ..._itemQtyRoutes(ItemQtyKinds.salesOrder),
        ..._itemQtyRoutes(ItemQtyKinds.deliveryNote),
        ..._itemQtyRoutes(ItemQtyKinds.purchaseOrder),
        ..._itemQtyRoutes(ItemQtyKinds.receiptNote),
        ..._itemQtyRoutes(ItemQtyKinds.purchaseInvoice),
        ..._itemQtyRoutes(ItemQtyKinds.creditNote),
        ..._itemQtyRoutes(ItemQtyKinds.debitNote),
        ..._ledgerAmountRoutes(LedgerAmountKinds.payment),
        ..._ledgerAmountRoutes(LedgerAmountKinds.receipt),
        ..._debitCreditRoutes(DebitCreditKinds.journal),
        ..._debitCreditRoutes(DebitCreditKinds.contra),
        ..._stockVoucherRoutes(StockVoucherKinds.godownTransfer),
        ..._stockVoucherRoutes(StockVoucherKinds.materialIn),
        ..._stockVoucherRoutes(StockVoucherKinds.requirement),
        ..._stockVoucherRoutes(StockVoucherKinds.stockRequest),
        GoRoute(
          path: '/accounts/groups/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const AccountGroupFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/accounts/groups/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: AccountGroupFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/accounts/ledgers/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const LedgerFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/accounts/ledgers/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: LedgerFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/item/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const InventoryItemFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/item/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: InventoryItemFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/group/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const InventoryGroupFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/group/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: InventoryGroupFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/sku/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const SkuMasterFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/sku/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: SkuMasterFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/batch/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ItemBatchFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/batch/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ItemBatchFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/brand/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const BrandFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/brand/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: BrandFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/uom/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const UomFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/uom/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: UomFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/category/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const CategoryFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/category/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: CategoryFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/tax-category/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const TaxCategoryFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/tax-category/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: TaxCategoryFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/godown/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const GodownFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/godown/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: GodownFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/route/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const RouteMasterFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/route/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: RouteMasterFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/conversion/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const UomConversionFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/conversion/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: UomConversionFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/pricelist/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const PriceListFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/pricelist/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: PriceListFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/branches/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const BranchFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/branches/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: BranchFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/currencies/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const CurrencyFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/currencies/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: CurrencyFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/roles/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const UserRoleFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/roles/:id/permissions',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: RolePermissionsPage(
              roleId: int.parse(state.pathParameters['id']!),
              roleName: state.uri.queryParameters['name'],
            ),
          ),
        ),
        GoRoute(
          path: '/organization/roles/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: UserRoleFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/companies/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: CompanyProfileFormPage(
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/users/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const UserCredentialsFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/users/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: UserCredentialsFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/contacts/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const AddressBookFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/contacts/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: AddressBookFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/fy/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const FinancialYearFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/fy/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: FinancialYearFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/voucher-series/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const VoucherSeriesFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/voucher-series/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: VoucherSeriesFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/projects/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ProjectMasterFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/projects/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ProjectMasterFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/rates/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const CurrencyRateFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/organization/rates/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: CurrencyRateFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/config/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ConfigSettingFormPage(
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/organization/error-reports/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ErrorReportFormPage(),
          ),
        ),
        GoRoute(
          path: '/inventory/property/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ItemPropertyFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/property/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ItemPropertyFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/inventory/attribute/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ProductAttributeFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/inventory/attribute/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ProductAttributeFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/department/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const DepartmentFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/department/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: DepartmentFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/designation/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const DesignationFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/designation/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: DesignationFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/employees/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const EmployeeFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/employees/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: EmployeeFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/leave/policies/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const LeavePolicyFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/leave/policies/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: LeavePolicyFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/leave/allocations/new',
          pageBuilder: (context, state) {
            final extra = state.extra;
            int? employeeId;
            int? year;
            if (extra is Map) {
              final rawEmp = extra['employeeId'];
              final rawYear = extra['year'];
              if (rawEmp is int) employeeId = rawEmp;
              if (rawYear is int) year = rawYear;
            }
            return buildPageWithMotion(
              state: state,
              child: LeaveAllocationFormPage(
                initialEmployeeId: employeeId,
                initialYear: year,
              ),
            );
          },
        ),
        GoRoute(
          path: '/employee/leave-requests/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const LeaveRequestFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/leave-requests/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: LeaveRequestFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/employee/shifts/new',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: const ShiftMasterFormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path: '/employee/shifts/:id',
          pageBuilder: (context, state) => buildPageWithMotion(
            state: state,
            child: ShiftMasterFormPage(
              mode: FormMode.edit,
              entityId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('No route for ${state.uri}'))),
);

/// Adapts a [Stream] into a [Listenable] for `GoRouter.refreshListenable`.
/// go_router does not export its own, so we keep the standard adapter here.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _ForbiddenPage extends StatelessWidget {
  const _ForbiddenPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Access denied', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              "You don't have permission to view this page.",
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Back to desk'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves binder hubs and hub-master list pages for AppMenu shell list items.
Widget shellListPageFor(String route, {required String fallbackTitle}) {
  // Every business hub renders from its manifest — Sales, Purchase, Inventory,
  // Finance, People, Organization (via Settings), and the All-documents index.
  if (AppMenu.hubs[route] case final hub?) return ModuleHubPage(hub: hub);

  return switch (route) {
    '/dashboard' => const TodaysDeskPage(),
    '/reports' => const ReportsHubPage(),
    '/settings' => const SettingsPage(),
    '/theme-preview' => const ThemePreviewPage(),
    '/widget-gallery' => const WidgetGalleryPage(),
    // Organization masters
    '/organization/companies' => const CompanyProfileListPage(),
    '/organization/branches' => const BranchListPage(),
    '/organization/currencies' => const CurrencyListPage(),
    '/organization/roles' => const UserRoleListPage(),
    '/organization/users' => const UserCredentialsListPage(),
    '/organization/contacts' => const AddressBookListPage(),
    '/organization/fy' => const FinancialYearListPage(),
    '/organization/voucher-series' => const VoucherSeriesListPage(),
    '/organization/projects' => const ProjectMasterListPage(),
    '/organization/rates/history' => const CurrencyRateListPage(),
    '/organization/config' => const ConfigSettingListPage(),
    '/organization/audit-logs' => const AuditLogListPage(),
    '/organization/error-reports' => const ErrorReportListPage(),
    // Accounts
    '/accounts/groups' => const AccountGroupListPage(),
    '/accounts/ledgers' => const LedgerListPage(),
    // Inventory
    '/inventory/item' => const InventoryItemListPage(),
    '/inventory/group' => const InventoryGroupListPage(),
    '/inventory/sku' => const SkuMasterListPage(),
    '/inventory/batch' => const ItemBatchListPage(),
    '/inventory/brand' => const BrandListPage(),
    '/inventory/uom' => const UomListPage(),
    '/inventory/category' => const CategoryListPage(),
    '/inventory/tax-category' => const TaxCategoryListPage(),
    '/inventory/godown' => const GodownListPage(),
    '/inventory/route' => const RouteMasterListPage(),
    '/inventory/conversion' => const UomConversionListPage(),
    '/inventory/pricelist' => const PriceListListPage(),
    '/inventory/property' => const ItemPropertyListPage(),
    '/inventory/attribute' => const ProductAttributeListPage(),
    // Employee
    '/employee/employees' => const EmployeeListPage(),
    '/employee/department' => const DepartmentListPage(),
    '/employee/designation' => const DesignationListPage(),
    '/employee/leave/policies' => const LeavePolicyListPage(),
    '/employee/leave/allocations' => const LeaveAllocationListPage(),
    '/employee/leave-requests' => const LeaveRequestListPage(),
    '/employee/shifts' => const ShiftMasterListPage(),
    // Transactions
    '/transactions/sales-invoices' => const SalesInvoiceListPage(),
    '/transactions/quotations' => const ItemQtyListPage(
      kind: ItemQtyKinds.quotation,
    ),
    '/transactions/sales-orders' => const ItemQtyListPage(
      kind: ItemQtyKinds.salesOrder,
    ),
    '/transactions/delivery-notes' => const ItemQtyListPage(
      kind: ItemQtyKinds.deliveryNote,
    ),
    '/transactions/purchase-orders' => const ItemQtyListPage(
      kind: ItemQtyKinds.purchaseOrder,
    ),
    '/transactions/receipt-notes' => const ItemQtyListPage(
      kind: ItemQtyKinds.receiptNote,
    ),
    '/transactions/purchase-invoices' => const ItemQtyListPage(
      kind: ItemQtyKinds.purchaseInvoice,
    ),
    '/transactions/payments' => const LedgerAmountListPage(
      kind: LedgerAmountKinds.payment,
    ),
    '/transactions/receipts' => const LedgerAmountListPage(
      kind: LedgerAmountKinds.receipt,
    ),
    '/transactions/credit-notes' => const ItemQtyListPage(
      kind: ItemQtyKinds.creditNote,
    ),
    '/transactions/debit-notes' => const ItemQtyListPage(
      kind: ItemQtyKinds.debitNote,
    ),
    '/transactions/journals' => const DebitCreditListPage(
      kind: DebitCreditKinds.journal,
    ),
    '/transactions/contra' => const DebitCreditListPage(
      kind: DebitCreditKinds.contra,
    ),
    '/transactions/godown-transfers' => const StockVoucherListPage(
      kind: StockVoucherKinds.godownTransfer,
    ),
    '/transactions/material-in' => const StockVoucherListPage(
      kind: StockVoucherKinds.materialIn,
    ),
    '/transactions/requirements' => const StockVoucherListPage(
      kind: StockVoucherKinds.requirement,
    ),
    '/transactions/stock-requests' => const StockVoucherListPage(
      kind: StockVoucherKinds.stockRequest,
    ),
    _ => _PlaceholderPage(title: fallbackTitle),
  };
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Feature not yet built — placeholder route from Step 3.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
