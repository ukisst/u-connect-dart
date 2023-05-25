import 'package:json_annotation/json_annotation.dart';

part 'uc_bitcoin_transaction.g.dart';

@JsonSerializable()
class UCBitcoinTransaction {
  final String data;
  UCBitcoinTransaction({
    required this.data,
  });

  factory UCBitcoinTransaction.fromJson(String _data) => _$UCBitcoinTransactionFromJson(_data);
  String toJson() => _$UCBitcoinTransactionToJson(this);

  @override
  String toString() {
    return 'UCBitcoinTransaction(data: $data)';
  }
}
