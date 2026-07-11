import 'package:algo_erp_front/core/data/remote_data_source_base.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';

/// Collapses the "`RemoteDataSourceBase` + resource path + decode/encode/idOf
/// closures → `RemoteRepository`" boilerplate every `*_di.dart` file
/// otherwise repeats verbatim.
///
/// Deliberately small — a function, not a registry or `@injectable` binding.
/// Was withheld in the EMR vertical slice ("until more than one entity needs
/// the same wiring" — see the original `brand_di.dart`); with three manifests
/// now sharing this exact shape (and Designation needing a *second*
/// repository instance for its FK field), that threshold is met.
RemoteRepository<E, ID> buildRepository<E, ID>({
  required DioClient client,
  required String resourcePath,
  required E Function(Map<String, dynamic> json) decode,
  required Map<String, dynamic> Function(E entity) encode,
  required ID Function(E entity) idOf,
}) {
  return RemoteRepository<E, ID>(
    dataSource: RemoteDataSourceBase(client, resourcePath),
    decode: decode,
    encode: encode,
    idOf: idOf,
  );
}
