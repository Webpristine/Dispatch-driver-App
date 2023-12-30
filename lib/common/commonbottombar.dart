import 'package:fancy_bottom_navigation_2/fancy_bottom_navigation.dart';
import 'package:first_choice_driver/common/bottomnavigationbar.dart';
import 'package:first_choice_driver/helpers/colors.dart';
import 'package:flutter/material.dart';

import '../my_flutter_app_icons.dart';

class CommonBottomBar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  CommonBottomBar({super.key});

  @override
  State<CommonBottomBar> createState() => _CommonBottomBarState();
}

class _CommonBottomBarState extends State<CommonBottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green,
      child: FancyBottomNavigation(
        barBackgroundColor: Colors.green,
        circleColor: Colors.white,
        inactiveIconColor: Colors.black,
        activeIconColor: Colors.green,
        //    initialSelection: widget.currentTab,
        onTabChangedListener: (int i) {
          if (i == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PagesWidget(
                  currentTab: 0,
                ),
              ),
            );
          } else if (i == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PagesWidget(
                  currentTab: 1,
                ),
              ),
            );
          } else if (i == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PagesWidget(
                  currentTab: 2,
                ),
              ),
            );
          } // _selectTab(
          //   i,
          // );
        },
        tabs: [
          TabData(
            iconData: MyFlutterApp.home,
            title: "",
            onclick: () {},
          ),
          TabData(
            iconData: MyFlutterApp.past,
            title: "",
            onclick: () {},
          ),
          TabData(
            iconData: MyFlutterApp.person,
            title: "",
            onclick: () {},
          ),
        ],
      ),

      // return Container(
      //   color: AppColors.appColor,
      //   child: BottomNavigationBar(
      //     type: BottomNavigationBarType.fixed, // Fixed
      //     selectedItemColor: AppColors.green,
      //     selectedFontSize: 0,
      //     unselectedFontSize: 0,
      //     iconSize: 22,

      //     elevation: 0,
      //     selectedLabelStyle: AppText.text14w400.copyWith(
      //       color: AppColors.green,
      //       fontSize: 0.sp,
      //     ),
      //     unselectedLabelStyle: AppText.text14w400.copyWith(
      //       color: AppColors.grey500,
      //       fontSize: 14.sp,
      //     ),
      //     backgroundColor: Colors.transparent,
      //     selectedIconTheme: IconThemeData(
      //       size: 22,
      //       color: AppColors.green,
      //     ),
      //     unselectedItemColor: AppColors.grey500,
      //     //    currentIndex: widget.currentTab,
      //     onTap: (int i) {
      //       // this._selectTab(
      //       //   i,
      //       // );
      //     },
      //     items: [
      //       BottomNavigationBarItem(
      //         icon: InkWell(

      //           child: const Icon(
      //             Icons.home,
      //           ),
      //         ),
      //         label: "",
      //       ),
      //       BottomNavigationBarItem(
      //         icon: InkWell(

      //           child: const Icon(
      //             Icons.ac_unit,
      //           ),
      //         ),
      //         label: "",
      //       ),
      //       BottomNavigationBarItem(
      //         label: "",
      //         icon: InkWell(

      //           child: const Icon(
      //             Icons.person,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
    );
  }
}
