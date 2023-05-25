import 'package:json_annotation/json_annotation.dart';

part 'uc_bitcoin_transaction.g.dart';

@JsonSerializable()
class UCBitcoinTransaction {
  final String from;
  final String? to;
  final String? nonce;
  final String? gasPrice;
  final String? maxFeePerGas;
  final String? maxPriorityFeePerGas;
  final String? gas;
  final String? gasLimit;
  final String? value;
  final String? data;
  UCBitcoinTransaction({
    required this.from,
    this.to,
    this.nonce,
    this.gasPrice,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.gas,
    this.gasLimit,
    this.value,
    this.data,
  });

  factory UCBitcoinTransaction.fromJson(Map<String, dynamic> json) => _$UCBitcoinTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$UCBitcoinTransactionToJson(this);

  @override
  String toString() {
    return 'WCEthereumTransaction(from: $from, to: $to, nonce: $nonce, gasPrice: $gasPrice, gas: $gas, gasLimit: $gasLimit, value: $value, data: $data)';
  }
}
