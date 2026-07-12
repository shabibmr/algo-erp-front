import 'package:algo_erp_front/features/employee_employee/data/employee_dto.dart';
import 'package:algo_erp_front/features/employee_employee/data/employee_mapper.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = EmployeeMapper();

  test('EmployeeDto.fromJson reads core fields and nested bank/salary', () {
    final dto = EmployeeDto.fromJson({
      'id': 7,
      'Name': 'Aisha Khan',
      'employee_code': 'E-007',
      'department_id': 2,
      'designation_id': 3,
      'is_active': true,
      'bank_details': {
        'bank_name': 'FAB',
        'account_number': '123',
        'iban': 'AE00',
      },
      'employee_salary_details': [
        {
          'Basic_Salary': 5000,
          'HRA': 1000,
          'salary_ledger_id': 10,
        },
      ],
    });

    expect(dto.id, 7);
    expect(dto.name, 'Aisha Khan');
    expect(dto.employeeCode, 'E-007');
    expect(dto.departmentId, 2);
    expect(dto.bankDetails?.bankName, 'FAB');
    expect(dto.salaryDetails?.basicSalary, '5000');
    expect(dto.salaryDetails?.salaryLedgerId, 10);
  });

  test('toEntity maps money to Decimal; toJson nests bankDetails/salaryDetails', () {
    final entity = mapper.toEntity(
      EmployeeDto.fromJson({
        'id': 1,
        'Name': 'Test',
        'bank_details': {
          'bank_name': 'ENBD',
          'account_number': '99',
        },
        'salaryDetails': {
          'Basic_Salary': '2500.50',
          'DA': 0,
        },
      }),
    );

    expect(entity.name, 'Test');
    expect(entity.bank.bankName, 'ENBD');
    expect(entity.salary.basicSalary, Decimal.parse('2500.50'));

    final json = mapper.toDto(entity).toJson();
    expect(json['Name'], 'Test');
    expect(json['bankDetails'], isA<Map<String, dynamic>>());
    expect(json['salaryDetails'], isA<Map<String, dynamic>>());
    expect((json['bankDetails'] as Map)['account_number'], '99');
  });

  test('toJson omits empty bank/salary when shouldWrite is false', () {
    const employee = Employee(id: 1, name: 'Bare');
    final json = mapper.toDto(employee).toJson();
    expect(json.containsKey('bankDetails'), isFalse);
    expect(json.containsKey('salaryDetails'), isFalse);
  });

  test('round-trip identity for core fields', () {
    final original = Employee(
      id: 4,
      name: 'Sam',
      code: 'S-1',
      gender: 'Male',
      departmentId: 1,
      bank: const EmployeeBankDetails(
        bankName: 'X',
        accountNumber: '1',
      ),
      salary: EmployeeSalaryDetails(
        basicSalary: Decimal.fromInt(1000),
        workingHours: 8,
      ),
    );
    final again = mapper.toEntity(mapper.toDto(original));
    expect(again.name, original.name);
    expect(again.code, original.code);
    expect(again.bank.accountNumber, '1');
    expect(again.salary.basicSalary, Decimal.fromInt(1000));
  });
}
