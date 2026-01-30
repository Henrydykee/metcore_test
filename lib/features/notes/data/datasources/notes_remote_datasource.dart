import '../../../../core/data/datasources/remote_datasource_base.dart';
import '../../../../core/data/network/network_service.dart';
import '../../../../core/data/network/network_service_response.dart' show handleNetworkResponse;
import '../../../../core/utils/data/guarded_datasource_calls.dart';
import '../../../../core/utils/logger.dart';
import '../models/note_dto.dart';

class NotesRemoteDatasource implements RemoteDataSource {
  NotesRemoteDatasource(this._networkService);

  final NetworkService _networkService;
  static const String _endpoint = '/notes';


  Future<List<NoteDto>> getNotes() async {
    return guardedApiCall<List<NoteDto>>(() async {
      final response = await _networkService.get(_endpoint);
      final data = handleNetworkResponse(response);
      
      if (data is List) {
        return data.map((json) => NoteDto.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      logger.e('Unexpected response format: $data');
      throw Exception('Invalid response format');
    }, source: 'NotesRemoteDatasource.getNotes');
  }


  Future<NoteDto> getNoteById(String id) async {
    return guardedApiCall<NoteDto>(() async {
      final response = await _networkService.get('$_endpoint/$id');
      final data = handleNetworkResponse(response);
      
      if (data is Map<String, dynamic>) {
        return NoteDto.fromJson(data);
      }
      
      logger.e('Unexpected response format: $data');
      throw Exception('Invalid response format');
    }, source: 'NotesRemoteDatasource.getNoteById');
  }

  /// Create a new note on the server
  Future<NoteDto> createNote(NoteDto noteDto) async {
    return guardedApiCall<NoteDto>(() async {
      final response = await _networkService.post(
        _endpoint,
        body: noteDto.toCreateRequest(),
      );
      final data = handleNetworkResponse(response);
      
      if (data is Map<String, dynamic>) {
        return NoteDto.fromJson(data);
      }
      
      logger.e('Unexpected response format: $data');
      throw Exception('Invalid response format');
    }, source: 'NotesRemoteDatasource.createNote');
  }


  Future<NoteDto> updateNote(NoteDto noteDto) async {
    return guardedApiCall<NoteDto>(() async {
      final response = await _networkService.patch(
        '$_endpoint/${noteDto.id}',
        body: noteDto.toUpdateRequest(),
      );
      final data = handleNetworkResponse(response);
      
      if (data is Map<String, dynamic>) {
        return NoteDto.fromJson(data);
      }
      
      logger.e('Unexpected response format: $data');
      throw Exception('Invalid response format');
    }, source: 'NotesRemoteDatasource.updateNote');
  }

  /// Delete a note from the server
  Future<void> deleteNote(String id) async {
    return guardedApiCall<void>(() async {
      final response = await _networkService.delete('$_endpoint/$id');
      handleNetworkResponse(response);
    }, source: 'NotesRemoteDatasource.deleteNote');
  }

  @override
  void dispose() {
    // No resources to dispose
  }
}
