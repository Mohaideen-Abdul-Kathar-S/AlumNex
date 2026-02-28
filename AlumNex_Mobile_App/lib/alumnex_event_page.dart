
import 'package:alumnex/alumnex_inside_college_page.dart';
import 'package:alumnex/alumnex_outside_college_page.dart';
import 'package:flutter/material.dart';


class AlumnexEventPage extends StatefulWidget {
  final dynamic rollno;
  
  final String roll;

  const AlumnexEventPage({super.key,required this.rollno,required this.roll});

  @override
  State<AlumnexEventPage> createState() => _AlumnexEventPageState();
}

class _AlumnexEventPageState extends State<AlumnexEventPage> {
  int myIndex = 1;
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  late String rollno;
  @override
  void initState() {
    super.initState();
    rollno = widget.rollno;
    
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            
            tabs: [
              Tab(
                icon: Icon(Icons.groups, color: Colors.white,),
                child: Text("Out Side", style: TextStyle(color: Colors.white)),
            
              ),
              Tab(
                icon: Icon(Icons.group_sharp, color: Colors.white),

                child: Text("In Side", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          title: Text('Events'),
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shadowColor: accentColor,
          actions: [
            Icon(Icons.notifications_none_rounded),
            SizedBox(width: 15),
            Icon(Icons.sticky_note_2_outlined),
            SizedBox(width: 15),
          ],
        ),
        body: TabBarView(
          children: [
            AlumnexOutsideCollegePage(rollno: rollno, roll: widget.roll),
            
            AlumnexInsideCollegePage(rollno : rollno, roll: widget.roll),
          ],
        ),
        
      ),
    );
  }
}
