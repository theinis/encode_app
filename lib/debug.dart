import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'comms.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:masked_text_field/masked_text_field.dart';

class DebugPage extends StatefulWidget {
  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> with TickerProviderStateMixin {
  int _state = 0;

  Widget setUpButtonChild() {
    if (_state == 0) {
      return Text(
        "Click Here",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      );
    } else if (_state == 1) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    } else {
      return Icon(Icons.check, color: Colors.white);
    }
  }

  void animateButton() {

    setState(() {
      _state = 1;
    });

    Timer(Duration(milliseconds: 3300), () {
      setState(() {
        _state = 2;
      });
    });
  }

  List<String> buttonTexts = ['Start', 'Confirm', 'Confirm'];
  int currentTextIndex = 0;
  bool showIndicator = false;
  
  final RoundedLoadingButtonController _btnController1 =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    _btnController1.stateStream.listen((value) {
      print(value);
    });
  }

  late String sessionID;
  late var runID;

  void _showCartridgeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Exchanging cartridge";
        String contentText = "Make sure new cartridge is ready";

        LinearProgressIndicator progressindicator = LinearProgressIndicator(value: 1.0,
                          backgroundColor: Colors.orangeAccent,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                          minHeight: 8,
                        );

        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return AlertDialog(
              title: Text(titleText),
              content: SizedBox(
                height: 50,
                child: Column(
                  children: [
                    Text(contentText),
                    showIndicator
                      ? SizedBox(height: 10)
                      : SizedBox(height: 1),
                    showIndicator
                        ? progressindicator
                        : Text('')
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      //this should lead to all state being removed, i.e., the queue cleared etc.
                      child: Text("Abort"),
                    ),
                    StatefulBuilder(builder: (context, StateSetter setStates) {
                      return InkWell(
                        onTap: () async {

                          print("Pressed with currentTextIndex is $currentTextIndex");

                          if (currentTextIndex == 0) {

                            setState(() {});

                            setStates(() {
                              contentText = "Lowering cartridge...";
                              showIndicator = true;
                            });

                            sessionID = await loginCall();

                            initiateCartridgeChange(sessionID);

                            Result initResponse = await initCall(sessionID);

                            while(initResponse.data['processRunQueue'].length == 0) {
                              await Future.delayed(Duration(milliseconds: 1000));
                              initResponse = await initCall(sessionID);
                              print("waiting");
                            } 

                            //should check that we're lookign at the correct event processType:"cartridgeUp"

                            runID  = initResponse.data['processRunQueue'][0]['id'];

                            Result runResponse = await processRunCall(sessionID, runID);

                            //pendinganswer now
                            Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);
                          
                            while(! await isAnswerPending(sessionID)) {
                              await Future.delayed(Duration(milliseconds: 500));
                              print("waiting");
                            } 

                            //won't update content text if not present
                            setState(() {});

                            setStates(() {
                              contentText = "Please remove cartridge";
                              print("DEBUG - increment 1");
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });
                          } else if (currentTextIndex == 1) {

                            Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);

                            setState(() {});

                            setStates(() {
                              contentText = "Please insert new cartridge";
                              print("DEBUG - increment 2");
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 2) {

                            Result response = await cartridgeInsertConfirmedCall(sessionID, runID);

                            setState(() {});

                            setStates(() {
                              contentText = "Moving cartridge up";
                              print("DEBUG - increment 3");
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = true;
                            });
 
                            while(! await isCartridgePositionClosed(sessionID)) {
                              await Future.delayed(Duration(milliseconds: 1000));
                              print("waiting");
                            } 

                            Navigator.pop(context);

                          } else {

                            print("DEBUG - undefined currentTextIndex with $currentTextIndex");

                          }
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(21)),
                        child: Center(
                          child: showIndicator
                              ? Center(child: 
                                  SizedBox( width: 15, height: 15, child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )))
                              : Text(
                                  buttonTexts[currentTextIndex],
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ));
                }),
              ],
            ),
          ],
        );
          },
        );
      },
    );
  }


  void _showNetworkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {

        String titleText = "Configure network";

        var KBIPController = TextEditingController();
        var MinionIPController = TextEditingController();

        MaskedTextField kilobaserip = MaskedTextField(
          textFieldController: KBIPController,
          inputDecoration: const InputDecoration(
            hintText: '192.192.192.192',
            counterText: ""
          ),
          autofocus: true,
          mask: 'xxx.xxx.xxx.xxx',
          maxLength: 15,
          keyboardType: TextInputType.number,
          onChange: (String value) {
            print(value);
          },
        );

        MaskedTextField minionip = MaskedTextField(
          textFieldController: MinionIPController,
          inputDecoration: const InputDecoration(
            hintText: '192.192.192.192',
            counterText: ""
          ),
          autofocus: true,
          mask: 'xxx.xxx.xxx.xxx',
          maxLength: 15,
          keyboardType: TextInputType.number,
          onChange: (String value) {
            print(value);
          },
        );

/*
        TextField kilobaserip = TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Kilobaser IP',
          )
        ); 

        TextField minionip = TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Minion IP',
          )
        );
*/

        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return AlertDialog(
              title: Text(titleText),
              content: SizedBox(
                height: 200,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Enter Kilobaser IP Address"),
                      ),
                    ),
                    const SizedBox(height: 5,),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: kilobaserip
                    ),
                    const SizedBox(height: 30,),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Enter MinION IP Address"),
                      ),
                    ),
                    const SizedBox(height: 5,),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: minionip
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Abort')
                        ),
                      
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Save')
                        ),
                      
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: StatefulBuilder(builder: (context, StateSetter setStates) {
                          return InkWell(
                            onTap: () async {

                              setState(() {});

                              setStates(() {
                                showIndicator = true;
                              });

                              String subnet = '192.168.1';

                              //looking for Minion
                              final minionstream = NetworkDiscovery.discover(subnet, 80); 

                              //assumption: only one device will be found
                              var minionip = "";
                              minionstream.listen((NetworkAddress addr) {
                                minionip = addr.ip.toString();
                                print('Found MinION: ${addr.ip}');
                              }).onDone(() => MinionIPController.text = minionip);

                              //looking for Kilobaser
                              final kilobaserstream = NetworkDiscovery.discover(subnet, 80); 

                              var kilobaserip = "";
                              kilobaserstream.listen((NetworkAddress addr) {
                                kilobaserip = addr.ip.toString();
                                print('Found Kilobaser: ${addr.ip}');
                              }).onDone(() => KBIPController.text = kilobaserip);

                              setState(() {});

                              setStates(() {
                                showIndicator = false;
                              });

                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(21)),
                            child: Center(
                              child: showIndicator
                                ? Center(child: 
                                    SizedBox( width: 15, height: 15, child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    )))
                                : Text(
                                  "Find Devices",
                                  style: TextStyle(color: Colors.white),
                                ),
                          ),
                        ));
                      }),
                    )


              ],
            ),
          ],
        );
          },
        );
      },
    );
  }
  

  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
      //  title: Text("Encode to DNA & Synthesise"),
      //  backgroundColor: Colors.blue,
      //),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      _showCartridgeDialog(context);
                    },
                    child: Text('Exchange cartridge'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {

                      _showNetworkDialog(context);

                    },
                    child: Text('Configure network'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }
}