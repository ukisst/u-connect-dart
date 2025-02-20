import 'package:json_annotation/json_annotation.dart';

enum WCMethod {
  @JsonValue("uc_sessionRequest")
  SESSION_REQUEST,

  @JsonValue("uc_sessionUpdate")
  SESSION_UPDATE,

  @JsonValue("wallet_switchEthereumChain")
  WALLET_SWITCH_NETWORK,

  @JsonValue("eth_sign")
  ETH_SIGN,

  @JsonValue("personal_sign")
  ETH_PERSONAL_SIGN,

  @JsonValue("eth_signTypedData")
  ETH_SIGN_TYPE_DATA,

  @JsonValue("eth_signTransaction")
  ETH_SIGN_TRANSACTION,

  @JsonValue("eth_sendTransaction")
  ETH_SEND_TRANSACTION,

  @JsonValue("btc_sign")
  BTC_SIGN,

  @JsonValue("btc_signTransaction")
  BTC_SIGN_TRANSACTION,

  @JsonValue("btc_sendTransaction")
  BTC_SEND_TRANSACTION,
}
