import 'package:flutter/material.dart';
import 'package:bookcycle/pages/homepage.dart';
import 'package:bookcycle/second_page.dart';

class ScreenManage extends StatefulWidget {
  const ScreenManage({super.key});

  @override
  State<ScreenManage> createState() => _ScreenManageState();
}

class _ScreenManageState extends State<ScreenManage> {

  List pages = [
    SecondPage(),
    SecondPage(),
    SecondPage(),

  ];

  int currentIndex = 0;

  void changepage(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
          onTap: changepage,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home),
                label: "Home"
            ),
            BottomNavigationBarItem(icon: Icon(Icons.settings),
                label: "Setting"
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person),
                label: "profil"


            ),
          ]),
    );
  }
}