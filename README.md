<div align="center">
<img src="https://github.com/Orange-Wallet/orangewallet-utils/raw/master/assets/images/walletconnect.png" alt="Wallet Connect Logo" width="70"/>
<h1>U-Connect</h1>
</div>

## Usage

```dart
    import 'package:u_connect/u_connect.dart';
```

1.  Create instance of U-Connect client and define callbacks.

```dart
    final ucClient = ucClient(
      onConnect: () {
        // Respond to connect callback
      },
      onDisconnect: (code, reason) {
        // Respond to disconnect callback
      },
      onFailure: (error) {
        // Respond to connection failure callback
      },
      onSessionRequest: (id, peerMeta) {
        // Respond to connection request callback
      },
      onEthSign: (id, message) {
        // Respond to personal_sign or eth_sign or eth_signTypedData request callback
      },
      onEthSendTransaction: (id, tx) {
        // Respond to eth_sendTransaction request callback
      },
      onEthSignTransaction: (id, tx) {
        // Respond to eth_signTransaction request callback
      },
    );
```

2.  Create UCSession object from uc: uri.

```dart
    final session = UCSession.from(ucUri);
```

3.  Create UCPeerMeta object containing metadata for your app.

```dart
    final peerMeta = UCPeerMeta(
        name: 'Example Wallet',
        url: 'https://example.wallet',
        description: 'Example Wallet',
        icons: [],
    );
```

4.  Connect to a new session.

```dart
    ucClient.connectNewSession(session: session, peerMeta: peerMeta);
```

5.  Or connect to a saved session (from step 8).

```dart
    ucClient.connectFromSessionStore(sessionStore);
```

6.  Approve a session connection request.

```dart
    ucClient.approveSession(
        accounts: [], // account addresses
        chainId: 1, // chain id
    );
```

7.  Or reject a session connection request.

```dart
    ucClient.rejectSession();
```

8.  Get active session from sessionStore getter to save for later use.

```dart
    final sessionStore = ucClient.sessionStore;
```

9.  Approve a sign transaction request by signing the transaction and sending the signed hex data.

```dart
    ucClient.approveRequest<String>(
        id: id,
        result: signedDataAsHex,
    );
```

10. Approve a send transaction request by sending the transaction hash generated from sending the transaction.

```dart
    ucClient.approveRequest<String>(
        id: id,
        result: transactionHash,
    );
```

11. Approve a sign request by sending the signed data hex generated.

```dart
    ucClient.approveRequest<String>(
        id: id,
        result: signedDataAsHex,
    );
```

12. Or reject any of the requests above by specifying request id.

```dart
    ucClient.rejectRequest(id: id);
```

13. Disconnect from a connected session locally.

```dart
    ucClient.disconnect();
```

14. Permanently close a connected session.

```dart
    ucClient.killSession();
```
