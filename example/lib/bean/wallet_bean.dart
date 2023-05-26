class WalletBean {
  final String name;
  final String address;
  final String derivePath;
  final ChainType chainType;
  final int chainId;
  final String publicKey;

  WalletBean({
    required this.name,
    required this.address,
    required this.derivePath,
    required this.chainType,
    required this.chainId,
    required this.publicKey,
  });
}

enum ChainType {
  eth,
  eth_ropsten,
  btc,
  btc_testnet,
}
