import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:wallet_connect_example/bean/wallet_bean.dart';
import 'package:wallet_connect_example/utils/constants.dart';
import 'package:wallet_connect_example/utils/eth_conversions.dart';
import 'package:wallet_connect_example/widgets/input_field.dart';
import 'package:wallet_connect_example/widgets/qr_scan_view.dart';
import 'package:wallet_connect_example/widgets/session_request_view.dart';
import 'package:wallet_connect_example/widgets/toast.dart';
import 'package:wallet_connect_example/widgets/update_session_view.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:coinslib/coinslib.dart' as coinslib;
import 'package:bip39/bip39.dart' as bip39;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Wallet Connect'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const rpcUri = 'https://ethereum-goerli.publicnode.com';

enum MenuItems {
  PREVIOUS_SESSION,
  UPDATE_SESSION,
  KILL_SESSION,
  SCAN_QR,
  PASTE_CODE,
  CLEAR_CACHE,
  GOTO_URL,
}

class _MyHomePageState extends State<MyHomePage> {
  late WCClient _wcClient;
  late SharedPreferences _prefs;
  late InAppWebViewController _webViewController;
  bool connected = false;
  WCSessionStore? _sessionStore;
  final _web3client = Web3Client(rpcUri, http.Client());
  List<WalletBean> wallets = List.empty(growable: true);
  int selectedWalletIndex = 0;
  late var seed;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  _initialize() async {
    _wcClient = WCClient(
      onSessionRequest: _onSessionRequest,
      onFailure: _onSessionError,
      onDisconnect: _onSessionClosed,
      onEthSign: _onSign,
      onEthSignTransaction: _onSignTransaction,
      onEthSendTransaction: _onSendTransaction,
      onBtcSign: _onBtcSign,
      onBtcSignTransaction: _onBtcSignTransaction,
      onBtcSendTransaction: _onBtcSendTransaction,
      onCustomRequest: (_, __) {},
      onConnect: _onConnect,
      onWalletSwitchNetwork: _onSwitchNetwork,
    );

    _prefs = await SharedPreferences.getInstance();
    seed = bip39.mnemonicToSeed(SEED_MNEMONIC);
    _initWalletsWithSeed(seed);
  }

  _initWalletsWithSeed(Uint8List seed) async {
    // 0x543599aE363450bff398ac0Cca21FE3b07A7bDAB
    var ethHDWallet = coinslib.HDWallet.fromSeed(seed);
    //general eth wallet
    coinslib.HDWallet ethWallet = ethHDWallet.derivePath("m/44'/60'/0'/0");
    EthPrivateKey ethPrivKey = EthPrivateKey(hexToBytes(ethWallet.privKey!));
    WalletBean ethWalletBean = WalletBean(
      name: "Ethereum",
      address: ethPrivKey.address.hexEip55,
      publicKey: bytesToHex(ethPrivKey.encodedPublicKey),
      chainId: 1,
      derivePath: "m/44'/60'/0'/0",
      chainType: ChainType.eth,
    );
    wallets.add(ethWalletBean);
    //general eth testnet wallet
    ethWallet = ethHDWallet.derivePath("m/44'/1'/0'/0");
    ethPrivKey = EthPrivateKey(hexToBytes(ethWallet.privKey!));
    WalletBean ethTestnetWalletBean = WalletBean(
      name: "Ethereum Goerli",
      address: ethPrivKey.address.hexEip55,
      publicKey: bytesToHex(ethPrivKey.encodedPublicKey),
      chainId: 5,
      derivePath: "m/44'/1'/0'/0",
      chainType: ChainType.eth_ropsten,
    );
    wallets.add(ethTestnetWalletBean);

    var btcHDWallet = coinslib.HDWallet.fromSeed(seed, network: coinslib.bitcoin);
    //general btc wallet
    var btcWallet = btcHDWallet.derivePath("m/44'/0'/0'/0");
    WalletBean btcWalletBean = WalletBean(
      name: "Bitcoin",
      address: btcWallet.address,
      publicKey: btcWallet.pubKey,
      derivePath: "m/44'/0'/0'/0",
      chainType: ChainType.btc,
      chainId: 999999,
    );
    wallets.add(btcWalletBean);

    final descriptorSecretKey = await bitcoin.DescriptorSecretKey.fromString(
        "tprv8ZgxMBicQKsPdCsijTmAs1ZEeVu9C98EmbX4g5C5UHQmavCnmnFJytu4ufULeGFf2hodgXPiUeQ18ZpwMVrUa1oNt9EfZfCqZywefv4B6bi/*");

// create external descriptor
    final derivationPath = await bitcoin.DerivationPath.create(path: "m/44h/1h/0h/0");
    final descriptorPrivateKey = await descriptorSecretKey.derive(derivationPath);
    var descriptorPrivate = await bitcoin.Descriptor.create(
      descriptor: "pkh(${descriptorPrivateKey.toString()})",
      network: bitcoin.Network.Testnet,
    );

    bitcoin.Wallet bdkWallet = await bitcoin.Wallet.create(
      descriptor: descriptorPrivate,
      network: bitcoin.Network.Testnet,
      databaseConfig: const bitcoin.DatabaseConfig.memory(),
    );

    bitcoin.AddressInfo btc_address = await bdkWallet.getAddress(addressIndex: const bitcoin.AddressIndex());
    bitcoin.AddressInfo internalAddress = await bdkWallet.getInternalAddress(addressIndex: const bitcoin.AddressIndex());
    String btc_privateKey = descriptorSecretKey.asString();
    String btc_publicKey = await descriptorPrivate.asString();
    print("BTC---->私钥：${btc_privateKey} ,地址：${btc_address.address},内部地址：${internalAddress.address},公钥:${btc_publicKey}");

    WalletBean btcTestnet2WalletBean = WalletBean(
      name: "Bitcoin testnet 用于交易签名方法",
      address: btc_address.address,
      publicKey: btc_publicKey,
      derivePath: "m/44'/1'/0'/0",
      chainType: ChainType.btc_testnet,
      chainId: 999990,
    );
    wallets.add(btcTestnet2WalletBean);

    btcHDWallet = coinslib.HDWallet.fromSeed(seed, network: coinslib.testnet);
    //general btc testnet wallet
    btcWallet = btcHDWallet.derivePath("m/44'/1'/0'/0");
    WalletBean btcTestnetWalletBean = WalletBean(
      name: "Bitcoin testnet",
      address: btcWallet.address,
      publicKey: btcWallet.pubKey,
      derivePath: "m/44'/1'/0'/0",
      chainType: ChainType.btc_testnet,
      chainId: 999990,
    );
    wallets.add(btcTestnetWalletBean);

    setState(() {});
  }

//   _initBTCWallet() async {
//     //btc
//     final descriptorSecretKey = await bitcoin.DescriptorSecretKey.fromString(BTC_PRIVATE_KEY);

// // create external descriptor
//     final derivationPath = await bitcoin.DerivationPath.create(path: "m/44h/1h/0h/0");
//     final descriptorPrivateKey = await descriptorSecretKey.derive(derivationPath);
//     descriptorPrivate = await bitcoin.Descriptor.create(
//       descriptor: "pkh(${descriptorPrivateKey.toString()})",
//       network: bitcoin.Network.Testnet,
//     );

// // create internal descriptor
//     final derivationPathInt = await bitcoin.DerivationPath.create(path: "m/44h/1h/0h/1");
//     final descriptorPrivateKeyInt = await descriptorSecretKey.derive(derivationPathInt);
//     final bitcoin.Descriptor descriptorPrivateInt = await bitcoin.Descriptor.create(
//       descriptor: "pkh(${descriptorPrivateKeyInt.toString()})",
//       network: bitcoin.Network.Testnet,
//     );

//     bdkWallet = await bitcoin.Wallet.create(
//       descriptor: descriptorPrivate,
//       changeDescriptor: descriptorPrivateInt,
//       network: bitcoin.Network.Testnet,
//       databaseConfig: const bitcoin.DatabaseConfig.memory(),
//     );

//     bitcoin.AddressInfo btc_address = await bdkWallet.getAddress(addressIndex: const bitcoin.AddressIndex());
//     bitcoin.AddressInfo internalAddress = await bdkWallet.getInternalAddress(addressIndex: const bitcoin.AddressIndex());
//     String btc_privateKey = descriptorSecretKey.asString();

//     print("BTC---->私钥：${btc_privateKey} ,地址：${btc_address.address},内部地址：${internalAddress.address}");
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("U-Connect Demo"),
        iconTheme: IconThemeData(
          color: Color(0xff373737),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.lightBlue,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ListView.separated(
                    itemCount: wallets.length,
                    padding: EdgeInsets.only(top: 20),
                    separatorBuilder: (context, index) {
                      return Divider(height: 1, color: Colors.blueGrey);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      WalletBean walletBean = wallets[index];
                      return GestureDetector(
                        onTap: () {
                          if (connected) {
                            Toast.show("Please kill current session first", context);
                          } else {
                            setState(() {
                              selectedWalletIndex = index;
                            });
                          }
                        },
                        child: Container(
                          height: 80,
                          color: selectedWalletIndex == index ? Colors.black12 : Colors.white,
                          padding: EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      walletBean.name,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      walletBean.address,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: walletBean.address));
                                  Toast.show("Address has been copied to clipboard", context);
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  child: Center(child: Text("Copy")),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
              SizedBox(height: 50),
              connected
                  ? GestureDetector(
                      onTap: () {
                        _killSession();
                      },
                      child: Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Center(
                          child: Text(
                            "Kill Session",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QRScanView()),
                        ).then((value) {
                          if (value != null) {
                            _qrScanHandler(value);
                          }
                        });
                      },
                      child: Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Center(
                          child: Text(
                            "Connect",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  _connectToPreviousSession();
                },
                child: Container(
                  width: 300,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      "Connect to Previous Session",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(widget.title),
  //       actions: [
  //         PopupMenuButton<MenuItems>(
  //           onSelected: (item) {
  //             switch (item) {
  //               case MenuItems.PREVIOUS_SESSION:
  //                 _connectToPreviousSession();
  //                 break;
  //               case MenuItems.UPDATE_SESSION:
  //                 if (_wcClient.isConnected) {
  //                   showGeneralDialog(
  //                     context: context,
  //                     barrierDismissible: true,
  //                     barrierLabel: 'Update Session',
  //                     pageBuilder: (context, _, __) => UpdateSessionView(
  //                       client: _wcClient,
  //                       address: walletAddress,
  //                     ),
  //                   ).then((value) {
  //                     if (value != null && (value as List).isNotEmpty) {
  //                       _wcClient.updateSession(
  //                         chainId: value[0] as int,
  //                         accounts: [value[1] as String],
  //                       );
  //                     }
  //                   });
  //                 } else {
  //                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                     content: Text('Not connected.'),
  //                   ));
  //                 }
  //                 break;
  //               case MenuItems.KILL_SESSION:
  //                 _wcClient.killSession();
  //                 break;
  //               case MenuItems.SCAN_QR:
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(builder: (_) => QRScanView()),
  //                 ).then((value) {
  //                   if (value != null) {
  //                     _qrScanHandler(value);
  //                   }
  //                 });
  //                 break;
  //               case MenuItems.PASTE_CODE:
  //                 showGeneralDialog(
  //                   context: context,
  //                   barrierDismissible: true,
  //                   barrierLabel: 'Paste Code',
  //                   pageBuilder: (context, _, __) => InputDialog(
  //                     title: 'Paste code to connect',
  //                     label: 'Enter Code',
  //                   ),
  //                 ).then((value) {
  //                   if (value != null && (value as String).isNotEmpty) {
  //                     _qrScanHandler(value);
  //                   }
  //                 });
  //                 break;
  //               case MenuItems.CLEAR_CACHE:
  //                 _webViewController.clearCache();
  //                 break;
  //               case MenuItems.GOTO_URL:
  //                 showGeneralDialog(
  //                   context: context,
  //                   barrierDismissible: true,
  //                   barrierLabel: 'Goto URL',
  //                   pageBuilder: (context, _, __) => InputDialog(
  //                     title: 'Enter URL to open',
  //                     label: 'Enter URL',
  //                   ),
  //                 ).then((value) {
  //                   if (value != null && (value as String).isNotEmpty) {
  //                     _webViewController.loadUrl(
  //                       urlRequest: URLRequest(url: Uri.parse(value)),
  //                     );
  //                   }
  //                 });
  //                 break;
  //             }
  //           },
  //           itemBuilder: (_) {
  //             return [
  //               PopupMenuItem(
  //                 value: MenuItems.PREVIOUS_SESSION,
  //                 child: Text('Connect Previous Session'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.UPDATE_SESSION,
  //                 child: Text('Update Session'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.KILL_SESSION,
  //                 child: Text('Kill Session'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.SCAN_QR,
  //                 child: Text('Connect via QR'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.PASTE_CODE,
  //                 child: Text('Connect via Code'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.CLEAR_CACHE,
  //                 child: Text('Clear Cache'),
  //               ),
  //               PopupMenuItem(
  //                 value: MenuItems.GOTO_URL,
  //                 child: Text('Goto URL'),
  //               ),
  //             ];
  //           },
  //         ),
  //       ],
  //     ),
  //     body: InAppWebView(
  //       initialUrlRequest: URLRequest(url: Uri.parse('https://uc1-demo-dapp.sandbox158.run/')),
  //       initialOptions: InAppWebViewGroupOptions(
  //         crossPlatform: InAppWebViewOptions(
  //           useShouldOverrideUrlLoading: true,
  //         ),
  //       ),
  //       onWebViewCreated: (controller) {
  //         _webViewController = controller;
  //       },
  //       shouldOverrideUrlLoading: (controller, navAction) async {
  //         final url = navAction.request.url.toString();
  //         debugPrint('URL $url');
  //         if (url.contains('uc?uri=')) {
  //           final wcUri = Uri.parse(Uri.decodeFull(Uri.parse(url).queryParameters['uri']!));
  //           _qrScanHandler(wcUri.toString());
  //           return NavigationActionPolicy.CANCEL;
  //         } else if (url.startsWith('uc:')) {
  //           _qrScanHandler(url);
  //           return NavigationActionPolicy.CANCEL;
  //         } else {
  //           return NavigationActionPolicy.ALLOW;
  //         }
  //       },
  //     ),
  //   );
  // }

  _qrScanHandler(String value) {
    if (value.contains('bridge') && value.contains('key')) {
      final session = WCSession.from(value);
      debugPrint('session $session');
      final peerMeta = WCPeerMeta(
        name: "Example Wallet",
        url: "https://example.wallet",
        description: "Example Wallet",
        icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png"],
      );
      _wcClient.connectNewSession(session: session, peerMeta: peerMeta);
    }
  }

  _connectToPreviousSession() {
    final _sessionSaved = _prefs.getString('session');
    debugPrint('_sessionSaved $_sessionSaved');
    _sessionStore = _sessionSaved != null ? WCSessionStore.fromJson(jsonDecode(_sessionSaved)) : null;
    if (_sessionStore != null) {
      debugPrint('_sessionStore $_sessionStore');
      try {
        _wcClient.connectFromSessionStore(_sessionStore!);
      } catch (e) {
        Future.delayed(Duration(seconds: 5)).then((value) {
          if (!connected) {
            _wcClient.connectFromSessionStore(_sessionStore!);
          }
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No previous session found.'),
      ));
    }
  }

  _onConnect() {
    setState(() {
      connected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: _sessionStore == null ? Text('Connected') : Text('Connected to ${_sessionStore!.peerMeta.name}'),
    ));
  }

  _onSwitchNetwork(int id, int chainId) async {
    await _wcClient.updateSession(chainId: chainId);
    _wcClient.approveRequest<Null>(id: id, result: null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Changed network to $chainId.'),
    ));
  }

  _onSessionRequest(int id, WCPeerMeta peerMeta) async {
    // String pubKey = await descriptorPrivate.asString();
    // print("BTC公钥:${pubKey}");
    WalletBean walletBean = wallets[selectedWalletIndex];
    showDialog(
      context: context,
      builder: (_) => SessionRequestView(
        peerMeta: peerMeta,
        onApprove: (chainId) async {
          _wcClient.approveSession(
            accounts: [walletBean.address],
            publicKeys: [walletBean.publicKey],
            chainId: walletBean.chainId,
          );
          _sessionStore = _wcClient.sessionStore;
          await _prefs.setString('session', jsonEncode(_wcClient.sessionStore.toJson()));
          Navigator.pop(context);
        },
        onReject: () {
          _wcClient.rejectSession();
          Navigator.pop(context);
        },
      ),
    );
  }

  _onSessionError(dynamic message) {
    setState(() {
      connected = false;
    });
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Text("Error"),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Some Error Occured. $message'),
            ),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CLOSE'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _killSession() {
    setState(() {
      connected = false;
    });
    _prefs.remove('session');
    _wcClient.killSession();
  }

  _onSessionClosed(int? code, String? reason) {
    print("连接断开,错误码:${code},原因:${reason}");
    if (code == 1005) {
      connected = false;
      Future.delayed(Duration(seconds: 1)).then((value) {
        _connectToPreviousSession();
      });
      return;
    }

    _prefs.remove('session');
    setState(() {
      connected = false;
    });
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Text("Session Ended"),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Some Error Occured. ERROR CODE: $code'),
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Failure Reason: $reason'),
              ),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CLOSE'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _onSignTransaction(
    int id,
    WCEthereumTransaction ethereumTransaction,
  ) {
    WalletBean walletBean = wallets[selectedWalletIndex];
    var hdWallet = coinslib.HDWallet.fromSeed(seed);
    coinslib.HDWallet ethdWallet = hdWallet.derivePath(walletBean.derivePath);
    EthPrivateKey ethPrivKey = EthPrivateKey(hexToBytes(ethdWallet.privKey!));

    _onTransaction(
      id: id,
      ethereumTransaction: ethereumTransaction,
      title: 'Sign Transaction',
      onConfirm: () async {
        final tx = await _web3client.signTransaction(
          ethPrivKey,
          _wcEthTxToWeb3Tx(ethereumTransaction),
          chainId: _wcClient.chainId!,
        );
        _wcClient.approveRequest<String>(
          id: id,
          result: bytesToHex(tx),
        );
        Navigator.pop(context);
      },
      onReject: () {
        _wcClient.rejectRequest(id: id);
        Navigator.pop(context);
      },
    );
  }

  _onSendTransaction(
    int id,
    WCEthereumTransaction ethereumTransaction,
  ) {
    WalletBean walletBean = wallets[selectedWalletIndex];
    var hdWallet = coinslib.HDWallet.fromSeed(seed);
    coinslib.HDWallet ethdWallet = hdWallet.derivePath(walletBean.derivePath);
    EthPrivateKey ethPrivKey = EthPrivateKey(hexToBytes(ethdWallet.privKey!));

    _onTransaction(
      id: id,
      ethereumTransaction: ethereumTransaction,
      title: 'Send Transaction',
      onConfirm: () async {
        var txhash;
        try {
          txhash = await _web3client.sendTransaction(
            ethPrivKey,
            _wcEthTxToWeb3Tx(ethereumTransaction),
            chainId: _wcClient.chainId!,
          );
        } catch (e) {
          print(e.toString());
          Toast.show(e.toString(), context);
          _wcClient.rejectRequest(id: id);
        }
        if (txhash != null) {
          debugPrint('txhash $txhash');
          _wcClient.approveRequest<String>(
            id: id,
            result: txhash,
          );
        }
        Navigator.pop(context);
      },
      onReject: () {
        _wcClient.rejectRequest(id: id);
        Navigator.pop(context);
      },
    );
  }

  _onTransaction({
    required int id,
    required WCEthereumTransaction ethereumTransaction,
    required String title,
    required VoidCallback onConfirm,
    required VoidCallback onReject,
  }) async {
    BigInt gasPrice = BigInt.parse(ethereumTransaction.gasPrice ?? '0');
    if (gasPrice == BigInt.zero) {
      gasPrice = await _web3client.estimateGas();
    }
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (_sessionStore!.peerMeta.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(_wcClient.remotePeerMeta!.icons.first),
                ),
              Text(
                _wcClient.remotePeerMeta!.name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${ethereumTransaction.to}',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction Fee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${EthConversions.weiToEthUnTrimmed(gasPrice * BigInt.parse(ethereumTransaction.gas ?? '0'), 18)} ETH',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${EthConversions.weiToEthUnTrimmed(BigInt.parse(ethereumTransaction.value ?? '0'), 18)} MATIC',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  children: [
                    Text(
                      '${ethereumTransaction.data}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: onConfirm,
                    child: Text('CONFIRM'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: onReject,
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _onSign(
    int id,
    WCEthereumSignMessage ethereumSignMessage,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (_wcClient.remotePeerMeta!.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(_wcClient.remotePeerMeta!.icons.first),
                ),
              Text(
                _wcClient.remotePeerMeta!.name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Sign Message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  children: [
                    Text(
                      ethereumSignMessage.data!,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      WalletBean walletBean = wallets[selectedWalletIndex];
                      var hdWallet = coinslib.HDWallet.fromSeed(seed);
                      coinslib.HDWallet ethdWallet = hdWallet.derivePath(walletBean.derivePath);
                      EthPrivateKey ethPrivKey = EthPrivateKey(hexToBytes(ethdWallet.privKey!));

                      String signedDataHex;
                      if (ethereumSignMessage.type == WCSignType.TYPED_MESSAGE) {
                        signedDataHex = EthSigUtil.signTypedData(
                          privateKey: bytesToHex(ethPrivKey.privateKey),
                          jsonData: ethereumSignMessage.data!,
                          version: TypedDataVersion.V4,
                        );
                      } else {
                        final encodedMessage = hexToBytes(ethereumSignMessage.data!);
                        final signedData = await ethPrivKey.signPersonalMessageToUint8List(encodedMessage);
                        signedDataHex = bytesToHex(signedData, include0x: true);
                      }
                      debugPrint('SIGNED $signedDataHex');
                      _wcClient.approveRequest<String>(
                        id: id,
                        result: signedDataHex,
                      );
                      Navigator.pop(context);
                    },
                    child: Text('SIGN'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      _wcClient.rejectRequest(id: id);
                      Navigator.pop(context);
                    },
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Transaction _wcEthTxToWeb3Tx(WCEthereumTransaction ethereumTransaction) {
    return Transaction(
      from: EthereumAddress.fromHex(ethereumTransaction.from),
      to: EthereumAddress.fromHex(ethereumTransaction.to!),
      maxGas: ethereumTransaction.gasLimit != null ? int.tryParse(ethereumTransaction.gasLimit!) : null,
      gasPrice: ethereumTransaction.gasPrice != null ? EtherAmount.inWei(BigInt.parse(ethereumTransaction.gasPrice!)) : null,
      value: EtherAmount.inWei(BigInt.parse(ethereumTransaction.value ?? '0')),
      data: hexToBytes(ethereumTransaction.data!),
      nonce: ethereumTransaction.nonce != null ? int.tryParse(ethereumTransaction.nonce!) : null,
    );
  }

  _onBtcSign(int id, UCBitcoinSignMessage message) async {
    print("WC:Request:onBtcSign");

    __onBTCSign(id, message);
    // final creds = EthPrivateKey.fromHex(BTC_PRIVATE_KEY);
    // final encodedMessage = hexToBytes(message.data!);
    // final signedData = await creds.signPersonalMessageToUint8List(encodedMessage);
    // String signedDataHex = bytesToHex(signedData, include0x: true);
    // print('SIGNED $signedDataHex');
    // _wcClient.approveRequest<String>(
    //   id: id,
    //   result: signedDataHex,
    // );

    // var peercoin = NetworkType(
    //   messagePrefix: 'Peercoin Signed Message:\n',
    //   bech32: 'pc',
    //   bip32: Bip32Type(public: 0x043587cf, private: 0x04358394),
    //   pubKeyHash: 0x37,
    //   scriptHash: 0x75,
    //   wif: 0xb7,
    //   opreturnSize: 256,
    // );

    // String entropy = bip39.mnemonicToEntropy("praise you muffin lion enable neck grocery crumble super myself license ghost");
    // print("entropy:" + entropy);
    // String mnemonic = bip39.entropyToMnemonic(entropy);
    // var seed = bip39.mnemonicToSeed(mnemonic);

    // coinslib.BIP32.fromSeed(coinslib.testnet)

    // var hdWallet = coinslib.HDWallet.fromSeed(
    //   seed,
    //   network: coinslib.testnet,
    // ); //default network is Bitcoin
    // print(hdWallet.address);
    // // => mhARbrfUzFoepzrAwdzwEVWAi3Wmq22FmR
    // print(hdWallet.pubKey);
    // // => 0360729fb3c4733e43bf91e5208b0d240f8d8de239cff3f2ebd616b94faa0007f4
    // print(hdWallet.privKey);
    // // => 01304181d699cd89db7de6337d597adf5f78dc1f0784c400e41a3bd829a5a226
    // print(hdWallet.wif);
    // // => cMd1eP15rgk3o2ikF3dYVJGQBqB2nQfWTN7LnjSzADkAKaFyGJjw

    // Uint8List signedData = hdWallet.sign(message.data!);
    // String signedDataHex = bytesToHex(signedData, include0x: true);
    // print('SIGNED $signedDataHex');
    // _wcClient.approveRequest<String>(
    //   id: id,
    //   result: signedDataHex,
    // );

    // var wallet = coinslib.Wallet.fromWIF('U59hdLpi45SME3yjGoXXuYy8FVvW2yUoLdE3TJ3gfRYJZ33iWbfD', coinslib.testnet);
    // print(wallet.address);
    // // => PAEeTmyME9rb2j3Ka9M65UG7To5wzZ36nf
    // print(wallet.pubKey);
    // // => 03aea0dfd576151cb399347aa6732f8fdf027b9ea3ea2e65fb754803f776e0a509
    // print(wallet.privKey);
    // // => 01304181d699cd89db7de6337d597adf5f78dc1f0784c400e41a3bd829a5a226
    // print(wallet.wif);
    // // => U59hdLpi45SME3yjGoXXuYy8FVvW2yUoLdE3TJ3gfRYJZ33iWbfD
  }

  _onBtcSignTransaction(int id, UCBitcoinTransaction bitcoinTransaction) async {
    print("WC:Request:onBtcSignTransaction");

    // WalletBean walletBean = wallets[selectedWalletIndex];
    // var hdWallet = coinslib.HDWallet.fromSeed(seed, network: walletBean.chainType == ChainType.btc ? coinslib.bitcoin : coinslib.testnet);
    // hdWallet = hdWallet.derivePath(walletBean.derivePath);

    // //解析Psbt
    // bitcoin.PartiallySignedTransaction psbt = bitcoin.PartiallySignedTransaction(psbtBase64: bitcoinTransaction.data);
    // bitcoin.Transaction transaction = await psbt.extractTx();
    // //组装coinslib交易对象
    // final txb = coinslib.TransactionBuilder();
    // txb.setVersion(await transaction.version());
    // List<bitcoin.TxIn> inputs = await transaction.input();
    // for (bitcoin.TxIn input in inputs) {
    //   // final OutPoint previousOutput;
    //   // final Script scriptSig;
    //   // final int sequence;
    //   // final List<String> witness;

    //   txb.addInput(
    //     input.scriptSig.internal,
    //     input.witness.length,
    //     input.sequence,
    //     hexToBytes(input.previousOutput.txid),
    //   );
    // }
    // List<bitcoin.TxOut> outputs = await transaction.output();
    // for (bitcoin.TxOut output in outputs) {
    //   txb.addOutput(output.scriptPubkey.internal, BigInt.from(output.value));
    // }
    // final keyPair = coinslib.ECPair.fromWIF(hdWallet.wif!, network: walletBean.chainType == ChainType.btc ? coinslib.bitcoin : coinslib.testnet);
    // String signature = txb.sign(vin: 0, keyPair: keyPair);

    // getTxBuilderWithIn() {
    //   final txb = coinslib.TransactionBuilder();
    //   txb.setVersion(1);
    //   txb.addInput(
    //     '61d520ccb74288c96bc1a2b20ea1c0d5a704776dd0164a396efec3ea7040349d',
    //     0,
    //   );
    //   return txb;
    // }

    // // hdWallet.sign
    // final txb = getTxBuilderWithIn();

    // txb.addOutput('1cMh228HTCiwS8ZsaakH8A8wze1JR5ZsP', BigInt.from(12000));
    // (in)15000 - (out)12000 = (fee)3000, this is the miner fee

    final descriptorSecretKey = await bitcoin.DescriptorSecretKey.fromString(
        "tprv8ZgxMBicQKsPdCsijTmAs1ZEeVu9C98EmbX4g5C5UHQmavCnmnFJytu4ufULeGFf2hodgXPiUeQ18ZpwMVrUa1oNt9EfZfCqZywefv4B6bi/*");

// create external descriptor
    final derivationPath = await bitcoin.DerivationPath.create(path: "m/44h/1h/0h/0");
    final descriptorPrivateKey = await descriptorSecretKey.derive(derivationPath);
    var descriptorPrivate = await bitcoin.Descriptor.create(
      descriptor: "pkh(${descriptorPrivateKey.toString()})",
      network: bitcoin.Network.Testnet,
    );

    bitcoin.Wallet bdkWallet = await bitcoin.Wallet.create(
      descriptor: descriptorPrivate,
      network: bitcoin.Network.Testnet,
      databaseConfig: const bitcoin.DatabaseConfig.memory(),
    );
    bitcoin.PartiallySignedTransaction psbt = bitcoin.PartiallySignedTransaction(psbtBase64: bitcoinTransaction.data);

    bitcoin.PartiallySignedTransaction signedTransaction = await bdkWallet.sign(psbt: psbt);
    String signedTx = await signedTransaction.jsonSerialize();
    Map signedTxMap = jsonDecode(signedTx);
    String signature = signedTxMap["inputs"][0]["final_script_sig"];
    _wcClient.approveRequest<String>(
      id: id,
      result: signature,
    );
  }

  _onBtcSendTransaction(int id, UCBitcoinTransaction bitcoinTransaction) async {
    print("WC:Request:onBtcSendTransaction");
    // bitcoin.PartiallySignedTransaction psbt = bitcoin.PartiallySignedTransaction(psbtBase64: bitcoinTransaction.data);

    // bitcoin.PartiallySignedTransaction signedTransaction = await bdkWallet.sign(psbt: psbt);

    //这里需要发送这条交易数据
    // _wcClient.approveRequest<String>(
    //   id: id,
    //   result: txid,
    // );
  }

  __onBTCSign(int id, UCBitcoinSignMessage message) {
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (_wcClient.remotePeerMeta!.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(_wcClient.remotePeerMeta!.icons.first),
                ),
              Text(
                _wcClient.remotePeerMeta!.name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Sign Message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  children: [
                    Text(
                      message.data!,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      WalletBean walletBean = wallets[selectedWalletIndex];

                      var hdWallet =
                          coinslib.HDWallet.fromSeed(seed, network: walletBean.chainType == ChainType.btc ? coinslib.bitcoin : coinslib.testnet);
                      hdWallet = hdWallet.derivePath(walletBean.derivePath);
                      Uint8List signedData = hdWallet.sign(message.data!);
                      String signedDataHex = bytesToHex(signedData, include0x: true);
                      print('SIGNED $signedDataHex');
                      _wcClient.approveRequest<String>(
                        id: id,
                        result: signedDataHex,
                      );
                      Navigator.pop(context);
                    },
                    child: Text('SIGN'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      _wcClient.rejectRequest(id: id);
                      Navigator.pop(context);
                    },
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
