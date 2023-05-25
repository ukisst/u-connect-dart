// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_rpc_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonRpcRequest _$JsonRpcRequestFromJson(Map<String, dynamic> json) => JsonRpcRequest(
      id: json['id'] as int,
      jsonrpc: json['jsonrpc'] as String? ?? JSONRPC_VERSION,
      method: $enumDecodeNullable(_$WCMethodEnumMap, json['method'], unknownValue: JsonKey.nullForUndefinedEnumValue),
      params: json['params'] as List<dynamic>?,
    );

Map<String, dynamic> _$JsonRpcRequestToJson(JsonRpcRequest instance) => <String, dynamic>{
      'id': instance.id,
      'jsonrpc': instance.jsonrpc,
      'method': _$WCMethodEnumMap[instance.method],
      'params': instance.params,
    };

const _$WCMethodEnumMap = {
  WCMethod.SESSION_REQUEST: 'uc_sessionRequest',
  WCMethod.SESSION_UPDATE: 'uc_sessionUpdate',
  WCMethod.WALLET_SWITCH_NETWORK: 'wallet_switchEthereumChain',
  //ethereum based method
  WCMethod.ETH_SIGN: 'eth_sign',
  WCMethod.ETH_PERSONAL_SIGN: 'personal_sign',
  WCMethod.ETH_SIGN_TYPE_DATA: 'eth_signTypedData',
  WCMethod.ETH_SIGN_TRANSACTION: 'eth_signTransaction',
  WCMethod.ETH_SEND_TRANSACTION: 'eth_sendTransaction',
  //bitcoin based method
  WCMethod.BTC_SIGN: 'btc_sign',
  WCMethod.BTC_SIGN_TRANSACTION: 'btc_signTransaction',
  WCMethod.BTC_SEND_TRANSACTION: 'btc_sendTransaction',
};
