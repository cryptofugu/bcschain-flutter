
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/src/components/qr_scan.dart';
import '/src/configuration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:bitcoin_flutter/src/utils/script.dart';
import 'package:bitcoin_flutter/src/utils/constants/op.dart';
import "package:hex/hex.dart";
import 'package:base58check/base58.dart';
import 'package:url_launcher/url_launcher.dart';
import '/src/constants.dart' as CONSTANTS;
import 'package:http/http.dart';
import 'token_list_page.dart' as TokenList;
import 'screen_lock_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendTransaction extends StatefulWidget {
  SendTransaction(this.address);

  final String address;

  @override
  State<StatefulWidget> createState() => SendTransactionState(address, inputAddress: null, inputValue: null);
}

class SendTransactionState extends State<SendTransaction> {

  SendTransactionState(this.address, {this.inputAddress, this.inputValue});

  final String address;

  String? inputAddress;
  String? inputValue;

  late String alertText;
  late TextEditingController addressController;
  late TextEditingController valueController;

  FocusNode addressFocusNode = new FocusNode();
  FocusNode valueFocusNode = new FocusNode();
  String dropdownValue = 'BCS';
  List<String> dropdownItems = List.filled(1, 'BCS', growable: true);

  late List<TokenList.Token>? tokens;

  double _feeValue = 0.003;
  double _gasLimitValue = 200000;
  double _gasPriceValue = 50;
  bool? addressValidator;
  bool? valueValidator;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(text: inputAddress);
    valueController = TextEditingController(text: inputValue);
  }

  void _requestValueFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(valueFocusNode);
    });
  }

  void _requestAddressFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(addressFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TokenList.Token>>(
      future: fillTokens(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          tokens = snapshot.data;
          return Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        focusNode: addressFocusNode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          labelText: AppLocalizations.of(context)!.to,
                          labelStyle: (addressValidator != true) ? (addressFocusNode.hasFocus ? TextStyle(color:Color(0xffbb9f89)) : TextStyle(color:Colors.grey)) : TextStyle(color:Colors.red),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffbb9f89)),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 1,
                        maxLength: 34,
                        controller: addressController,
                        cursorColor: Color(0xffbb9f89),
                        style: TextStyle(color: Color(0xffbb9f89)),
                        onTap: _requestAddressFocus,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^$|^[B][a-km-zA-HJ-NP-Z1-9]{0,33}$')),
                        ],
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: TextField(
                              focusNode: valueFocusNode,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                labelText: AppLocalizations.of(context)!.value,
                                labelStyle: (valueValidator != true) ? (valueFocusNode.hasFocus ? TextStyle(color:Color(0xffbb9f89)) : TextStyle(color:Colors.grey)) : TextStyle(color:Colors.red),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xffbb9f89)),
                                ),
                              ),
                              minLines: 1,
                              maxLines: 1,
                              controller: valueController,
                              keyboardType: TextInputType.number,
                              cursorColor: Color(0xffbb9f89),
                              style: TextStyle(color: Color(0xffbb9f89)),
                              onTap: _requestValueFocus,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp('[0-9.]'))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                icon: const Icon(Icons.arrow_downward,
                                  color: Color(0xffbb9f89)
                                ),
                                iconSize: 24,
                                elevation: 16,
                                underline: Container(
                                  height: 2,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue = newValue!;
                                  });
                                },
                                items: dropdownItems.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(color: Color(0xffbb9f89))),
                                  );
                                }).toList(),
                              )
                            )
                          )
                        ]
                      )
                    ),
                    Divider(
                      height: 30,
                      thickness: 0,
                      indent: 1000,
                      endIndent: 1000,
                    ),
                    Text(AppLocalizations.of(context)!.fee_sat),
                    Slider(
                      value: _feeValue,
                      min: 0.001,
                      max: 0.010001,
                      divisions: 9,
                      label: _feeValue.toStringAsFixed(3),
                      activeColor: Color(0xffbb9f89),
                      inactiveColor: Color(0x4dbb9f89),
                      onChanged: (double value) {
                        setState(() {
                          _feeValue = value;
                        });
                      },
                    ),
                    if (dropdownValue != 'BCS') Text(AppLocalizations.of(context)!.gasLimit),
                    if (dropdownValue != 'BCS') Slider(
                      value: _gasLimitValue,
                      min: 100000,
                      max: 1000000.1,
                      divisions: 18,
                      label: _gasLimitValue.round().toString(),
                      activeColor: Color(0xffbb9f89),
                      inactiveColor: Color(0x4dbb9f89),
                      onChanged: (double value) {
                        setState(() {
                          _gasLimitValue = value;
                        });
                      },
                    ),
                    if (dropdownValue != 'BCS') Text(AppLocalizations.of(context)!.gasPrice_sat_per_gas),
                    if (dropdownValue != 'BCS') Slider(
                      value: _gasPriceValue,
                      min: 40,
                      max: 100,
                      divisions: 12,
                      label: _gasPriceValue.round().toString(),
                      activeColor: Color(0xffbb9f89),
                      inactiveColor: Color(0x4dbb9f89),
                      onChanged: (double value) {
                        setState(() {
                          _gasPriceValue = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text(AppLocalizations.of(context)!.confirm),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xffbb9f89)),
                      ),
                      onPressed: () => _navigate(context),
                    )
                  ]
                )
              )
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Color(0xffbb9f89),
              onPressed: () => _scanQR(context),
              child: const Icon(Icons.qr_code_scanner),
            )
          );
        }
        else 
          return Center(
            child: CircularProgressIndicator(color:Color(0xffbb9f89))
          );
      }
    );
  }

  void _navigate(BuildContext context) async {
    try {
      double.parse(valueController.text);
      setState(() {
        valueValidator = false;
      });
    }
    catch (e) {
      setState(() {
        valueValidator = true;
      });
    } 
    if (addressController.text.length < 34)
      setState(() {
        addressValidator = true;
      });
    else
      setState(() {
        addressValidator = false;
      });

    bool? result;

    if (!addressValidator! && !valueValidator!) 
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScreenLockPage())
      );

    if (result == true)
      if (dropdownValue == 'BCS')
        _buildSendCoinTx();
      else _buildTokenTransferTx(dropdownValue);
  }

  void _buildSendCoinTx() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    final keyPair = ECPair.fromWIF(configurationService.getBCSWIF(), network: CONSTANTS.bcsNetwork);
    var fee = (_feeValue * CONSTANTS.BCS_DECIMALS).toInt();
    var totalValue = 0;
    var value = (double.parse(valueController.text) * CONSTANTS.BCS_DECIMALS).toInt();
    List<UTXO> inputs = await selectP2SHUtxos(context, address, value, fee);
                
    if (inputs.isNotEmpty) {
      final txb = new TransactionBuilder(network: CONSTANTS.bcsNetwork);
      txb.setVersion(1);
      for (var i = 0; i < inputs.length; i++) {
        txb.addInput(
          inputs[i].id,
          inputs[i].outputIndex
        );
        totalValue += inputs[i].value;
      }

      txb.addOutput(addressController.text, value);

      if (totalValue > value + fee)
        txb.addOutput(address, totalValue - value - fee);

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }

      _broadcastTx(txb.build().toHex());
    }
  }

  void _buildTokenTransferTx(String token) async {
    var index;
    for (int i = 0; i < tokens!.length; i++)
      if (tokens![i].symbol == token)
        index = i;
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    const transfer = 'a9059cbb';
    final keyPair = ECPair.fromWIF(configurationService.getBCSWIF(), network: CONSTANTS.bcsNetwork);
    var fee = (_feeValue * CONSTANTS.BCS_DECIMALS).toInt() + _gasLimitValue.toInt() * _gasPriceValue.toInt();
    var totalValue = 0;
    var value = (double.parse(valueController.text) * pow(10, tokens![index].decimals)).toInt().toRadixString(16).padLeft(64, '0');
    var receiverAddress = HEX.encode(Base58Decoder('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz').convert(address)).substring(2,42).padLeft(64, '0');
    List<UTXO> inputs = await selectP2SHUtxos(context, address, 0, fee);
                
    if (inputs.isNotEmpty) {
      final txb = new TransactionBuilder(network: CONSTANTS.bcsNetwork);
      txb.setVersion(1);
      for (var i = 0; i < inputs.length; i++) {
        txb.addInput(
          inputs[i].id,
          inputs[i].outputIndex
        );
        totalValue += inputs[i].value;
      }

      var chunks = List<dynamic>.generate(6, (_) => null);
      chunks[0] = OPS['OP_4'];
      chunks[1] = number2Buffer(_gasLimitValue.toInt());
      chunks[2] = number2Buffer(_gasPriceValue.toInt());
      chunks[3] = Uint8List.fromList(HEX.decode(transfer + receiverAddress + value));
      chunks[4] = Uint8List.fromList(HEX.decode(tokens![index].address));
      chunks[5] = 0xc2; //OP_CALL

      var contract =  compile(chunks);
      txb.addOutput(contract, 0);

      if (totalValue > fee + _gasLimitValue.toInt()*_gasPriceValue.toInt())
        txb.addOutput(address, totalValue - fee - _gasLimitValue.toInt()*_gasPriceValue.toInt());

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }

      _broadcastTx(txb.build().toHex());
    }
  }

  Uint8List number2Buffer(int num) {
    List<int> buffer = List.empty(growable: true);
    var neg = (num < 0);
    num = num.abs();

    while(num > 0) {
        buffer.add(num & 0xff);
        num = num >> 8;
    }

    var top = buffer[buffer.length - 1];

    if (top & 0x80 != 0x00) {
        buffer[buffer.length] = neg ? 0x80 : 0x00;
    }
    else if (neg) {
        buffer[buffer.length - 1] = top | 0x80;
    }

    return Uint8List.fromList(buffer);
  }

  Future<List<TokenList.Token>> fillTokens() async {
    var res = await TokenList.fetchData(address);
    for(int i = 0; i < res.length; i++)
      if (!dropdownItems.contains(res[i].symbol)) dropdownItems.add(res[i].symbol);
    return res;
  }

  void _broadcastTx(String datahex) async {
    Map<String, String> data = {
      'rawtx': datahex,
    };

    var client = new Client();

    try {
      var uriResponse = await client.post(Uri.parse('https://bcschain.info/api/tx/send'),
        body: data);
      var res = HttpResponse.fromJson(jsonDecode(uriResponse.body));
      if (uriResponse.statusCode == 200) {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: res.getStatus() == 0 ? Text(AppLocalizations.of(context)!.txSent) : Text(AppLocalizations.of(context)!.txError),
            content: InkWell(
              child: Text(
                res.getTxResult(),
                style: TextStyle(decoration: TextDecoration.underline),
              ),
              onTap: res.getStatus() == 0 ? () async {
                var url = 'https://bcschain.info/tx/${res.getTxResult()}';
                if (await canLaunch(url)) {
                  await launch(
                    url,
                  );
                }
              } : null,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  addressController.clear();
                  valueController.clear();
                  Navigator.pop(context, 'OK');
                },  
                child: const Text('OK', style: TextStyle(color: Color(0xffbb9f89)),),
              ),
            ],
          ),
        );
      }
    } finally {
      client.close();
    }
  }

  void _scanQR(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );

    if (result != null && result != []) {
      setState(() {
        addressController = TextEditingController(text: result[0]);
        valueController = TextEditingController(text: result[1]);
      });
    }
  }
}


selectP2SHUtxos(context, address, amount, fee) async {
  List<UTXO> unspentTransactions = await fetchUtxos(address);
  List<UTXO> matureList = List.empty(growable: true);
  List<UTXO> immatureList = List.empty(growable: true);

  for(var i = 0; i < unspentTransactions.length; i++) {
    if(unspentTransactions[i].isStake == false || unspentTransactions[i].confirmations >= 500)
      matureList.add(unspentTransactions[i]);
    else
      immatureList.add(unspentTransactions[i]);
  }

  matureList.sort((a, b) {return a.value - b.value;});
  immatureList.sort((a, b) {return b.confirmations - a.confirmations;});

  var value = amount + fee;
  List<UTXO> find = List.empty(growable: true);
  var findTotal = 0;

  for (var i = 0; i < matureList.length; i++) {
    var tx = matureList[i];
    findTotal = findTotal + tx.value;
    find.add(tx);
    if (findTotal >= value) break;
  }

  if (value > findTotal) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.txError),
        content: InkWell(
          child: Text((AppLocalizations.of(context)!.youDontHaveEnoughCoins))
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
            },  
            child: const Text('OK', 
              style: TextStyle(color: Color(0xffbb9f89))
            )
          )
        ]
      ),
    );
  }
  return find;
}

Future<List<UTXO>> fetchUtxos(String address) async {
  final response = await Client()
      .get(Uri.parse('https://bcschain.info/api/address/$address/utxo'));

  return compute(parseUtxos, response.body);
}

class UTXO {
  final String id;
  final int confirmations;
  final int outputIndex;
  final int value;
  final bool isStake;

  UTXO({
    required this.id, 
    required this.confirmations, 
    required this.outputIndex, 
    required this.value, 
    required this.isStake
  });

  factory UTXO.fromJson(dynamic json) {
    return UTXO(
      id: json['transactionId'], 
      confirmations: json['confirmations'] as int,
      outputIndex: json['outputIndex'] as int,
      value: json['value'] as int,
      isStake: json['isStake'] as bool
      );
  }

}

List<UTXO> parseUtxos(String responseBody) {
  final utxoObjsJson = jsonDecode(responseBody) as List;
  List<UTXO> utxoObjs = utxoObjsJson.map((utxoJson) => UTXO.fromJson(utxoJson)).toList();
  return utxoObjs;
}

class HttpResponse {
  final String? message;
  final int status;
  final String? txid;

  HttpResponse({
    this.message, 
    required this.status, 
    this.txid, 
  });

  factory HttpResponse.fromJson(dynamic json) {
    return HttpResponse(
      message: json['message'], 
      status: json['status'] as int,
      txid: json['txid']
      );
  }

  String getTxResult() {
    if (txid != null)
      return txid!;
    else if (message != null)
      return message!;
    else return 'Something gone wrong!';
  }

  int getStatus() {
    return status;
  }
}