import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:math';
import 'dart:async';

import 'package:rounded_loading_button/rounded_loading_button.dart';
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

addSynthesis(var sessionID, var sequence) async {
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
      "title": "test synthesis"
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
      baseUrl: 'https://169.254.113.178:443/',
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
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
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

  List<String> buttonTexts = ['Click Here', 'Button Text 2', 'Button Text 3'];
  int currentTextIndex = 0;
  bool showIndicator = false;

  Future<void> _doSomething() async {}
  // void _doSomething() async {

  // }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String contentText = "Content of Dialog";
        String titleText = "Writing Data";
        String buttonText = "Open Lid";

        AlertDialog dialog = AlertDialog(
          title: Text(titleText),
          content: Text(contentText),
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
                        setStates(() {
                          showIndicator = true;
                        });

                        await Future.delayed(Duration(milliseconds: 900));

                        setStates(() {
                          currentTextIndex =
                              (currentTextIndex + 1) % buttonTexts.length;
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
                                  buttonTexts[currentTextIndex],
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ));
                }),
                //  RoundedLoadingButton(
                //     elevation: 0,
                //     width: 100,
                //     color: Colors.blue,
                //     successColor: Colors.blue,
                //     successIcon: Icons.check,
                //     failedIcon: Icons.cottage,
                //     height: 40,
                //     borderRadius: 20,
                //     duration: Duration(milliseconds: 900),
                // child: Text(buttonTexts[currentTextIndex],
                //     style: TextStyle(color: Colors.white)),
                //     controller: _btnController1,
                //     onPressed: () {
                //       _doSomething();
                //       // Navigator.pop(context);
                //     }),
                //)
              ],
            ),
            // PhysicalModel(
            //   color: Colors.lightGreen,
            //   borderRadius: BorderRadius.circular(25.0),
            //   child: MaterialButton(
            //     onPressed: () {
            //       setState(() {
            //         if (_state == 0) {
            //           print(_state);
            //           animateButton();
            //         }
            //       });
            //     },
            //     child: setUpButtonChild(),
            //   ),
            // ),
          ],
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return dialog;
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
      appBar: AppBar(
        title: Text("Encode to DNA & Synthesise"),
        backgroundColor: Colors.blue,
      ),
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
                      dna.text = generateRandomString('ATCG', 100);
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

                      //Result loginResponse = 

                      String sessionID = await loginCall();

                      print("finished call");

                      print(sessionID);

                      print('button pressed!');

                      addSynthesis(sessionID, 'TTTTTTTT');


                      Result initResponse = await initCall(sessionID);

                      var runID  = initResponse.data['processRunQueue'][0]['id'];

                      print(initResponse.data['processRunQueue'][0]['id']);

                      //start process and wait for user interaction
                      Result runResponse = await processRunCall(sessionID, runID);
                      
                      print(runResponse.data);

                      Result cartridgeDownResponse = await cartridgeDownCall(sessionID, runID);

                      print(cartridgeDownResponse.data);
/*
                      Result openLidResponse = await openLidCall(sessionID, runID);

                      print(openLidResponse.data);
*/                      
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