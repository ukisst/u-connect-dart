import 'package:json_annotation/json_annotation.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

part 'wc_approve_session_response.g.dart';

@JsonSerializable()
class WCApproveSessionResponse {
  final bool approved;
  final int? chainId;
  final List<String> accounts;
  final List<String> publicKeys;
  final String peerId;
  final WCPeerMeta peerMeta;
  WCApproveSessionResponse({
    this.approved = true,
    this.chainId,
    required this.accounts,
    required this.publicKeys,
    required this.peerId,
    required this.peerMeta,
  });

  factory WCApproveSessionResponse.fromJson(Map<String, dynamic> json) => _$WCApproveSessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WCApproveSessionResponseToJson(this);

  @override
  String toString() {
    return 'WCApproveSessionResponse(approved: $approved, chainId: $chainId, account: $accounts,publicKeys: $publicKeys, peerId: $peerId, peerMeta: $peerMeta)';
  }
}
