import 'package:flutter/material.dart';
import '../utils/language.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class ImagePickDialog extends StatelessWidget {
  final ValueChanged<File> callback;
  final String title;

  ImagePickDialog({Key key, @required this.callback, @required this.title}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 180.0,
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Padding(
              child: Text(
                AppLocalizations.of(context).getLanguageText('pickFrom'),
                style: TextStyle(fontSize:20, color: Colors.black54),
              ),
              padding: EdgeInsets.all(10),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(25.0, 25.0, 25.0, 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex:1,
                  child:GestureDetector(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('images/images.png', height: 50.0, width: 50.0,),
                          Padding(
                            child:Text(
                              AppLocalizations.of(context).getLanguageText('gallery'),
                              style: TextStyle(fontSize:16),
                            ),
                            padding:EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      onTap: () {
                        _pick(context, ImageSource.gallery);
                      }
                  ),
                ),
                Expanded(
                  flex:1,
                  child:GestureDetector(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('images/camera.png', height: 50.0, width: 50.0,),
                          Padding(
                            child: Text(
                              AppLocalizations.of(context).getLanguageText('camera'),
                              style: TextStyle(fontSize:16),
                            ),
                            padding: EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      onTap: () {
                        _pick(context, ImageSource.camera);
                      }
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _pick(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    var image = await ImagePicker.pickImage(source: source);
    if (image == null) return;
    var croppedFile = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: Platform.isAndroid ? [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ] : [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio5x3,
          CropAspectRatioPreset.ratio5x4,
          CropAspectRatioPreset.ratio7x5,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: title,
        )
    );
    if (croppedFile == null) return;
    callback(croppedFile);
  }
}