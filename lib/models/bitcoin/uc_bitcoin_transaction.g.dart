// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uc_bitcoin_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UCBitcoinTransaction _$UCBitcoinTransactionFromJson(Map<String, dynamic> json) => UCBitcoinTransaction(
      from: json['from'] as String,
      to: json['to'] as String?,
      nonce: json['nonce'] as String?,
      gasPrice: json['gasPrice'] as String?,
      maxFeePerGas: json['maxFeePerGas'] as String?,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String?,
      gas: json['gas'] as String?,
      gasLimit: json['gasLimit'] as String?,
      value: json['value'] as String?,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$UCBitcoinTransactionToJson(UCBitcoinTransaction instance) => <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'nonce': instance.nonce,
      'gasPrice': instance.gasPrice,
      'maxFeePerGas': instance.maxFeePerGas,
      'maxPriorityFeePerGas': instance.maxPriorityFeePerGas,
      'gas': instance.gas,
      'gasLimit': instance.gasLimit,
      'value': instance.value,
      'data': instance.data,
    };
