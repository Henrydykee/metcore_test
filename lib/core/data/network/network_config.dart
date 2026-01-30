class NetworkConfig {
  Map<String, String>? headers;
}

class NetworkConfigImpl implements NetworkConfig {
  @override
  Map<String, String>? headers;

  NetworkConfigImpl({this.headers});
}
