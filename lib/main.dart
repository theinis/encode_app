import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:math';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
//import 'dart:convert';

late IRestApiClient restApiClient;

Future<String> loginCall() async {
  Result response = await restApiClient.post(
    '/api/login',
    data: {'username': 'test', 'password': 'test'},
  );

  return response.data['id'];
}

Future<String> checkLidState(var sessionID) async {
  Result response = initCall(sessionID) as Result;

  return response.data['id'];
}

Future<Result> initCall(var sessionID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  Result response = await restApiClient.get(
    '/api/init',
    options: options,
  );

  return response;
}

addSynthesis(var sessionID, var sequence, var name) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var seq = {'sequence': sequence};
  var data = {
      "answers": seq,
      "cartridgeType": "2",
      "chipKind": "2",
      "priority": 0,
      "processType": "synthesis",
      "title": name
  };

  //make more robust with specific, time based ID for title
  Result response = await restApiClient.post(
    '/api/processRuns/queue',
    options: options,
    data: data,
  );

/*
    curl -X 'POST' \
    --insecure \
    -b ./kbcookies.txt  \
    'https://${KILOBASERIP}:8443/api/processRuns/queue' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
      "answers": {
        "sequence": "AGCTAGCT"
      },
      "cartridgeType": "2",
      "chipKind": "2",
      "priority": 0,
      "processType": "synthesis",
      "title": "test synthesis"
    }'
*/
}

Future<Result> processRunCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  Result response = await restApiClient.post(
    '/api/processRuns',
    options: options,
    data: {'id': runID},
  );

  return response;
}

Future<Result> openLidCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'lidClosed': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}

Future<Result> confirmEndProcessCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'confirmEndProcess': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}

Future<Result> placeholderInsertConfirmedCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'placeholderInsertConfirmed': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}

Future<Result> chipInsertConfirmedCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'chipInsertConfirmed': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}


Future<Result> changeCartridgeConfirmCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'lidClosed': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}

Future<Result> cartridgeDownCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'cartridgeDown': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}

void main() async {
  await RestApiClient.initFlutter();

  restApiClient = RestApiClient(
    options: RestApiClientOptions(
      //Defines your base API url eg. https://mybestrestapi.com
      //baseUrl: 'https://169.254.73.31:443/',
      baseUrl: 'https://169.254.57.42:443/',
      //baseUrl: 'https://enmj2r4tawo3p.x.pipedream.net:443/',
      //Enable caching of response data
      cacheEnabled: true,
    ),
    loggingOptions: LoggingOptions(
      //Toggle logging of your requests and responses
      //to the console while debugging
      logNetworkTraffic: true,
    ),
  );

  //init must be called, preferably right after the instantiation
  await restApiClient.init();

  runApp(MyApp());
}

final Random random = Random();

String generateRandomString(chars, int length) =>
    Iterable.generate(length, (idx) => chars[random.nextInt(chars.length)])
        .join();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'DNA Storage App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Write"),
                Tab(text: "Read"),
                Tab(text: "Debug"),
              ],
            ),
            title: const Text('DNA Storage App'),
          ),
          body: TabBarView(
            children: [
              EncodingPage(),
              Icon(Icons.directions_car),
              DebugPage(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class EncodingPage extends StatefulWidget {
  @override
  _EncodingPageState createState() => _EncodingPageState();
}

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

  List<String> buttonTexts = ['Click Here', 'Confirm', 'Button Text 3'];
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

                      String sessionID = await loginCall();

                      print("finished call");

                      print(sessionID);

                      print('button pressed!');

                      addSynthesis(sessionID, 'TTTTTTTT', 'synthesis');

                      Result initResponse = await initCall(sessionID);

                      var runID  = initResponse.data['processRunQueue'][0]['id'];

                      print(initResponse.data['processRunQueue'][0]['id']);

                      //start process and wait for user interaction
                      
                      Result runResponse = await processRunCall(sessionID, runID);
              
                      print(runResponse.data);

                      Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);

                      print(placeholderInsertConfirmed.data);

                      Result initResponse2 = await initCall(sessionID);

                      print(initResponse2.data);

                      //Result cartridgeDownResponse = await cartridgeDownCall(sessionID, runID);

                      //print(cartridgeDownResponse.data);
/*
                      Result openLidResponse = await openLidCall(sessionID, runID);

                      print(openLidResponse.data);
*/                      
                    },
                    child: Text('Do stuff'),
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

  List<String> buttonTexts = ['Start', 'Confirm', 'Confirm', 'Confirm', 'Confirm'];
  int currentTextIndex = 0;
  bool showIndicator = false;
  late String sessionID;
  late var runID;

  Future<void> _doSomething() async {}
  // void _doSomething() async {

  // }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Writing Data";
        String contentText = "Make sure chip and cartridge are ready";

        LinearProgressIndicator progressindicator = LinearProgressIndicator(value: 1.0,
                          backgroundColor: Colors.orangeAccent,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                          minHeight: 8,
                        );


        //AlertDialog dialog = 
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
                              Result initResponse = await initCall(sessionID);

                              if(initResponse.data['status']['pendingAnswers'] != null && initResponse.data['status']['pendingAnswers'][0] == 'chipInsertConfirmed') {
                                print(currentTextIndex);
                                break;
                              }

                              await Future.delayed(Duration(milliseconds: 2000));
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Please make sure chip and vial are inserted";
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });
                          } else if (currentTextIndex == 1) {

                            Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);

                            print(chipInsertConfirmed.data);

                            //synthesis start
                            setState(() {});

                            setStates(() {
                              contentText = "Synthesising";
                              showIndicator = true;
                            });

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
                              showIndicator = false;
                            });

                            setStates(() {
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                            });

                          } else if (currentTextIndex == 2) {

                            Result confirmEndProcessCallResult = await confirmEndProcessCall(sessionID, runID);

                            print(confirmEndProcessCallResult.data);

                            Result placeholderInsertConfirmed = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed.data);
                            
                            Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed2.data);

                            //won't update content text if not present
                            setState(() {});

                            setStates(() {
                              contentText = "Opening lid...";
                              showIndicator = true;
                            });

                            while(true) {
                              Result initResponse2 = await initCall(sessionID);

                              print("Opening lid...");

                              if(initResponse2.data['status']['pendingAnswers'] != null) {
                                print(initResponse2.data['status']['pendingAnswers']);
                              } else {
                                print("no pending answers");
                                break;
                              }

                              if(initResponse2.data['status']['pendingAnswers'] != null && initResponse2.data['status']['pendingAnswers'][0] == 'chipInsertConfirmed') {
                                print(currentTextIndex);
                                break;
                              }

                              await Future.delayed(Duration(milliseconds: 1000));
                            }

                            setState(() {});

                            setStates(() {
                              contentText = "Please remove vial and replace chip with placeholder";
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });

                          } else if (currentTextIndex == 2) {

                            //Result chipInsertConfirmed = await chipInsertConfirmedCall(sessionID, runID);

                            Result placeholderInsertConfirmed2 = await placeholderInsertConfirmedCall(sessionID, runID);

                            print(placeholderInsertConfirmed2.data);

                            setStates(() {
                              contentText = "Closing lid...";
                              currentTextIndex = (currentTextIndex + 1) % buttonTexts.length;
                              showIndicator = false;
                            });

                          } else {

                            print("Undefined currentTextIndex with $currentTextIndex");

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
    TextEditingController dna = TextEditingController();

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
                    onPressed: () {
                      dna.text = generateRandomString('ATCG', 70);
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

                      sessionID = await loginCall();

                      final String synthesisName = DateTime.now().toString();

                      addSynthesis(sessionID, 'ATCGATCG', synthesisName);

                      Result initResponse = await initCall(sessionID);

                      runID  = initResponse.data['processRunQueue'][0]['id'];
  
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