import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:first_choice_driver/api/app_repository.dart';
import 'package:first_choice_driver/common/bottomnavigationbar.dart';
import 'package:first_choice_driver/helpers/strings.dart';
import 'package:first_choice_driver/model/acceptresponse.dart';
import 'package:first_choice_driver/model/currentride.dart' as cr;
import 'package:first_choice_driver/model/driver_arrived.dart';
import 'package:first_choice_driver/model/endride.dart' as er;
import 'package:first_choice_driver/model/payment_collected.dart';
import 'package:first_choice_driver/model/ridestatus.dart';
import 'package:first_choice_driver/model/startride.dart' as sr;
import 'package:first_choice_driver/screens/driver_search_screen.dart';
import 'package:first_choice_driver/screens/in_between_ride.dart';
import 'package:first_choice_driver/screens/permission_page.dart';
import 'package:first_choice_driver/screens/rating_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/colors.dart';
import '../screens/payment_screen.dart';

class RideProvider extends ChangeNotifier {
  AudioPlayer audioPlayer = AudioPlayer();

  bool isloading = false;
  bool iserror = false;
  String errortext = '';
  AcceptResponse? acceptResponse;
  TextEditingController ratingcontroller = TextEditingController();
  cr.CurrentRide? currentRide;
  bool isdriverarrive = false;
  bool isacceptvisible = false;
  bool isarriving = false;
  DriverArrived? driverArrived;
  String rating = "0";
  RideStatus? rideStatus;
  sr.StartRide? startRide;
  er.EndRide? endRide;
  Completer<GoogleMapController> googleMapController = Completer();
  PaymentCollected? paymentCollected;
  Position? currentPosition;
  Timer? timer;
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  PolylineId selectedPolyline = const PolylineId('route');
  StreamSubscription<Position>? positionStream;
  String? rideid;
  List<LatLng> droplocations = [];
  int minutes = 0; // Calculate minutes

  String formatTime() {
    String minutesStr = minutes.toString().padLeft(
          2,
          '0',
        );
    return minutesStr;
  }

  void reset() {
    isdriverarrive = false;
    isacceptvisible = false;
    isarriving = false;
    notifyListeners();
  }

  void startLocationUpdates() async {
    positionStream = Geolocator.getPositionStream().listen(
      (
        Position position,
      ) {
        addmarker(position: position);
        currentPosition = position;
        polylineCoordinates.clear();
        notifyListeners();
        //   rideProvider.getPolylines();
      },
    );
  }

  Set<Marker> markers = {};

  addmarker({required Position position}) async {
    markers.clear();
    notifyListeners();
    markers.add(
      Marker(
        markerId: const MarkerId('marker_2'),
        draggable: false,
        position: LatLng(
          position.latitude,
          position.longitude,
        ),
        infoWindow: const InfoWindow(
          title: 'Driver Location',
          snippet: 'Marker Snippet',
        ),
        icon: await drivericon,
      ),
    );
  }

  void getPolylines({
    required LatLng latLng,
    required LatLng secondlatlong,
  }) async {
    debugPrint("Get Polylines Calling");
    // polylineCoordinates.clear();
    await getDriverToPickupPolyline(latLng: latLng);
    await getPickupToDropPolyline(latLng: secondlatlong);

    Polyline polyline = Polyline(
      polylineId: selectedPolyline,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    polylines[selectedPolyline] = polyline;
    notifyListeners();
  }

  Future<void> getDriverToPickupPolyline({
    required LatLng latLng,
  }) async {
    PolylineResult driverToPickupPoints =
        await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyD6MRqmdjtnIHn7tyDLX-qsjreaTkuzSCY', // Replace with your own Google Maps API Key
      PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
      PointLatLng(latLng.latitude, latLng.longitude),
    );

    if (driverToPickupPoints.points.isNotEmpty) {
      for (var point in driverToPickupPoints.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    notifyListeners();
  }

  Future<void> getPickupToDropPolyline({required LatLng latLng}) async {
    LatLng previousLocation = LatLng(latLng.latitude, latLng.longitude);

    for (LatLng dropLocation in droplocations) {
      PolylineResult pickupToDropPoints =
          await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyD6MRqmdjtnIHn7tyDLX-qsjreaTkuzSCY', // Replace with your own Google Maps API Key
        PointLatLng(previousLocation.latitude, previousLocation.longitude),
        PointLatLng(dropLocation.latitude, dropLocation.longitude),
      );

      if (pickupToDropPoints.points.isNotEmpty) {
        for (var point in pickupToDropPoints.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }

      previousLocation = dropLocation;
    }
    notifyListeners();
  }

  Future<void> fetchlocatiocation({
    required BuildContext context,
  }) async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      permission = await Geolocator.checkPermission();
      // if (currentPosition == null) {
      //   await Geolocator.getLastKnownPosition().then(
      //     (value) {
      //       currentPosition = value;
      //       notifyListeners();
      //     },
      //   );
      // }
      if (permission == LocationPermission.denied) {
        const error =
            PermissionDeniedException("Location Permission is denied");
        // context.showSnackBar(context, msg: error.message!);
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NoPermission(),
              ),
            );
          });
          return Future.error(error);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        const error =
            PermissionDeniedException("Location Permission is denied forever");
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(
              " ${error.message!} \n\n ",
            ),
            duration: const Duration(seconds: 2),
          ));
        }); //; Permissions are denied forever, handle appropriately.

        SchedulerBinding.instance.addPostFrameCallback(
          (timeStamp) {},
        );

        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NoPermission(),
            ),
          );
        });
        return Future.error(error);
      }

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();

        while (!await Geolocator.isLocationServiceEnabled()) {}
      }
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) {
          OverlayLoadingProgress.start(
            context,
          );
        },
      );

      var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      debugPrint(" Location is ${position.latitude}");

      currentPosition = position;
      googleMapController.future.then((value) async {
        await value.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      });
      notifyListeners();

      // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      //   context.read<DriverStatusProvider>().getdriverstatus(context: context);
      // });
      OverlayLoadingProgress.stop();
    } on PermissionDeniedException catch (e) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NoPermission(),
        ),
      );
    } catch (e) {
      OverlayLoadingProgress.stop();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   backgroundColor: AppColors.black,
      //   content: Text(
      //     " ${e.toString()} \n\n",
      //   ),
      //   duration: const Duration(
      //     seconds: 2,
      //   ),
      // ));
    } finally {
      OverlayLoadingProgress.stop();
    }
    notifyListeners();
  }

  void startTimer() {
    const oneSec = Duration(minutes: 1);
    timer = Timer.periodic(oneSec, (Timer t) {
      // setState(() {
      minutes++;

      notifyListeners();
    });
  }

  void stoptimer() {
    timer!.cancel();
    minutes = 0;
    notifyListeners();
  }

  Future<void> visibleaccept() async {
    isacceptvisible = true;

    //

    notifyListeners();
  }

  Future<void> adddroplocation() async {
    for (int i = 0; i < droplocations.length; i++) {
      if (i == droplocations.length - 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('marker_5'),
            draggable: false,
            position: LatLng(droplocations.elementAt(i).latitude,
                droplocations.elementAt(i).longitude),
            infoWindow: const InfoWindow(
                title: 'Drop Location', snippet: 'Marker Snippet'),
            icon: await dropicon,
          ),
        );
      } else {
        markers.add(
          Marker(
            markerId: const MarkerId('marker_4'),
            draggable: false,
            position: LatLng(droplocations.elementAt(i).latitude,
                droplocations.elementAt(i).longitude),
            infoWindow: const InfoWindow(
                title: 'Center Location', snippet: 'Marker Snippet'),
            icon: await centericon,
          ),
        );
      }
    }
  }

  Future<void> addpickupmarker({
    required LatLng pickuplatLng,
  }) async {
    markers.add(
      Marker(
        markerId: const MarkerId('marker_3'),
        draggable: false,
        position: pickuplatLng,
        infoWindow: const InfoWindow(
          title: 'Pickup Location',
          snippet: 'Marker Snippet',
        ),
        icon: await pickupicon,
      ),
    );
  }

  void playAlertSoundContinuously() async {
    await audioPlayer.play(AssetSource('alert.mp3'));
    audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void acceptride({
    required BuildContext context,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();
    audioPlayer.stop();

    try {
      await AppRepository()
          .acceptrejectride(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        status: "accept",
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.green,
              content: Text(" ${value["message"]} \n\n"),
              duration: const Duration(seconds: 2),
            ),
          );
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          acceptResponse = AcceptResponse.fromJson(value);
          if (acceptResponse != null) {
            for (var e in acceptResponse!.dropLocation) {
              debugPrint("Drop Location is ${e.lat}");
              if (acceptResponse!.dropLocation.length != droplocations.length) {
                droplocations.add(
                  LatLng(
                    double.parse(e.lat),
                    double.parse(
                      e.long,
                    ),
                  ),
                );
              }
            }

            getPolylines(
                secondlatlong: LatLng(
                  double.parse(acceptResponse!.pickupLocation.lat),
                  double.parse(acceptResponse!.pickupLocation.long),
                ),
                latLng: LatLng(
                  double.parse(acceptResponse!.pickupLocation.lat),
                  double.parse(acceptResponse!.pickupLocation.long),
                ));
          }
          isacceptvisible = false;
          isarriving = true;
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ArrivingScreen(
          //       acceptResponse: acceptResponse!,
          //     ),
          //   ),
          // );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void rejectride({
    required BuildContext context,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();
    audioPlayer.stop();

    try {
      await AppRepository()
          .acceptrejectride(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        status: "reject",
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.green,
              content: Text(" ${value["message"]} \n\n"),
              duration: const Duration(seconds: 2),
            ),
          );
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.green,
              content: Text(" ${value["message"]} \n\n"),
              duration: const Duration(seconds: 2),
            ),
          );
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: const Text(
              "Ride Rejected \n\n",
            ),
            duration: const Duration(seconds: 2),
          ));

          isacceptvisible = false;

          // Navigator.pop(context);

          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void driverarrive({
    required BuildContext context,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();

    try {
      await AppRepository()
          .driverarrive(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          driverArrived = DriverArrived.fromJson(value);
          isacceptvisible = false;
          isarriving = false;
          isdriverarrive = true;
          startTimer();
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AfterArrivingScreen(
          //       driverArrived: driverArrived!,
          //     ),
          //   ),
          // );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(
            seconds: 2,
          ),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void startride({
    required BuildContext context,
    required Set<Marker> markers,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();

    try {
      await AppRepository()
          .startride(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        waitingtime: formatTime(),
        latitude: currentPosition!.latitude.toString(),
        longitude: currentPosition!.longitude.toString(),
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          startRide = sr.StartRide.fromJson(value);
          stoptimer();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InBetweenRide(
                startRide: startRide!,
                markers: markers,
              ),
            ),
          );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void endride({
    required BuildContext context,
    required Set<Marker> markers,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();

    try {
      await AppRepository()
          .endrideride(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          endRide = er.EndRide.fromJson(value);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                endRide: endRide!,
                rideid: rideid!,
                markers: markers,
              ),
            ),
          );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void paymentcollected({
    required BuildContext context,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();

    try {
      await AppRepository()
          .paymentcollected(
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          paymentCollected = PaymentCollected.fromJson(value);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RatingScreen(
                paymentCollected: paymentCollected!,
                rideid: rideid!,
              ),
            ),
          );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  void riderating({
    required BuildContext context,
  }) async {
    isloading = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    notifyListeners();

    try {
      await AppRepository()
          .riderate(
        rating: rating,
        review: ratingcontroller.text,
        bookingnumber: prefs.getString("rideid") ?? rideid!,
        userid: prefs.getString(Strings().userid)!,
        accesstoken: prefs.getString(Strings().accesstoken)!,
      )
          .then((value) {
        print("value is $value");
        if (value["code"] == 201) {
          isloading = false;
          iserror = true;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 401) {
          isloading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: Text(" ${value["message"]} \n\n"),
            duration: const Duration(seconds: 2),
          ));
          notifyListeners();
        } else if (value["code"] == 200) {
          isloading = false;
          isacceptvisible = false;
          isarriving = false;
          isdriverarrive = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.green,
            content: const Text(" Rating has been updated successfully \n\n"),
            duration: const Duration(seconds: 2),
          ));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PagesWidget(
                currentTab: 0,
              ),
            ),
          );
          notifyListeners();
        }
      });
    } catch (e) {
      iserror = true;
      isloading = false;
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            " ${e.toString()} \n\n",
          ),
          duration: const Duration(seconds: 2),
        ));
      });
      notifyListeners();
    }
    notifyListeners();
  }

  Future<void> updatetoken({required BuildContext context}) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    notifyListeners();
    await AppRepository()
        .updatetoken(
          userid: preferences.getString(Strings().userid)!,
          accesstoken: preferences.getString(Strings().accesstoken)!,
          fcmtoken: fcmToken!,
        )
        .then((value) {})
        .catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.green,
        content: Text(
          "${e.toString()} \n\n ",
        ),
        duration: const Duration(seconds: 2),
      ));

      errortext = e.toString();
      notifyListeners();
    });
  }

  Future<void> currentride({required BuildContext context}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    notifyListeners();
    await AppRepository()
        .getcurrentbooking(
      userid: preferences.getString(Strings().userid)!,
      accesstoken: preferences.getString(Strings().accesstoken)!,
    )
        .then((value) {
      if (value["code"] == 200) {
        isloading = false;

        currentRide = cr.CurrentRide.fromJson(value);
        rideid = currentRide!.bookingId;
        notifyListeners();
        if (currentRide!.status == "arrived") {
          isdriverarrive = true;
          startTimer();
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AfterArrivingScreen(
          //       driverArrived: driverArrived!,
          //     ),
          //   ),
          // );
          notifyListeners();
        }
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.green,
        content: Text(
          "${e.toString()} \n\n ",
        ),
        duration: const Duration(seconds: 2),
      ));

      errortext = e.toString();
      notifyListeners();
    });
  }

  Future<void> getridestatus({
    required BuildContext context,
  }) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    notifyListeners();
    await AppRepository()
        .getridestatus(
      rideid: preferences.getString("rideid") ?? rideid!,
      userid: preferences.getString(Strings().userid)!,
      accesstoken: preferences.getString(Strings().accesstoken)!,
    )
        .then((value) {
      if (value["code"] == 200) {
        isloading = false;

        rideStatus = RideStatus.fromJson(value);
        if (rideStatus!.status == "new") {
          visibleaccept();
        } else if (rideStatus!.status == "accept") {
          for (var e in rideStatus!.dropLocation) {
            debugPrint("Drop Location is ${e.lat}");
            if (rideStatus!.dropLocation.length != droplocations.length) {
              droplocations.add(
                LatLng(
                  double.parse(e.lat),
                  double.parse(
                    e.long,
                  ),
                ),
              );
            }
          }

          getPolylines(
              secondlatlong: LatLng(
                double.parse(rideStatus!.pickupLocation.lat),
                double.parse(rideStatus!.pickupLocation.long),
              ),
              latLng: LatLng(
                double.parse(rideStatus!.pickupLocation.lat),
                double.parse(rideStatus!.pickupLocation.long),
              ));
          isarriving = true;
          notifyListeners();
        } else if (rideStatus!.status == "arrived") {
          isdriverarrive = true;
          // startTimer();
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AfterArrivingScreen(
          //       driverArrived: driverArrived!,
          //     ),
          //   ),
          // );
          notifyListeners();
        } else if (rideStatus!.status == "start") {
          //  stoptimer();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InBetweenRide(
                startRide: sr.StartRide(
                    code: 200,
                    mesage: "",
                    timestamp: "timestamp",
                    pickupLocation: sr.PLocation(
                        lat: rideStatus!.pickupLocation.lat,
                        long: rideStatus!.pickupLocation.long,
                        address: rideStatus!.pickupLocation.address),
                    dropLocation: rideStatus!.dropLocation.map((e) {
                      return sr.PLocation(
                          address: e.address, lat: e.lat, long: e.long);
                    }).toList(),
                    distance: "",
                    timing: ""),
                markers: markers,
              ),
            ),
          );
          notifyListeners();
        } else if (rideStatus!.status == "complete") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                rideid: rideid!,
                endRide: er.EndRide(
                  code: 200,
                  mesage: "",
                  timestamp: "",
                  pickupAddress: rideStatus!.pickupLocation.address,
                  dropAddress: rideStatus!.dropLocation.last.address,
                  totalAmount: "",
                  pickupLocation: er.PLocation(
                      lat: rideStatus!.pickupLocation.lat,
                      long: rideStatus!.pickupLocation.long,
                      address: rideStatus!.pickupLocation.address),
                  dropLocation: rideStatus!.dropLocation.map((e) {
                    return er.PLocation(
                        address: e.address, lat: e.lat, long: e.long);
                  }).toList(),
                  distance: "",
                  timing: "",
                ),
                markers: markers,
              ),
            ),
          );
          notifyListeners();
        }
        notifyListeners();
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.green,
        content: Text(
          "${e.toString()} \n\n ",
        ),
        duration: const Duration(seconds: 2),
      ));

      errortext = e.toString();
      notifyListeners();
    });
  }
}
