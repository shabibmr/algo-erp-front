import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_bloc.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_form_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesInvoiceRepository extends Mock
    implements SalesInvoiceRepository {}

class _MockLedgerRepository extends Mock implements Repository<Ledger, int> {}

class _MockGodownRepository extends Mock implements Repository<Godown, int> {}

class _MockItemRepository extends Mock
    implements Repository<InventoryItem, int> {}

final _customer = Ledger(
  id: 7,
  name: 'Acme Trading',
  openingBalance: Decimal.zero,
);
final _godown = Godown(id: 3, name: 'Main store');

SalesInvoiceLine _completeLine() => ItemQtyLine(
  itemId: 11,
  itemLabel: 'Widget',
  quantity: Decimal.one,
  price: Decimal.parse('10'),
);

final _postResult = ItemQtyPostResult(
  id: 99,
  voucherNo: 'SI-0001',
  total: Decimal.zero,
  subtotal: Decimal.zero,
  discount: Decimal.zero,
  vat: Decimal.zero,
);

void main() {
  late _MockSalesInvoiceRepository repository;
  late _MockLedgerRepository ledgerRepository;
  late _MockGodownRepository godownRepository;
  late _MockItemRepository itemRepository;

  setUpAll(() {
    registerFallbackValue(ItemQtyDraft());
  });

  setUp(() {
    repository = _MockSalesInvoiceRepository();
    ledgerRepository = _MockLedgerRepository();
    godownRepository = _MockGodownRepository();
    itemRepository = _MockItemRepository();
  });

  SalesInvoiceFormBloc build() => SalesInvoiceFormBloc(
    repository: repository,
    ledgerRepository: ledgerRepository,
    godownRepository: godownRepository,
    itemRepository: itemRepository,
  );

  /// Fills in the minimum a draft needs to pass validation.
  void seedValidDraft(SalesInvoiceFormBloc bloc) {
    bloc
      ..add(const FormInitialized())
      ..add(CustomerSelected(_customer))
      ..add(GodownSelected(_godown))
      ..add(LineItemUpdated(index: 0, line: _completeLine()));
  }

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'deselecting the customer clears it — `?? this.customer` never could',
    build: build,
    act: (bloc) => bloc
      ..add(CustomerSelected(_customer))
      ..add(const CustomerSelected(null)),
    verify: (bloc) {
      expect(bloc.state.customer, isNull);
      expect(bloc.state.draft.partyLedgerId, isNull);
    },
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'a second Post while one is in flight is dropped, not queued',
    setUp: () {
      when(() => repository.post(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Right(_postResult);
      });
    },
    build: build,
    act: (bloc) {
      seedValidDraft(bloc);
      bloc
        ..add(const FormSubmitted(saveStatus: 'Posted'))
        ..add(const FormSubmitted(saveStatus: 'Posted'));
    },
    wait: const Duration(milliseconds: 150),
    verify: (bloc) {
      verify(() => repository.post(any())).called(1);
      expect(bloc.state.status, FormSubmissionStatus.success);
      expect(bloc.state.postedInvoiceId, 99);
    },
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'submitting an invalid draft reports the error and posts nothing',
    build: build,
    act: (bloc) => bloc
      ..add(const FormInitialized())
      ..add(const FormSubmitted(saveStatus: 'Posted')),
    verify: (bloc) {
      verifyNever(() => repository.post(any()));
      expect(bloc.state.errorMessage, 'Customer is required');
    },
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'editing a non-Draft invoice fails instead of opening an editable form',
    setUp: () {
      when(
        () => repository.getById(
          any(),
          resolveItemLabel: any(named: 'resolveItemLabel'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(ItemQtyDetail(id: 5, status: 'Posted', lines: const [])),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const FormInitialized(entityId: 5)),
    verify: (bloc) {
      expect(bloc.state.status, FormSubmissionStatus.failure);
      expect(bloc.state.isFailure, isTrue);
      expect(bloc.state.errorMessage, contains('Only Draft invoices'));
    },
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'a failed load surfaces the failure message',
    setUp: () {
      when(
        () => repository.getById(
          any(),
          resolveItemLabel: any(named: 'resolveItemLabel'),
        ),
      ).thenAnswer((_) async => const Left(Failure.network('No connection')));
    },
    build: build,
    act: (bloc) => bloc.add(const FormInitialized(entityId: 5)),
    verify: (bloc) {
      expect(bloc.state.status, FormSubmissionStatus.failure);
      expect(bloc.state.errorMessage, 'No connection');
    },
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'a freshly-initialized form is not dirty (nothing to lose on back)',
    build: build,
    act: (bloc) => bloc.add(const FormInitialized()),
    verify: (bloc) => expect(bloc.state.isDirty, isFalse),
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'changing any field marks the form dirty (guards against data loss)',
    build: build,
    act: (bloc) => bloc
      ..add(const FormInitialized())
      ..add(CustomerSelected(_customer)),
    verify: (bloc) => expect(bloc.state.isDirty, isTrue),
  );

  blocTest<SalesInvoiceFormBloc, SalesInvoiceFormState>(
    'a successful post clears dirty so navigating away never prompts',
    setUp: () {
      when(
        () => repository.post(any()),
      ).thenAnswer((_) async => Right(_postResult));
    },
    build: build,
    act: (bloc) {
      seedValidDraft(bloc);
      bloc.add(const FormSubmitted(saveStatus: 'Posted'));
    },
    verify: (bloc) {
      expect(bloc.state.status, FormSubmissionStatus.success);
      expect(bloc.state.isDirty, isFalse);
    },
  );
}
