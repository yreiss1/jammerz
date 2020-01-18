import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:geocoder/geocoder.dart' as prefix1;
import 'package:image_cropper/image_cropper.dart';
import 'package:bandmates/views/OnboardingScreens/ImageCapture.dart';
import 'dart:io';
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';

import 'package:achievement_view/achievement_view.dart';
import 'package:achievement_view/achievement_widget.dart';

class QuestionsCapture extends StatefulWidget {
  GlobalKey<FormBuilderState> fbKey;

  QuestionsCapture({@required this.getInfo, @required this.fbKey});
  final Function getInfo;

  @override
  _QuestionsCaptureState createState() => _QuestionsCaptureState();
}

class _QuestionsCaptureState extends State<QuestionsCapture> {
  File _imageFile;
  GeoFirePoint point;
  Geoflutterfire geo = Geoflutterfire();
  Location location = new Location();
  int _currentStep = 0;

  TextEditingController _locationController;

  final _birthdayFocusNode = FocusNode();

  final _genderFocusNode = FocusNode();

  final _bioFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _locationController = new TextEditingController();
  }

  /// Remove image
  void _clear() {
    setState(() => _imageFile = null);
  }

  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
      sourcePath: _imageFile.path,
    );

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = selected;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<LocationData> _getLocation() async {
    var pos = await location.getLocation();
    setState(() {
      point = geo.point(latitude: pos.latitude, longitude: pos.longitude);
    });
    final coordinates = new prefix1.Coordinates(pos.latitude, pos.longitude);
    var address =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = address.first;

    print(
        "${first.featureName} : ${first.addressLine} : ${first.subLocality} : ${first.subThoroughfare} : ${first.subAdminArea}");

    _locationController.text = first.subAdminArea;
  }

  getImage(File imageFile) {
    setState(() {
      _imageFile = imageFile;
    });
  }

  List<Step> _mySteps() {
    List<Step> _steps = [
      Step(
        title: Text('Your Name'),
        content: FormBuilderTextField(
          onFieldSubmitted: (value) {
            FocusScope.of(context).requestFocus(_birthdayFocusNode);
          },
          attribute: "name",
          decoration: InputDecoration(
            labelText: "Name",
            hintText: 'What\'s your name?',
          ),
          keyboardType: TextInputType.text,
          validators: [
            FormBuilderValidators.required(),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text('Your Profile Image'),
        content: ImageCapture(
          getImageFile: getImage,
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: Text('A little bit about you'),
        content: FormBuilderTextField(
          focusNode: _bioFocusNode,
          attribute: "bio",
          decoration: InputDecoration(
            labelText: "Bio",
            hintText: 'Tell us about yourself...',
          ),
          keyboardType: TextInputType.text,
          minLines: 1,
          maxLines: 3,
          validators: [FormBuilderValidators.required()],
        ),
        isActive: _currentStep >= 2,
      ),
      Step(
          title: Text("Your Location"),
          content: Column(
            children: <Widget>[
              FormBuilderTextField(
                attribute: 'location',
                decoration: InputDecoration(
                  labelText: "Hit the button to find your location",
                ),
                readOnly: true,
                controller: _locationController,
                validators: [FormBuilderValidators.required()],
              ),
              SizedBox(
                height: 20,
              ),
              FlatButton.icon(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Colors.white,
                          width: 1,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(50)),
                  color: Theme.of(context).primaryColor,
                  icon: Icon(LineIcons.camera),
                  textColor: Colors.white,
                  label: Text("Get My Location"),
                  onPressed: () => _getLocation()),
            ],
          ),
          isActive: _currentStep >= 3),
      Step(
          title: Text("Some Logistics"),
          content: Column(
            children: <Widget>[
              FormBuilderCheckbox(
                attribute: 'transportation',
                checkColor: Theme.of(context).primaryColor,
                activeColor: Colors.white,
                label: Text("I have a reliable mode of transportation"),
                validators: [],
              ),
              FormBuilderCheckbox(
                attribute: 'practice',
                checkColor: Theme.of(context).primaryColor,
                activeColor: Colors.white,
                label: Text("I have practice space"),
                validators: [],
              ),
            ],
          ),
          isActive: _currentStep >= 4),
    ];

    return _steps;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildHeader(),
        _buildMainArea(),
      ],
    );
  }

  _buildHeader() {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25))),
      padding: EdgeInsets.only(left: 12, top: 32),
      height: 250,
      width: double.infinity,
      child: Container(),
    );
  }

  _buildMainArea() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        child: FormBuilder(
          onChanged: (val) => {
            widget.fbKey.currentState.save(),
            widget.getInfo(
                val['name'],
                val['birthday'],
                val['bio'],
                val['gender'],
                val['transportation'],
                val['practice'],
                point,
                _imageFile)
          },
          key: widget.fbKey,
          autovalidate: false,
          child: Stepper(
            steps: _mySteps(),
            physics: ClampingScrollPhysics(),
            currentStep: this._currentStep,
            controlsBuilder: (BuildContext context,
                {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _currentStep == 4 // this is the last step
                        ? Container(child: null)
                        : RaisedButton.icon(
                            icon: Icon(
                              LineIcons.check,
                              color: Colors.white,
                            ),
                            onPressed: onStepContinue,
                            label: Text(
                              'Next',
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Theme.of(context).primaryColor,
                          ),
                    _currentStep == 0
                        ? Container(
                            child: null,
                          )
                        : FlatButton.icon(
                            icon: Icon(LineIcons.arrow_left),
                            label: const Text('Back'),
                            onPressed: onStepCancel,
                          )
                  ],
                ),
              );
            },
            onStepTapped: (step) {
              setState(() {
                this._currentStep = step;
              });
            },
            onStepContinue: () {
              FocusScope.of(context).unfocus();

              AchievementView(context,
                  title: "Bandmates",
                  subTitle: "Welcome to Bandmates!",
                  color: Theme.of(context).primaryColor,
                  duration: Duration(seconds: 2),
                  alignment: Alignment.topCenter,
                  icon: Icon(
                    LineIcons.trophy,
                    color: Colors.white,
                  ),
                  typeAnimationContent: AnimationTypeAchievement.fadeSlideToUp,
                  listener: (status) {
                print(status);
              }).show();

              setState(() {
                if (this._currentStep < this._mySteps().length - 1) {
                  this._currentStep = this._currentStep + 1;
                } else {
                  //Logic to check if everything is completed
                  if (!widget.fbKey.currentState.validate()) {}
                  print('Completed, check fields.');
                }
              });
            },
            onStepCancel: () {
              setState(() {
                if (this._currentStep > 0) {
                  this._currentStep = this._currentStep - 1;
                } else {
                  this._currentStep = 0;
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
