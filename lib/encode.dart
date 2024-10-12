import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'comms.dart';
import 'dart:math';
import 'package:file/local.dart';
import 'package:shell/shell.dart';

final Random random = Random();
TextEditingController dna = TextEditingController();

String generateRandomString(chars, int length) =>
    Iterable.generate(length, (idx) => chars[random.nextInt(chars.length)])
        .join();

class EncodingPage extends StatefulWidget {
  @override
  _EncodingPageState createState() => _EncodingPageState();
}

class _EncodingPageState extends State<EncodingPage> with TickerProviderStateMixin {
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

  List<String> buttonTexts = ['Start', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm', 'Confirm'];
  int currentTextIndex = 0;
  bool showIndicator = false;
  late String sessionID;
  late var runID;


  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Writing Data";
        String contentText = "Make sure chip and cartridge are ready";

        bool swapcartridge = false;
        bool initcartridge = false;
        bool insertcartridge = false;
        bool demomode = false;


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
                    //showIndicator
                    //    ? progressindicator
                    //    : Text('')
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

                            print(dna.text);

                            final String synthesisName = DateTime.now().toString();

                            print("synthesisName: $synthesisName");

                            //AGTGTCTG
                            //AGTGTCTGTGACCAGTACGACCCAGTACCGTCACGGTTAGGAATCAGCACGGTTCTGTCCCGCGCAGCAACTATTTCGCCGCGCCGCCGGCTCGACTCGGCCAAGTGTCTGTGAAGTGTCTGTGAAGTGTCTGTGAAGT
                            addSynthesis(sessionID, "AGTGTCTGTGACCAGTACGACCCAGTACCGTCACGGTTAGGAATCAGCACGGTTCTGTCCCGCGCAGCAACTATTTCGCCGCGCCGCCGGCTCGACTCGGCCAAGTGTCTGTGAAGTGTCTGTGAAGTGTCTGTGAAGT", synthesisName);

                            Result initResponse = await initCall(sessionID);

                            print(initResponse.data['processRunQueue'].length);

                            while(initResponse.data['processRunQueue'].length == 0) {
                              await Future.delayed(Duration(milliseconds: 500));
                              initResponse = await initCall(sessionID);
                              print("waiting");
                            } 

                            int ptl = initResponse.data['processRunQueue'][0]['processTypes'].length;
                            print(initResponse.data['processRunQueue'][0]['processTypes']);

                            //XXX: currently we distinguish between the length/number of processtypes - should be made more robuts
                            if(ptl == 6) {
                              //no cartridge after cleaning -> initcartridge

                              initcartridge = true;

                              print("Init cartridge");

                            } else if (ptl == 5) {
                              //cartridge in -> swap cartridge

                              swapcartridge = true;

                              print("Swap cartridge");

                            } else if (ptl == 4) {
                              //no cartridge -> insert cartridge

                              insertcartridge = true;

                              print("Insert cartridge");

                            } else if (ptl == 2) {

                              demomode = true;

                              print("Demo mode");

                            } else {
                              //XXX: undefined

                            }                         

                            runID  = initResponse.data['processRunQueue'][0]['id'];

                            print("DEBUG - Init done");

                            print("DEBUG - currentTextIndex is $currentTextIndex");

                            Result runResponse = await processRunCall(sessionID, runID);
              
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
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });


                          } else if (currentTextIndex > 0) {

                            if(initcartridge) {

                              if (currentTextIndex == 1) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setStates(() {
                                  contentText = "Closing lid";
                                  showIndicator = true;
                                });

                                Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);
                                print(chipInsertConfirmed.data);

                                while(true) {
                              
                                  await Future.delayed(Duration(milliseconds: 2000));

                                  if(!await isLidMoving(sessionID)) {
                                    break;
                                  }   

                                  print("DEBUG - lid closing...");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Flushing";
                                });

                                await Future.delayed(Duration(milliseconds: 5000));

                                while(true) {
                                  Result initResponse = await initCall(sessionID);

                                  String status = initResponse.data['status']['currentState']['mode'];

                                  if(status == 'working' || status == 'synthesis' || status == 'cleaving' || status == 'drying') {

                                  } else { break; }
                              
                                  await Future.delayed(Duration(milliseconds: 30000));
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Insert cartridge";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 2) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Moving cartridge up";
                                  showIndicator = true;
                                });

                                Result cartridgeInsertConfirmed = await cartridgeInsertConfirmedCall(sessionID, runID);
                                print(cartridgeInsertConfirmed.data);

                                while(! await isCartridgePositionClosed(sessionID)) {
                                  await Future.delayed(Duration(milliseconds: 1000));
                                  print("waiting");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Initialising cartridge";
                                  showIndicator = true;
                                });

                                //initcartridge start

                                bool firstime = true;
                                int totaltime = 0;

                                while(true) {
                                  Result initResponse = await initCall(sessionID);

                                  String status = initResponse.data['status']['currentState']['mode'];

                                  if(status == 'working' || status == 'synthesis' || status == 'cleaving' || status == 'drying') {
                                
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
                                      print("Initialising - $rt minutes to go");
                                      contentText = "Initialising - $rt minutes to go";
                                      //showIndicator = true;
                                    });

                                  } else { break; }
                              
                                  await Future.delayed(Duration(milliseconds: 30000));
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Cartridge initialisation done";
                                  showIndicator = false;
                                  currentTextIndex = currentTextIndex + 1;
                                });

                              } else if (currentTextIndex == 3) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Opening lid...";
                                  showIndicator = true;
                                });

                                Result skipRemoveAndStartNextRunResult = await skipRemoveAndStartNextRunCall(sessionID, runID);
                                print(skipRemoveAndStartNextRunResult.data);

                                await Future.delayed(Duration(milliseconds: 5000));

                                Result skipRemoveAndStartNextRunResult2 = await skipRemoveAndStartNextRunCall(sessionID, runID);
                                print(skipRemoveAndStartNextRunResult2.data);

                                print("DEBUG - about to open lid");

                                while(true) {
                              
                                  await Future.delayed(Duration(milliseconds: 2000));

                                  if(!await isLidMoving(sessionID)) {
                                    break;
                                  }

                                  print("DEBUG - lid opening...");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Please replace vial and chip";
                                  print("DEBUG - increment 3");
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 4) {

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

                                //synthesis start
                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesising";
                                });

                                bool firstime = true;
                                int totaltime = 0;

                                while(true) {
                                  Result initResponse = await initCall(sessionID);

                                  String status = "";
                                  double rtdouble = -1.0;

                                  try { 
                                    status = initResponse.data['status']['currentState']['mode'];
                                    rtdouble = initResponse.data['status']['currentRemainingTime']/1000/60;
                                  } catch (e) {
                                    status = "initfailed";
                                    print('Something really unknown: $e');
                                  }

                                  if(status == "initfailed" || status == 'working' || status == 'synthesis' || status == 'cleaving' || status == 'drying') {

                                    int remainingtime = rtdouble.floor();

                                    if(firstime) {
                                      totaltime = remainingtime;
                                      firstime = false;
                                    }

                                    setState(() {});

                                    String rt = remainingtime.toString();

                                    setStates(() {
                                      //progressindicator!.value=0.0;
                                      print("Synthesising - $rt minutes to go");
                                      contentText = "Synthesising - $rt minutes to go";
                                      //showIndicator = true;
                                    });

                                  } else { break; }
                              
                                  await Future.delayed(Duration(milliseconds: 30000));
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesis done";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 5) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Opening lid...";
                                  showIndicator = true;
                                });

                                try {
                                  Result initResponse = await initCall(sessionID);
                                  print(initResponse.data);
                                } catch (e) {
                                    print('Something really unknown: $e');
                                }

                                Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);
                                print(confirmEndProcessCallResult.data);

                                await Future.delayed(Duration(milliseconds: 2000));

                                Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed.data);

                                await Future.delayed(Duration(milliseconds: 2000));
                            
                                Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed2.data);

                                print("DEBUG - about to open lid");

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
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 6) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

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

                              Navigator.pop(context);

                              } else {

                                print("DEBUG - undefined currentTextIndex with $currentTextIndex");

                              }
                            }

                            if(insertcartridge) {

                              if (currentTextIndex == 1) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setStates(() {
                                  contentText = "Closing lid";
                                  showIndicator = true;
                                });

                                Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);
                                print(chipInsertConfirmed.data);

                                while(true) {
                              
                                  await Future.delayed(Duration(milliseconds: 2000));

                                  if(!await isLidMoving(sessionID)) {
                                    break;
                                  }   

                                  print("DEBUG - lid closing...");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Insert cartridge";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 2) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Moving cartridge up";
                                  showIndicator = true;
                                });

                                Result cartridgeInsertConfirmed = await cartridgeInsertConfirmedCall(sessionID, runID);
                                print(cartridgeInsertConfirmed.data);

                                while(! await isCartridgePositionClosed(sessionID)) {
                                  await Future.delayed(Duration(milliseconds: 1000));
                                  print("waiting");
                                }

                                //synthesis start
                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesising";
                                });

                                bool firstime = true;
                                int totaltime = 0;

                                while(true) {

                                  Result initResponse = await initCall(sessionID);

                                  String status = "";
                                  double rtdouble = -1.0;

                                  try { 
                                    status = initResponse.data['status']['currentState']['mode'];
                                    rtdouble = initResponse.data['status']['currentRemainingTime']/1000/60;
                                  } catch (e) {
                                    status = "initfailed";
                                    print('Something really unknown: $e');
                                  }

                                  if(status == "initfailed" || status == 'working' || status == 'synthesis' || status == 'cleaving' || status == 'drying') {

                                    int remainingtime = rtdouble.floor();

                                    if(firstime) {
                                      totaltime = remainingtime;
                                      firstime = false;
                                    }

                                    setState(() {});

                                    String rt = remainingtime.toString();

                                    setStates(() {
                                      //progressindicator!.value=0.0;
                                      print("Synthesising - $rt minutes to go");
                                      contentText = "Synthesising - $rt minutes to go";
                                      //showIndicator = true;
                                    });

                                  } else { break; }
                              
                                  await Future.delayed(Duration(milliseconds: 30000));
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesis done";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 3) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Opening lid...";
                                  showIndicator = true;
                                });

                                Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);
                                print(confirmEndProcessCallResult.data);

                                Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed.data);
                            
                                Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed2.data);

                                print("DEBUG - about to open lid");

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
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 4) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

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

                              Navigator.pop(context);

                              } else {

                                print("DEBUG - undefined currentTextIndex with $currentTextIndex");

                              }
                            }

                            if(swapcartridge) {

                              if (currentTextIndex == 1) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setStates(() {
                                  contentText = "Closing lid";
                                  showIndicator = true;
                                });

                                Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);
                                print(chipInsertConfirmed.data);

                                while(true) {
                              
                                  await Future.delayed(Duration(milliseconds: 2000));

                                  if(!await isLidMoving(sessionID)) {
                                    break;
                                  }   

                                  print("DEBUG - lid closing...");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Eject old cartridge";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 2) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Lowering cartridge";
                                  showIndicator = true;
                                });

                                //pendinganswer now
                                Result response = await confirmReadyForCartridgeDownCall(sessionID, runID);
                          
                                while(! await isAnswerPending(sessionID)) {
                                  await Future.delayed(Duration(milliseconds: 500));
                                  print("waiting");
                                } 

                                setState(() {});

                                setStates(() {
                                  contentText = "Please remove cartridge";
                                  currentTextIndex = (currentTextIndex + 1);
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 3) {

                                setStates(() {
                                  showIndicator = true;
                                });

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

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Moving cartridge up";
                                  showIndicator = true;
                                });

                                Result cartridgeInsertConfirmed = await cartridgeInsertConfirmedCall(sessionID, runID);
                                print(cartridgeInsertConfirmed.data);

                                while(! await isCartridgePositionClosed(sessionID)) {
                                  await Future.delayed(Duration(milliseconds: 1000));
                                  print("waiting");
                                }

                                //synthesis start
                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesising";
                                });

                                bool firstime = true;
                                int totaltime = 0;

                                while(true) {
                                  Result initResponse = await initCall(sessionID);

                                  String status = "";
                                  double rtdouble = -1.0;

                                  try { 
                                    status = initResponse.data['status']['currentState']['mode'];
                                    rtdouble = initResponse.data['status']['currentRemainingTime']/1000/60;
                                  } catch (e) {
                                    status = "initfailed";
                                    print('Something really unknown: $e');
                                  }

                                  if(status == "initfailed" || status == 'working' || status == 'synthesis' || status == 'cleaving' || status == 'drying') {

                                    int remainingtime = rtdouble.floor();

                                    if(firstime) {
                                      totaltime = remainingtime;
                                      firstime = false;
                                    }

                                    setState(() {});

                                    String rt = remainingtime.toString();

                                    setStates(() {
                                      //progressindicator!.value=0.0;
                                      print("Synthesising - $rt minutes to go");
                                      contentText = "Synthesising - $rt minutes to go";
                                      //showIndicator = true;
                                    });

                                  } else { break; }
                              
                                  await Future.delayed(Duration(milliseconds: 30000));
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Synthesis done";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 5) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Opening lid...";
                                  showIndicator = true;
                                });

                                Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);
                                print(confirmEndProcessCallResult.data);

                                await Future.delayed(Duration(milliseconds: 2000));

                                Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed.data);

                                await Future.delayed(Duration(milliseconds: 2000));
                            
                                Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed2.data);

                                print("DEBUG - about to open lid");

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
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 6) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                print("DEBUG - closing lid section");

                                setState(() {});

                                setStates(() {
                                  contentText = "Closing lid...";
                                  showIndicator = true;
                                });

                                Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed2.data);

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
                            }

                            if(demomode) {

                              if (currentTextIndex == 1) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Closing lid";
                                  showIndicator = true;
                                });

                                Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);
                                print(chipInsertConfirmed.data);

                                while(true) {
                              
                                  await Future.delayed(Duration(milliseconds: 2000));

                                  if(!await isLidMoving(sessionID)) {
                                    break;
                                  }   

                                  print("DEBUG - lid closing...");
                                }

                                setState(() {});

                                setStates(() {
                                  contentText = "Finished synthesis";
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 2) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

                                setState(() {});

                                setStates(() {
                                  contentText = "Opening lid...";
                                  showIndicator = true;
                                });

                                Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);
                                print(confirmEndProcessCallResult.data);

                                Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed.data);
                            
                                Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);
                                print(placeholderInsertConfirmed2.data);

                                print("DEBUG - about to open lid");

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
                                  currentTextIndex = currentTextIndex + 1;
                                  showIndicator = false;
                                });

                              } else if (currentTextIndex == 3) {

                                print("DEBUG - currentTextIndex is $currentTextIndex");

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

                              Navigator.pop(context);

                              } else {

                                print("DEBUG - undefined currentTextIndex with $currentTextIndex");

                              }
                            }
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

  final RoundedLoadingButtonController _btnController1 =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    _btnController1.stateStream.listen((value) {
      print(value);
    });
  }

  Widget build(BuildContext context) {
    TextEditingController input = TextEditingController();

    return Scaffold(
      //appBar: AppBar(
      //  title: Text("Encode to DNA & Synthesise"),
      //  backgroundColor: Colors.blue,
      //),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  'Input Data',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500,
                      fontSize: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: input,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: "Enter Text",
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(width: 1, color: Colors.blueAccent))),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  'Encoded Data',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500,
                      fontSize: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: dna,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: "Resulting DNA",
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(width: 1, color: Colors.blueAccent))),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      //dna.text = generateRandomString('ATCG', 140);

                      var shell = new Shell();
                      var pwd = await shell.startAndReadAsString('python', arguments: ['c:/users/omers/dnd/encodeData.py', '--stringData', input.text]);
                      print('cwd: $pwd');
                      dna.text = pwd;

                      print('encode pressed!');
                    },
                    child: Text('Encode'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      _showDialog(context);

                      //XXX: this is where the START button should be enabled when done
                    },
                    child: Text('Synthesise'),
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