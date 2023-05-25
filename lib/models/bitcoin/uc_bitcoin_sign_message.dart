class UCBitcoinSignMessage {
  final List<String> raw;
  UCBitcoinSignMessage({
    required this.raw,
  });

  String? get data {
    return raw[0];
  }

  String? get address {
    return raw[1];
  }
}
