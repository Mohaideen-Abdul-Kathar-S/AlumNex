import 'package:alumnex/alumnex_chats_page.dart';
import 'package:alumnex/alumnex_event_page.dart';
import 'package:alumnex/alumnex_post_page.dart';
import 'package:alumnex/alumnex_profile_page.dart';
import 'package:flutter/material.dart';

class AlumnexIndexPage extends StatefulWidget {
  final String rollno;
  
  final String roll;
  const AlumnexIndexPage({super.key, required this.rollno,required this.roll});

  @override
  State<AlumnexIndexPage> createState() => _AlumnexIndexPageState();
}

class _AlumnexIndexPageState extends State<AlumnexIndexPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
  int myIndex = 0;
  String pageName = 'Posts';
  late List<Widget> TapsWidgets;
  

  void initState() {
    super.initState();
    print(widget.rollno);
    print(widget.roll);
    TapsWidgets = [
    AlumnexPostPage(rollno: widget.rollno,roll : widget.roll),
    AlumnexEventPage(rollno: widget.rollno,roll: widget.roll),
    AlumnexChatsPage(rollno: widget.rollno,roll : widget.roll),
    AlumnexProfilePage(rollno: widget.rollno,roll : widget.roll),
  ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TapsWidgets[myIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        currentIndex: myIndex,
        selectedItemColor: accentColor,

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: Color(0xFF004d52),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Events",
            backgroundColor: Color(0xFF004d52),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart_sharp),
            label: "Chats",
            backgroundColor: Color(0xFF004d52),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
            backgroundColor: Color(0xFF004d52),
          ),
        ],
      ),
    );
  }
}
