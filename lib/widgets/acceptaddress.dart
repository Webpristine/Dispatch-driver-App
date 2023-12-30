import 'package:first_choice_driver/common/sizedbox.dart';
import 'package:first_choice_driver/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget acceptaddress({
  required String pickupLocation,
  required String droplocation,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        20,
      ),
    ),
    margin: EdgeInsets.only(
          top: 10.h,
        ) +
        EdgeInsets.symmetric(
          horizontal: 10.w,
        ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              sizedBoxWithHeight(10),
              Text(
                "Pickup",
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              sizedBoxWithHeight(10),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 8.w,
                ),
                padding: EdgeInsets.all(
                      8.r,
                    ) +
                    EdgeInsets.symmetric(horizontal: 30.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child: Text(
                  pickupLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              sizedBoxWithHeight(10),
              Text(
                "Drop",
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              sizedBoxWithHeight(10),
              Container(
                padding: EdgeInsets.all(
                      8.r,
                    ) +
                    EdgeInsets.symmetric(horizontal: 30.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child: Text(droplocation),
              ),
              sizedBoxWithHeight(20),
            ],
          ),
        ),
      ],
    ),
  );
}
