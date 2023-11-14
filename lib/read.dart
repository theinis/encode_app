import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:dartssh2/dartssh2.dart';
import 'filesystem_picker.dart';


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

  Widget build(BuildContext context) {
    TextEditingController result = TextEditingController();

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

                      var rootPath = Directory('/homes/theinis');

                      String path = await FilesystemPicker.openDialog(title: 'Choose sequencing run',
                        context: context,
                        rootDirectory: rootPath,
                        fsType: FilesystemType.folder,
                        fileTileSelectMode: FileTileSelectMode.wholeTile,
                        showGoUp: false,
                        pickText: 'Pick directory',) as String;

                      final client = SSHClient(
                        await SSHSocket.connect('146.169.21.39', 22),
                        username: 'theinis',
                        onPasswordRequest: () => '',
                      );

                      final sftp = await client.sftp();

                      final items = await sftp.listdir(path);

                      for (var item in items) {
                        if(item.attr.isFile) {
                          if (item.filename.toLowerCase().contains("fastq.gz")) {
                            print(item.filename);

                            final file = await sftp.open(path + Platform.pathSeparator + item.filename);
                            final content = await file.readBytes();
                            final f = new File(item.filename);
                            f.writeAsBytesSync(content);
                          }
                        }
                      }

                      client.close();
                      await client.done;

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