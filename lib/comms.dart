import 'package:rest_api_client/rest_api_client.dart';

late IRestApiClient restApiClient;


initiateCartridgeChange(var sessionID) async {

  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var data = {
      "cartridgeType": "2",
      "chipKind": "1",
      "processType": "cartridgeUp",
  };

  //make more robust with specific, time based ID for title
  Result response = await restApiClient.post(
    '/api/processRuns/queue',
    options: options,
    data: data,
  );
}


Future<bool> isAnswerPending(var sessionID) async {

  Result response = await initCall(sessionID);

  if(response.data['status']['pendingAnswers'] != null) {
    return true;
  } else {
    return false;
  }
}


Future<bool> isCartridgePositionClosed(var sessionID) async {

  //as opposed to moving

  Result response = await initCall(sessionID);

  if(response.data['status']['currentState']['cartridgePosition'] != null && response.data['status']['currentState']['cartridgePosition'] == 'closed') {
    return true;
  } else {
    return false;
  } 

}


Future<bool> isLidMoving(var sessionID) async {

  Result response = await initCall(sessionID);

  if(response.data['status']['currentState']['lidPosition'] != null && response.data['status']['currentState']['lidPosition'] == 'moving') {
    return true;
  } else {
    return false;
  } 
}


Future<bool> isLidClosed(var sessionID) async {

  Result response = await initCall(sessionID);

  if(response.data['status']['currentState']['lidPosition'] != null && response.data['status']['currentState']['lidPosition'] == 'closed') {
    return true;
  } else {
    return false;
  }
}


Future<bool> isLidOpen(var sessionID) async {

  Result response = await initCall(sessionID);

  if(response.data['status']['currentState']['lidPosition'] != null && response.data['status']['currentState']['lidPosition'] == 'open') {
    return true;
  } else {
    return false;
  }
}


initialiseComms() async {

  await RestApiClient.initFlutter();

  restApiClient = RestApiClient(
    options: RestApiClientOptions(
      baseUrl: 'https://169.254.196.153:443/',
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
}

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

  print(data);

  //make more robust with specific, time based ID for title
  Result response = await restApiClient.post(
    '/api/processRuns/queue',
    options: options,
    data: data,
  );

  print(response.data);

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

Future<Result> confirmReadyForCartridgeDownCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'confirmReadyForCartridgeDown': 'true'};

  Result response = await restApiClient.put(
    '/api/processRuns/' + runID + '/control',
    options: options,
    data: {'answers': answer},
  );

  return response;
}


Future<Result> cartridgeInsertConfirmedCall(var sessionID, var runID) async {
  RestApiClientRequestOptions options = RestApiClientRequestOptions(headers: {
    'cookie': 'session=' + sessionID,
  });

  var answer = {'cartridgeInsertConfirmed': 'true'};

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