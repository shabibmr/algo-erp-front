import 'package:algo_erp_front/core/error/failure.dart';

/// The four visual states any async-loaded view can be in, decoupled from
/// *how* the data was fetched.
///
/// `AsyncStateView<T>` (Track C) switches over this sealed type to render a
/// skeleton, a branded empty state, the data, or a friendly error+retry. It is
/// deliberately **independent of bloc/CrudState** so it works everywhere:
/// list screens, detail screens, dropdowns, dashboards — anything with a
/// loading/empty/data/error lifecycle. Adapters (e.g. `CrudState → ViewState`)
/// live next to their source, not here.
sealed class ViewState<T> {
  const ViewState();
}

/// Data is being fetched and there is nothing to show yet → skeleton loader.
class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

/// The fetch succeeded but produced no data → branded empty state + CTA.
class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

/// The fetch succeeded with data to render.
class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);

  final T data;
}

/// The fetch failed → friendly error message + retry, mapped from [failure].
class ViewError<T> extends ViewState<T> {
  const ViewError(this.failure);

  final Failure failure;
}
