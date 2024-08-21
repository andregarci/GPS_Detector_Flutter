import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationPage(),
    );
  }
}

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage>
    with WidgetsBindingObserver {
  String _locationMessage = "";
  bool _isGpsActive = false;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  bool _isAlertShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkGpsStatus();
    _listenForGpsChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusStream?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGpsStatus();
    }
  }

  void _listenForGpsChanges() {
    _serviceStatusStream =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setState(() {
        _isGpsActive = status == ServiceStatus.enabled;
      });
      if (_isGpsActive) {
        if (_isAlertShowing) {
          Navigator.of(context).pop();
          _isAlertShowing = false;
        }
        _getLocation();
      } else {
        _showGpsAlert();
      }
    });
  }

  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isGpsActive = serviceEnabled;
    });
    if (!serviceEnabled) {
      _showGpsAlert();
    } else {
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationMessage =
            "Latitud: ${position.latitude}, Longitud: ${position.longitude}";
      });
      print(_locationMessage);
    } catch (e) {
      print(e);
    }
  }

  void _showGpsAlert() {
    if (!_isAlertShowing) {
      _isAlertShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text("GPS Desactivado"),
              content: Text(
                  "Es necesario activar el GPS para usar esta aplicación."),
              actions: <Widget>[
                TextButton(
                  child: Text("Activar GPS"),
                  onPressed: () async {
                    await Geolocator.openLocationSettings();
                  },
                ),
              ],
            ),
          );
        },
      ).then((_) => _isAlertShowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isGpsActive,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Detector de Ubicación"),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_locationMessage),
              ElevatedButton(
                child: Text("Actualizar Ubicación"),
                onPressed: _checkGpsStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
