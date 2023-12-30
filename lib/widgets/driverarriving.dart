import 'dart:developer';

import 'package:first_choice_driver/common/app_image.dart';
import 'package:first_choice_driver/common/sizedbox.dart';
import 'package:first_choice_driver/controller/ride_provider.dart';
import 'package:first_choice_driver/helpers/colors.dart';
import 'package:first_choice_driver/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
    
Widget arrivingwidget({
  required RideProvider rideProvider,
  required BuildContext context,
}) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 10.h,
          ) +
          EdgeInsets.only(
            bottom: 30.h,
          ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(
              bottom: 20.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greydark,
                  spreadRadius: 0,
                  blurRadius: 4,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                sizedBoxWithHeight(10),
                Row(
                  children: [
                    sizedBoxWithWidth(20),
                    InkWell(
                      onTap: () async {
                        String telephoneNumber =
                            rideProvider.currentRide != null
                                ? rideProvider.currentRide!.customerMobile
                                : rideProvider.acceptResponse!.customerMobile;
                        String telephoneUrl = "tel:$telephoneNumber";

                        try {
                          await launchUrl(Uri.parse(telephoneUrl));
                        } catch (e) {
                          log(e.toString());
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            color: AppColors.green,
                            size: 13.sp,
                          ),
                          Text(
                            "  Call",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                    ),
                    sizedBoxWithWidth(50),
                    Row(
                      children: [
                        Icon(
                          Icons.close,
                          color: AppColors.green,
                          size: 13.sp,
                        ),
                        Text(
                          "  Cancel",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      AppImage(
                        "assets/user.png",
                        height: 60.h,
                        width: 60.w,
                      ),
                      sizedBoxWithWidth(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rideProvider.currentRide != null
                                ? rideProvider.currentRide!.customerName
                                : rideProvider.acceptResponse!.customerName,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.green,
                                size: 10,
                              ),
                              Text(
                                rideProvider.currentRide != null
                                    ? rideProvider.currentRide!.customerRating
                                    : rideProvider
                                        .acceptResponse!.customerRating,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w300,
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                      ) +
                      EdgeInsets.only(
                        bottom: 16.h,
                      ),
                  child: rideProvider.acceptResponse != null
                      ? rideProvider.acceptResponse!.pickupNotes != ""
                          ? Text(
                              "Pickup Note: ${rideProvider.acceptResponse!.pickupNotes}",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500),
                            )
                          : SizedBox()
                      : SizedBox(),
                ),
                InkWell(
                  onTap: () {
                    context.read<RideProvider>().driverarrive(
                          context: context,
                        );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.green,
                          AppColors.yellow,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Arrive",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
