import 'package:flutter/material.dart';
import 'package:wallet_connect/wallet_connect.dart';

class SessionRequestView extends StatefulWidget {
  final WCPeerMeta peerMeta;
  final void Function(int) onApprove;
  final void Function() onReject;

  const SessionRequestView({
    Key? key,
    required this.peerMeta,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  State<SessionRequestView> createState() => _SessionRequestViewState();
}

class _SessionRequestViewState extends State<SessionRequestView> {
  String chainId = '';

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Column(
        children: [
          if (widget.peerMeta.icons.isNotEmpty)
            Container(
              height: 100.0,
              width: 100.0,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.network(widget.peerMeta.icons.first),
            ),
          Text(widget.peerMeta.name),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      children: [
        if (widget.peerMeta.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.peerMeta.description),
          ),
        if (widget.peerMeta.url.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
            child: Center(
              child: Text(
                '${widget.peerMeta.url}',
                style: TextStyle(color: Colors.black45),
              ),
            ),
          ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  widget.onApprove(int.tryParse(chainId) != null ? int.parse(chainId) : 1);
                },
                child: Text('APPROVE'),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: widget.onReject,
                child: Text('REJECT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
