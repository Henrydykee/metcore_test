import 'dart:async';

/// An abstract base class for local data sources that emit data updates using streams.
///
/// [T] is the type of data being managed (e.g., User, List<User>, Settings, etc.).
abstract class LocalDataSource<T> {

  /// StreamController used to broadcast data updates to listeners (e.g., UI widgets).
  final StreamController<T> dataStreamController = StreamController<T>();

  /// Disposes of the stream controller to free up resources.
  /// This must be implemented by subclasses to prevent memory leaks.
  void dispose();
}
