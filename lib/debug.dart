import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'comms.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:masked_text_field/masked_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

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

  List<String> buttonTexts = ['Start', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm'];
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

  void _showCleaningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Cleaning Device";
        String contentText = "Make sure chip and cleaning cartridge are ready";

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

                            sessionID = await loginCall();

                            print("sessionID: $sessionID");

                            Result initiateClean = await initiateCleaning(sessionID);
                            print(initiateClean.data);

                            Result initResponse = await initCall(sessionID);

                            print(initResponse.data['processRunQueue'].length);

                            while(initResponse.data['processRunQueue'].length == 0) {
                              await Future.delayed(Duration(milliseconds: 100000));
                              initResponse = await initCall(sessionID);
                              print("waiting");
                            } 

                            runID  = initResponse.data['processRunQueue'][0]['id'];

                            print("DEBUG - Init done");                            

                            Result runResponse = await processRunCall(sessionID, runID);

                            print("PROCESS RUN CALL");
                            print(runResponse.data);

                            Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed.data);
                            
                            //won't update content text if not present
                            setState(() {});

                            setStates(() {
                              contentText = "Opening lid...";
                              showIndicator = true;
                            });

                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid opening...");
                            }

                            if(await isLidOpen(sessionID)) {
                              print("DEBUG - Lid is open");
                            } else {
                              //undefined state
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Please make sure chip and vial are inserted";
                              print("DEBUG - increment 1");
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 1) {

                            print("DEBUG - currentTextIndex is $currentTextIndex");

                            //XXXXXXXXX: this should be this, not placehilderInsertConfirmedCall --- CHECK!
                            print("NEW!!!!");
                            Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);
                            print(chipInsertConfirmed.data);

                            print("DEBUG - closing lid section");

                            //Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            //print(placeholderInsertConfirmed2.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Closing lid...";
                              showIndicator = true;
                            });

                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid closing...");
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Ready to swap cartridge";
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 2) {

                            setState(() {});

                            setStates(() {
                              contentText = "Lowering cartridge";
                              print("DEBUG - increment 1");
                              showIndicator = true;
                            });

                            //pendinganswer now
                            Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);
                            print(response.data);
                          
                            while(! await isAnswerPending(sessionID)) {
                              await Future.delayed(Duration(milliseconds: 500));
                              print("waiting");
                            } 

                            //won't update content text if not present
                            setState(() {});

                            setStates(() {
                              contentText = "Please remove cartridge";
                              print("DEBUG - increment 1");
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 3) {


                            Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);
                            print(response.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Please insert new cartridge";
                              print("DEBUG - increment 2");
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 4) {

                            Result response = await cartridgeInsertConfirmedCall(sessionID, runID);
                            print(response.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Moving cartridge up";
                              print("DEBUG - increment 3");
                              showIndicator = true;
                            });
 
                            while(! await isCartridgePositionClosed(sessionID)) {
                              await Future.delayed(Duration(milliseconds: 1000));
                              print("waiting");
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Cleaning";
                              print("DEBUG - increment 3");
                              showIndicator = true;
                            });

                            bool firstime = true;
                            int totaltime = 0;

                            while(true) {
                              Result initResponse = await initCall(sessionID);

                              String status = initResponse.data['status']['currentState']['mode'];

                              if(status == 'working') {
                                
                                double rtdouble = initResponse.data['status']['currentRemainingTime']/1000/60;

                                int remainingtime = rtdouble.floor();

                                if(firstime) {
                                  totaltime = remainingtime;
                                  firstime = false;
                                }

                                setState(() {});

                                String rt = remainingtime.toString();

                                setStates(() {
                                  //progressindicator!.value=0.0;
                                  print("Cleaning - $rt minutes left");
                                  contentText = "Cleaning - $rt minutes to go";
                                  //showIndicator = true;
                                });

                              } else { break; }
                              
                              await Future.delayed(Duration(milliseconds: 30000));
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Cleaning done";
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });
                          
                           } else if (currentTextIndex == 5) {

                            setStates(() {
                              contentText = "Finishing up cleaning";
                              showIndicator = true;
                            });
                            
                            print("confirmEndProcessCartridgeDownCall 1");
                            Result placeholderInsertConfirmed = await confirmEndProcessCartridgeDownCall(sessionID, runID);

                            print(placeholderInsertConfirmed.data);

                            await Future.delayed(Duration(milliseconds: 10000));

                            print("confirmEndProcessCartridgeDownCall 2");
                            Result placeholderInsertConfirmed2 = await confirmEndProcessCartridgeDownCall(sessionID, runID);

                            print(placeholderInsertConfirmed2.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Open lid";
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 6) {

                            setState(() {});

                            setStates(() {
                              contentText = "Opening lid...";
                              showIndicator = true;
                            });

                            Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed.data);

                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid opening...");
                            }

                            if(await isLidOpen(sessionID)) {
                              print("DEBUG - Lid is open");
                            } else {
                              //undefined state
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Please remove chip and vial and insert placeholder";
                              print("DEBUG - increment 1");
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 7) {

                            print("DEBUG - currentTextIndex is $currentTextIndex");

                            //Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);

                            print("DEBUG - closing lid section");

                            Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed2.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Closing lid...";
                              showIndicator = true;
                            });

                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid closing...");
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Ready to remove cartridge";
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 8) {

                            setState(() {});

                            setStates(() {
                              contentText = "Lowering cartridge";
                              print("DEBUG - increment 1");
                              showIndicator = true;
                            });

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
                              currentTextIndex = (currentTextIndex + 1);
                              showIndicator = false;
                            });


                            } else if (currentTextIndex == 9) {

                              Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);

                              Navigator.pop(context);  


                          } else if (currentTextIndex == 10) {

                            print("DEBUG - currentTextIndex is $currentTextIndex");

                            Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);

                            //print(confirmEndProcessCallResult.data);

                            Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);

                            //print(placeholderInsertConfirmed.data);
                            
                            Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            //print(placeholderInsertConfirmed2.data);

                            print("DEBUG - about to open lid");

                            //won't update content text if not present
                            setState(() {});

                            setStates(() {
                              contentText = "Opening lid...";
                              showIndicator = true;
                            });


                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid opening...");
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Please remove vial and replace chip with placeholder";
                              print("DEBUG - increment 3");
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 11) {
                            print("DEBUG - currentTextIndex is $currentTextIndex");

                            //Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);

                            print("DEBUG - closing lid section");

                            Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed2.data);

                            setState(() {});

                            setStates(() {
                              contentText = "Closing lid...";
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = true;
                            });

                            while(true) {
                              
                              await Future.delayed(Duration(milliseconds: 2000));

                              if(!await isLidMoving(sessionID)) {
                                break;
                              }

                              print("DEBUG - lid closing...");
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

  void _showNetworkDialog(BuildContext context, SharedPreferences prefs) {

    var KBIPController = TextEditingController();
    var KBUserController = TextEditingController();
    var KBPassController = TextEditingController();
    var MinionIPController = TextEditingController();
    var MinionUserController = TextEditingController();
    var MinionPassController = TextEditingController();

    MinionIPController.text = prefs.getString('minionip') ?? '192.192.192.1';
    MinionUserController.text = prefs.getString('minionuser') ?? 'minit';
    MinionPassController.text = prefs.getString('minionpass') ?? 'minit';
    KBIPController.text = prefs.getString('kbip') ?? '192.192.192.2';
    KBUserController.text = prefs.getString('kbuser') ?? 'test';
    KBPassController.text = prefs.getString('kbpass') ?? 'test';
    
    showDialog(
      context: context,
      builder: (context) {

        String titleText = "Configure devices";

        MaskedTextField kilobaserip = MaskedTextField(
          textFieldController: KBIPController,
          inputDecoration: const InputDecoration(
            hintText: '192.192.192.192',
            counterText: ""
          ),
          autofocus: true,
          mask: 'xxx.xxx.xxx.xxx',
          maxLength: 30,
          keyboardType: TextInputType.number,
          onChange: (String value) {},
        );

        MaskedTextField kilobaseruser = MaskedTextField(
          textFieldController: KBUserController,
          inputDecoration: const InputDecoration(
            counterText: ""
          ),
          autofocus: true,
          maxLength: 30,
          mask: '',
          keyboardType: TextInputType.text,
          onChange: (String value) {},
        );

        MaskedTextField kilobaserpass = MaskedTextField(
          textFieldController: KBPassController,
          inputDecoration: const InputDecoration(
            counterText: ""
          ),
          autofocus: true,
          maxLength: 30,
          mask: '',
          keyboardType: TextInputType.text,
          onChange: (String value) {},
        );

        MaskedTextField minionip = MaskedTextField(
          textFieldController: MinionIPController,
          inputDecoration: const InputDecoration(
            hintText: '192.192.192.192',
            counterText: ""
          ),
          autofocus: true,
          mask: 'xxx.xxx.xxx.xxx',
          maxLength: 30,
          keyboardType: TextInputType.number,
          onChange: (String value) {},
        );

        MaskedTextField minionuser = MaskedTextField(
          textFieldController: MinionUserController,
          inputDecoration: const InputDecoration(
            counterText: ""
          ),
          autofocus: true,
          mask: '',
          maxLength: 30,
          keyboardType: TextInputType.text,
          onChange: (String value) {},
        );

        MaskedTextField minionpass = MaskedTextField(
          textFieldController: MinionPassController,
          inputDecoration: const InputDecoration(
            counterText: ""
          ),
          autofocus: true,
          mask: '',
          maxLength: 30,
          keyboardType: TextInputType.text,
          onChange: (String value) {},
        );

        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return AlertDialog(
              title: Text(titleText),
              content: SizedBox(
                height: 500,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Kilobaser IP Address"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: kilobaserip
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Kilobaser Username"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: kilobaseruser
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Kilobaser Password"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: kilobaserpass
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("MinION IP Address"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: minionip
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("MinION Username"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: minionuser
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("MinION Password"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: minionpass
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
                          child: Text('Close')
                        ),
                      
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton(
                          onPressed: () { 
                            prefs.setString('minionip', MinionIPController.text);
                            prefs.setString('minionuser', MinionUserController.text);
                            prefs.setString('minionpass', MinionPassController.text);
                            prefs.setString('kbip', KBIPController.text);
                            prefs.setString('kbuser', KBUserController.text);
                            prefs.setString('kbpass', KBPassController.text);
                            Navigator.pop(context); 
                          },
                          child: Text('Save')
                        ),
                      
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: StatefulBuilder(builder: (context, StateSetter setStates) {
                          return InkWell(
                            onTap: () async {

                              print("configuring network");

                              setState(() {});

                              setStates(() {
                                showIndicator = true;
                              });

                              //String subnetont = '169.254.26';
                              String subnetont = '169.254.';

                              //looking for Minion
                              
                              //assumption: only one device will be found
                              var minionip = "";

                              for (var i = 0; i < 256; i++) {

                                print(subnetont+i.toString());

                                var minionstream = NetworkDiscovery.discover(subnetont+i.toString(), 22); 

                                await minionstream.listen((NetworkAddress addr) {
                                  minionip = addr.ip.toString();
                                  print('Found MinION: ${addr.ip}');
                                }).asFuture();

                                print(minionip);

                                if(minionip.isNotEmpty) {
                                  MinionIPController.text = minionip;
                                  KBIPController.text = '196.168.1.23';
                                  break;
                                }
                              }       

                              String subnetkb = '169.254.26';

                              //looking for Kilobaser
                              final kilobaserstream = NetworkDiscovery.discover(subnetkb, 80); 

                              var kilobaserip = "";
                              kilobaserstream.listen((NetworkAddress addr) {
                                kilobaserip = addr.ip.toString();
                                print('Found Kilobaser: ${addr.ip}');
                              }).onDone(() => KBIPController.text = kilobaserip);

                              print("done configuring network");

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

  void _showLoggingDialog(BuildContext context, SharedPreferences prefs) {

    var LogLocationController = TextEditingController();

    const List<String> list = <String>['OFF', 'SHOUT', 'SEVERE', 'WARNING', 'INFO'];

    String dropdownValue = prefs.getString('loglevel') ?? 'OFF';
    LogLocationController.text = prefs.getString('loglocation') ?? '';
    
    showDialog(
      context: context,
      builder: (context) {

        String titleText = "Configure logging";

        DropdownMenu loglevel = DropdownMenu<String>(
          initialSelection: dropdownValue,
            onSelected: (String? value) {
              // This is called when the user selects an item.
              print(value);
              setState(() {
              dropdownValue = value!;
            });
            },
            dropdownMenuEntries: list.map<DropdownMenuEntry<String>>((String value) {
            return DropdownMenuEntry<String>(value: value, label: value);
          }).toList(),
        );

        MaskedTextField loglocation = MaskedTextField(
          textFieldController: LogLocationController,
          inputDecoration: const InputDecoration(
            counterText: ""
          ),
          autofocus: true,
          maxLength: 15,
          mask: '',
          keyboardType: TextInputType.text,
          onChange: (String value) {},
        );

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
                        child: Text("Log level"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0)
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: loglevel,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        child: Text("Log file location"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: loglocation
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
                          child: Text('Close')
                        ),
                      
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton(
                          onPressed: () { 
                            prefs.setString('loglevel', dropdownValue);
                            prefs.setString('loglocation', LogLocationController.text);
                            Navigator.pop(context); 
                          },
                          child: Text('Save')
                        ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton(
                          onPressed: () async { 
                            
                            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

                            if (selectedDirectory != null) {
                              LogLocationController.text = selectedDirectory;
                            }
                          },
                          child: Text('Pick directoy')
                        ),
                    ),
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {

                      final prefs = await SharedPreferences.getInstance();

                      _showNetworkDialog(context, prefs);

                    },
                    child: Text('Configure Access'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {

                      final prefs = await SharedPreferences.getInstance();

                      _showLoggingDialog(context, prefs);

                    },
                    child: Text('Configure logging'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {

                      _showCleaningDialog(context);

                    },
                    child: Text('Clean device'),
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