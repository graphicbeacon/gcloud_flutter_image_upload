import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Upload to Google Cloud'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  Uint8List _imageBytes;
  String _imageName;
  final picker = ImagePicker();
  CloudApi api;
  bool isUploaded = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/credentials.json').then((json) {
      api = CloudApi(json);
    });
  }

  void _getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        print(pickedFile.path);
        _image = File(pickedFile.path);
        _imageBytes = _image.readAsBytesSync();
        _imageName = _image.path.split('/').last;
        isUploaded = false;
      } else {
        print('No image selected.');
      }
    });
  }

  void _saveImage() async {
    setState(() {
      loading = true;
    });
    // Upload to Google cloud
    final response = await api.save(_imageName, _imageBytes);
    print(response.downloadLink);
    setState(() {
      loading = false;
      isUploaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: _imageBytes == null
              ? Text('No image selected.')
              : Stack(
                  children: [
                    Image.memory(_imageBytes),
                    if (loading)
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    isUploaded
                        ? Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: FlatButton(
                              color: Colors.blueAccent,
                              textColor: Colors.white,
                              onPressed: _saveImage,
                              child: Text('Save to cloud'),
                            ),
                          )
                  ],
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Select image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
