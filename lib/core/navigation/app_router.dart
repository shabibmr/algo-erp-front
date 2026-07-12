import 'dart:async';

import 'package:algo_erp_front/core/navigation/app_shell.dart';
import 'package:algo_erp_front/core/navigation/menu_model.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/theme/theme_preview_page.dart';
import 'package:algo_erp_front/core/widgets/gallery/widget_gallery_page.dart';
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
import 'package:algo_erp_front/features/inventory_batch/presentation/item_batch_form_page.dart';
import 'package:algo_erp_front/features/inventory_batch/presentation/item_batch_list_page.dart';
import 'package:algo_erp_front/features/inventory_brand/presentation/brand_form_page.dart';
import 'package:algo_erp_front/features/inventory_brand/presentation/brand_list_page.dart';
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
import 'package:algo_erp_front/features/organization_branch/presentation/branch_form_page.dart';
import 'package:algo_erp_front/features/organization_branch/presentation/branch_list_page.dart';
import 'package:algo_erp_front/features/organization_currency/presentation/currency_form_page.dart';
import 'package:algo_erp_front/features/organization_currency/presentation/currency_list_page.dart';
import 'package:algo_erp_front/features/organization_financial_year/presentation/financial_year_form_page.dart';
import 'package:algo_erp_front/features/organization_financial_year/presentation/financial_year_list_page.dart';
import 'package:algo_erp_front/features/organization_user_role/presentation/user_role_form_page.dart';
import 'package:algo_erp_front/features/organization_user_role/presentation/user_role_list_page.dart';
import 'package:algo_erp_front/features/organization_voucher_series/presentation/voucher_series_form_page.dart';
import 'package:algo_erp_front/features/organization_voucher_series/presentation/voucher_series_list_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_detail_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_form_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_html_pdf_page.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_list_page.dart';
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

/// Wraps a destination widget in a fade-through transition using the shared
/// [MotionTokens], so every route in the shell animates consistently.
CustomTransitionPage<void> buildPageWithMotion({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurveTween(curve: MotionTokens.standardCurve);
      return FadeTransition(
        opacity: curved.animate(animation),
        child: child,
      );
    },
  );
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
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/403', builder: (_, __) => const _ForbiddenPage()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            for (final item in AppMenu.allItems)
              GoRoute(
                path: item.route,
                pageBuilder: (context, state) => buildPageWithMotion(
                  state: state,
                  child: switch (item.route) {
                    '/dashboard' => const TodaysDeskPage(),
                    '/theme-preview' => const ThemePreviewPage(),
                    '/widget-gallery' => const WidgetGalleryPage(),
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
                    '/inventory/conversion' =>
                      const UomConversionListPage(),
                    '/inventory/pricelist' => const PriceListListPage(),
                    '/employee/department' => const DepartmentListPage(),
                    '/employee/designation' => const DesignationListPage(),
                    '/organization/branches' => const BranchListPage(),
                    '/organization/currencies' => const CurrencyListPage(),
                    '/organization/roles' => const UserRoleListPage(),
                    '/organization/contacts' => const AddressBookListPage(),
                    '/organization/fy' => const FinancialYearListPage(),
                    '/organization/voucher-series' =>
                      const VoucherSeriesListPage(),
                    '/inventory/property' => const ItemPropertyListPage(),
                    '/accounts/groups' => const AccountGroupListPage(),
                    '/accounts/ledgers' => const LedgerListPage(),
                    '/transactions/sales-invoices' =>
                      const SalesInvoiceListPage(),
                    _ => _PlaceholderPage(title: item.label),
                  },
                ),
              ),
            // Manifest create/edit routes — not menu items, so registered
            // directly rather than through the AppMenu.allItems loop above.
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
              path: '/transactions/sales-invoices/:id/pdf',
              pageBuilder: (context, state) => buildPageWithMotion(
                state: state,
                child: SalesInvoiceHtmlPdfPage(
                  id: int.parse(state.pathParameters['id']!),
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
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('No route for ${state.uri}')),
      ),
    );

/// Adapts a [Stream] into a [Listenable] for `GoRouter.refreshListenable`.
/// go_router does not export its own, so we keep the standard adapter here.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
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
