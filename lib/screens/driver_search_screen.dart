import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:first_choice_driver/common/app_image.dart';
import 'package:first_choice_driver/common/bottomnavigationbar.dart';
import 'package:first_choice_driver/controller/driverstatus_provider.dart';
import 'package:first_choice_driver/controller/ride_provider.dart';
import 'package:first_choice_driver/model/riderequestnoti.dart';   
import 'package:first_choice_driver/size_extension.dart';

import 'package:first_choice_driver/widgets/acceptrejectride.dart';
import 'package:first_choice_driver/widgets/driverarrived.dart';
import 'package:first_choice_driver/widgets/driverarriving.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import '../widgets/acceptaddress.dart';

class DriverSearch extends StatefulWidget {
  final bool isriderecieved;
  final RideRequestModel? rideRequestModel;
  final GlobalKey<ScaffoldState>? parentScaffoldKey;

  const DriverSearch({
    super.key,
    this.parentScaffoldKey,
    this.isriderecieved = false,
    this.rideRequestModel,
  });

  @override
  State<DriverSearch> createState() => _DriverSearchState();
}

class _DriverSearchState extends State<DriverSearch>
    with WidgetsBindingObserver {
  late AppLifecycleState appLifecycle;

  Widget? errorPermssionWidget;
  @override
  // ADD THIS FUNCTION WITH A AppLifecycleState PARAMETER
  didChangeAppLifecycleState(AppLifecycleState state) {
    appLifecycle = state;
    setState(() {});

    if (state == AppLifecycleState.paused) {
      // IF YOUT APP IS IN BACKGROUND...
      // YOU CAN ADDED THE ACTION HERE
      rideProvider.audioPlayer.stop();
      print('My app is in background');
    } else if (state == AppLifecycleState.resumed) {
      if (rideProvider.isacceptvisible) {
        rideProvider.audioPlayer.resume();
      }
    }
  }

  LatLng? pickupLocation;
  Timer? _timer;

  RideProvider rideProvider = RideProvider();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    rideProvider = Provider.of<RideProvider>(
      context,
      listen: false,
    );
    rideProvider.fetchlocatiocation(context: context).onError(
          (error, stackTrace) => errorPermssionWidget,
        );

    rideProvider.updatetoken(context: context);
    rideProvider.startLocationUpdates();
    getrideid();
    context.read<DriverStatusProvider>().getdriverstatus(
          context: context,
        );
    print("is ride received ${widget.isriderecieved}");
    if (widget.isriderecieved) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        rideProvider.visibleaccept();
        rideProvider.playAlertSoundContinuously();
      });
    }

    if (mounted) {
      _timer = Timer.periodic(
        Duration(seconds: 5),
        (timer) async {
          if (!mounted) {
            timer.cancel();
            return;
          }
          await context.read<RideProvider>().getridestatus(
                context: context,
              );
        },
      );
    }
    _handlecurrentbooking();

    super.initState();
  }

  Future<void> getrideid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (widget.rideRequestModel != null) {
      setState(() {
        context.read<RideProvider>().rideid =
            widget.rideRequestModel!.bookingNumber;
      });
      preferences.setString("rideid", widget.rideRequestModel!.bookingNumber);
    }
    if (widget.rideRequestModel == null) {
      setState(() {
        context.read<RideProvider>().rideid = preferences.getString("rideid");
      });
    }
  }

  Future<void> _handlecurrentbooking() async {
    await Provider.of<RideProvider>(context, listen: false)
        .currentride(context: context);
    if (!mounted) {
      return;
    }

    final resultant = context.read<RideProvider>().currentRide;

    if (resultant?.bookingId.isNotEmpty ?? false) {
      if (resultant?.status == 'payment done' ||
          resultant?.status == 'payment received') {
        return;
      }
    }
  }

  @override
  void dispose() {
    rideProvider.positionStream?.cancel();
    _timer!.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(builder: (context, provider, child) {
      if (provider.isloading) {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          OverlayLoadingProgress.start(
            context,
          );
        });
      } else if (provider.iserror) {
        OverlayLoadingProgress.stop();
      }

      OverlayLoadingProgress.stop();

      return WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return false;
        },
        child: Consumer<DriverStatusProvider>(
            builder: (context, controller, child) {
          if (controller.isloading) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              OverlayLoadingProgress.start(
                context,
              );
            });
          } else if (controller.iserror) {
            OverlayLoadingProgress.stop();
          } else if (controller.driverStatus != null) {
            OverlayLoadingProgress.stop();

            if (provider.acceptResponse != null) {
              provider.addpickupmarker(
                pickuplatLng: LatLng(
                  double.parse(provider.acceptResponse!.pickupLocation.lat),
                  double.parse(provider.acceptResponse!.pickupLocation.long),
                ),
              );

              provider.adddroplocation();
            } else if (provider.currentRide != null) {
              provider.addpickupmarker(
                pickuplatLng: LatLng(
                  double.parse(provider.currentRide!.pickupLocation.lat),
                  double.parse(provider.currentRide!.pickupLocation.long),
                ),
              );

              provider.adddroplocation();
            }
            return Scaffold(
              appBar: AppBar(
                leading: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PagesWidget(
                            currentTab: 2,
                          ),
                        ),
                      );
                    },
                    child: const AppImage(
                      "assets/user.png",
                    ),
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 1,
                centerTitle: true,
                title: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: AnimatedToggleSwitch<bool>.dual(
                    current: controller.isonline,
                    first: true,
                    second: false,
                    dif: 20.0,
                    borderColor: Colors.transparent,
                    borderWidth: 5.0,
                    height: 35,
                    innerColor: controller.isonline ? Colors.green : Colors.red,
                    onChanged: (b) {
                      controller.changestatus(value: b, context: context);
                    },
                    indicatorColor: Colors.transparent,
                    indicatorSize: const Size(47, 25),
                    iconBuilder: (value) => value
                        ? const AppImage("assets/driver.svg")
                        : const AppImage("assets/driver.svg"),
                    textBuilder: (value) => value
                        ? Center(
                            child: Text(
                            'Online',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ))
                        : Center(
                            child: Text(
                            'Offline',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                  ),
                ),
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    polylines: Set<Polyline>.of(rideProvider.polylines.values),
                    zoomGesturesEnabled: true,
                    zoomControlsEnabled: false,
                    markers: rideProvider.markers,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onMapCreated: (mapcontroller) {
                      if (!provider.googleMapController.isCompleted) {
                        provider.googleMapController.complete(mapcontroller);
                      }
                      if (provider.acceptResponse != null) {
                        // setState(() {
                        //   contro.animateCamera(
                        //     CameraUpdate.newLatLngZoom(
                        //       LatLng(
                        //         double.parse(provider
                        //             .acceptResponse!.pickupLocation.lat),
                        //         double.parse(provider
                        //             .acceptResponse!.pickupLocation.long),
                        //       ),
                        //       15,
                        //     ),
                        //   );
                        // });
                      }
                      mapcontroller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          getlatlong(),
                          15,
                        ),
                      );
                    },
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    initialCameraPosition: CameraPosition(
                      target: getlatlong(),
                      zoom: 15.0,
                    ),
                  ),
                  //  const AppGoogleMap(),
                  Visibility(
                    visible: provider.isacceptvisible,
                    child: acceptaddress(
                            droplocation: widget.rideRequestModel == null
                                ? ""
                                : widget.rideRequestModel!.dropAddress,
                            pickupLocation: widget.rideRequestModel == null
                                ? ""
                                : widget.rideRequestModel!.pickupAddress)
                        .animate()
                        .slideX(
                          duration: 1.seconds,
                        ),
                  ),
                  Visibility(
                    visible: provider.isacceptvisible,
                    child: acceptrejectride(
                            context: context,
                            provider: controller,
                            rideRequestModel: widget.rideRequestModel)
                        .animate()
                        .slideY(begin: 1, duration: 1.seconds),
                  ),
                  Visibility(
                    visible: provider.isarriving,
                    child: provider.acceptResponse != null ||
                            provider.currentRide != null
                        ? arrivingwidget(
                            rideProvider: provider,
                            context: context,
                          ).animate().slideX(
                              duration: 500.milliseconds,
                            )
                        : const SizedBox(),
                  ),
                  Visibility(
                    visible: provider.isdriverarrive,
                    child: provider.driverArrived != null ||
                            provider.currentRide != null
                        ? driverarrived(
                            provider: provider,
                            rideid: provider.currentRide != null
                                ? provider.currentRide!.bookingId
                                : widget.rideRequestModel!.bookingNumber,
                            markers: rideProvider.markers,
                            context: context,
                            latitude: rideProvider.currentPosition != null
                                ? rideProvider.currentPosition!.latitude
                                    .toString()
                                : 00.toString(),
                          )
                        : const SizedBox(),
                  )
                ],
              ),
            );
          }

          return const SizedBox();
        }),
      );
    });
  }

  LatLng getlatlong() {
    return LatLng(
        rideProvider.currentPosition != null
            ? rideProvider.currentPosition!.latitude
            : 00,
        rideProvider.currentPosition != null
            ? rideProvider.currentPosition!.longitude
            : 00);
  }
}

final drivericon = const AppImage(
  "assets/driver.png",
  height: 130,
  width: 130,
).toBitmapDescriptor(
  logicalSize: const Size(130, 130),
  imageSize: const Size(130, 130),
);

final pickupicon = const AppImage(
  "assets/pickup.png",
  height: 130,
  width: 130,
).toBitmapDescriptor(
  logicalSize: const Size(130, 130),
  imageSize: const Size(130, 130),
);

final dropicon = const AppImage(
  "assets/droppin.png",
  height: 130,
  width: 130,
).toBitmapDescriptor(
  logicalSize: const Size(130, 130),
  imageSize: const Size(130, 130),
);

final centericon = const AppImage(
  "assets/centerpin.png",
  height: 130,
  width: 130,
).toBitmapDescriptor(
  logicalSize: const Size(130, 130),
  imageSize: const Size(130, 130),
);
