import 'package:bloc/bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Default idle time before a search term is acted on.
const kSearchDebounce = Duration(milliseconds: 350);

/// An event transformer that **debounces then restarts**: it waits [duration]
/// of quiet before handling a search event (so a fast typist triggers one
/// request, not one per keystroke), and `switchMap` cancels an in-flight
/// search the moment a newer term arrives (so results never arrive out of
/// order). Register it on the search event:
/// ```dart
/// on<CrudSearchChanged<E, F>>(_onSearch,
///     transformer: debounceRestartable(kSearchDebounce));
/// ```
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}
