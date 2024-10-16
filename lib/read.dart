import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:dartssh2/dartssh2.dart';
import 'filesystem_picker.dart';
import 'package:shell/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';


class ReadingPage extends StatefulWidget {
  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> with TickerProviderStateMixin {
  int _state = 0;

  bool _isBusy = false;
  //OpenFileDialogType _dialogType = OpenFileDialogType.image;
  //SourceType _sourceType = SourceType.photoLibrary;
  bool _allowEditing = false;
  File? _currentFile;
  String? _savedFilePath;
  bool _localOnly = false;
  bool _copyFileToCacheDir = true;
  String? _pickedFilePath;
  double _progress = 0.0;


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


  void _showDialog(BuildContext context, List<Map> items) {
    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Reading Data";
        String contentText = "Make sure chip and cartridge are ready";


  
  //DirectoryLocation? _pickedDirecotry;
  //Future<bool> _isPickDirectorySupported = FlutterFileDialog.isPickDirectorySupported();;

        LinearProgressIndicator progressindicator = LinearProgressIndicator(value: 1.0,
                          backgroundColor: Colors.orangeAccent,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                          minHeight: 8,
                        );

        Map<int, bool> selectedFlag = {};
        bool isSelectionMode = false;

        void onTap(bool isSelected, int index) {
          if (isSelectionMode) {
            setState(() {
              selectedFlag[index] = !isSelected;
              isSelectionMode = selectedFlag.containsValue(true);
            });
          } else {
      // Open Detail Page
          }
        }

        void onLongPress(bool isSelected, int index) {
          setState(() {
            selectedFlag[index] = !isSelected;
            isSelectionMode = selectedFlag.containsValue(true);
          });
        }

        Widget _buildSelectIcon(bool isSelected, Map data) {
          if (isSelectionMode) {
            return Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: Theme.of(context).primaryColor,
            );
          } else {
            return CircleAvatar(
              child: Text('${data['id']}'),
            );
          }
        }

        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return 
            
            AlertDialog(
              title: Text(titleText),
              content: SizedBox(
                height: 200,
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (builder, index) {
                        Map data = items[index];
                        selectedFlag[index] = selectedFlag[index] ?? false;
                        bool? isSelected = selectedFlag[index];

                        return ListTile(
                          onLongPress: () => onLongPress(isSelected!, index),
                          onTap: () => onTap(isSelected!, index),
                          title: Text("${data['name']}"),
                          leading: _buildSelectIcon(isSelected!, data),
                        );
                      },
                      itemCount: items.length,
                    ),
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

  void _updateProgress() {
    const oneSec = const Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer t) {
      setState(() {
        _progress += 0.2;
        if (_progress.toStringAsFixed(1) == '1.0') {
          t.cancel();
          return;
        }
      });
    });
  }

  void _showReadProgress(BuildContext context, String directory, SSHClient client) {

    String contentText = "Ready to download data";

    showDialog(
      context: context,
      builder: (context) {
        sessionID = '1234567890';
        runID = '1234567890';
        String titleText = "Decoding data";

        _updateProgress();

        LinearProgressIndicator progressindicator = LinearProgressIndicator(
                          value: _progress,
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
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async  {

                        final sftp = await client.sftp();
                        //final items = await sftp.listdir(path);
                        final items = await sftp.listdir('/homes/theinis/DnD');

                        var totalcount = 0;

                        for (var item in items) {
                          if(item.attr.isFile) {
                            if (item.filename.toLowerCase().contains("fastq")) {
                              totalcount++;
                            }
                          }
                        }

                        print(totalcount);

                        var currentcount = 1;

                        for (var item in items) {
                          if(item.attr.isFile) {
                            if (item.filename.toLowerCase().contains("fastq")) {
                              print(item.filename);

                              setState(() {
                                _progress = currentcount/totalcount;
                                contentText = "Downloading file " + currentcount.toString() + "/" + totalcount.toString();
                              });

                              final file = await sftp.open(directory + '/' + item.filename);
                              final content = await file.readBytes();
                              final f = new File(item.filename);
                              f.writeAsBytesSync(content);

                              currentcount++;

                             // sleep(Duration(seconds:1));
                            }
                          }
                        }

                        var shell = new Shell();
                        var localPath = await shell.startAndReadAsString('cd');
                        //print('cwd: $localPath');
                        //var decodingResult = await shell.startAndReadAsString('python', arguments: ['c:/users/omers/dnd/decodeData.py', '--pathToData', localPath, '--pathToNpyEncodingFile', 'c:/users/omers/dnd/temp/codec.npy']);
                        //print('$decodingResult');
                        //print(decodingResult.replaceAll('', replace));
                        //result.text = decodingResult;

                        client.close();
                        await client.done;

                        Navigator.pop(context);
                      },
                      //this should lead to all state being removed, i.e., the queue cleared etc.
                      child: Text("Start"),
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
    TextEditingController result = TextEditingController();
    String contentText = "Starting download";

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  'Read Data',
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
                controller: result,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: "",
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

                      //var rootPath = Directory('/home/minit');//
                      var rootPath = Directory('/homes/theinis');

                      final prefs = await SharedPreferences.getInstance();
                      final minionip = prefs.getString('minionip') ?? '192.192.192.1';
                      final minionuser = prefs.getString('minionuser') ?? 'minit';
                      final minionpass = prefs.getString('minionpass') ?? 'minit';

                      String path = await FilesystemPicker.openDialog(title: 'Choose sequencing run',
                        context: context,
                        rootDirectory: rootPath,
                        fsType: FilesystemType.folder,
                        fileTileSelectMode: FileTileSelectMode.wholeTile,
                        showGoUp: false,
                        pickText: 'Pick directory',) as String;
                      
                      final client = SSHClient(
                        await SSHSocket.connect(minionip, 22),//'146.169.21.39', 22),
                        username: minionuser,
                        onPasswordRequest: () => minionpass,
                      );

                      _showReadProgress(context, '/homes/theinis/DnD', client);


                    },
                    child: Text('Decode'),
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