import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'dart:math';
import 'dart:convert';

late IRestApiClient restApiClient;

Future<Result> loginCall() async {

  Result response = await restApiClient.post(
    '/api/login',
    data: {'username': 'test', 'password': 'test'},
  );
  
  return response; 
}

Future<Result> initCall(var sessionID) async {

  RestApiClientRequestOptions options = RestApiClientRequestOptions(
    headers: {
      'cookie': 'session='+sessionID,
    }
  );

  Result response = await restApiClient.get(
    '/api/init',
    options: options,
  );
  
  return response; 
}

Future<Result> processRunCall(var sessionID, var runID) async {

  RestApiClientRequestOptions options = RestApiClientRequestOptions(
    headers: {
      'cookie': 'session='+sessionID,
    }
  );

  Result response = await restApiClient.post(
    '/api/processRuns',
    options: options,
    data: { 'id': runID },
  );
  
  return response; 
}

Future<Result> openLidCall(var sessionID, var runID) async {

  RestApiClientRequestOptions options = RestApiClientRequestOptions(
    headers: {
      'cookie': 'session='+sessionID,
    }
  );

  var answer = {'lidClosed': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: { 'answers': answer },
  );
  
  return response; 
}

void main() async {

  await RestApiClient.initFlutter();

  restApiClient = RestApiClient(
    options: RestApiClientOptions(
      //Defines your base API url eg. https://mybestrestapi.com
      //baseUrl: 'https://169.254.73.31:443/',
      baseUrl: 'https://169.254.22.77:443/',
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

String generateRandomString(chars, int length) => Iterable.generate(length, (idx) => chars[random.nextInt(chars.length)]).join();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'DNA App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
}

class MyHomePage extends StatelessWidget {
  @override
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
                              borderSide: BorderSide(width: 1, color: Colors.blueAccent)
                           )
                        ),
                         
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
                              borderSide: BorderSide(width: 1, color: Colors.blueAccent)
                           )
                        ),
                         
                     ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton (
                    onPressed: () {
                      dna.text = generateRandomString('ATCG', 100);
                      print('encode pressed!');
                    },
                    child: Text('Encode'),
                  ),
                ),
                Padding (
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton (
                    onPressed: () async {
                      
                      Result loginResponse = await loginCall();
 
                      print("finished call");

                      var sessionID = loginResponse.data['id'];

                      print(loginResponse.data['id']);

                      print('button pressed!');

                      Result initResponse = await initCall(sessionID);

                      var runID  = initResponse.data['processRunQueue'][0]['id'];

                      print(initResponse.data['processRunQueue'][0]['id']);

                      //start process and wait for user interaction
                      Result runResponse = await processRunCall(sessionID, runID);
                      
                      print(runResponse.data);

                      Result openLidResponse = await openLidCall(sessionID, runID);

                      print(openLidResponse.data);

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
}
