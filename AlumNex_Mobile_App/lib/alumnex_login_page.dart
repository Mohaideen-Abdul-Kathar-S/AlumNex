import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_idcard_reg_page.dart';
import 'package:alumnex/alumnex_index_page.dart';
import 'package:alumnex/alumnex_reg_page.dart';
// import 'package:alumnex/alumnex_reg_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlumnexLoginPage extends StatefulWidget {
  const AlumnexLoginPage({super.key});

  @override
  State<AlumnexLoginPage> createState() => _AlumnexLoginPageState();
}

class _AlumnexLoginPageState extends State<AlumnexLoginPage> {
  String dropDownValue = 'Select Role'; // Small fix: 'Select Role'

  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
  final TextEditingController rollnoCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('AlumNex'),
        shadowColor: accentColor,
        toolbarHeight: 100,
        backgroundColor: primaryColor,
        elevation: 3,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: accentColor,
          fontSize: 24,
        ),
        foregroundColor: accentColor,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Login Page',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: dropDownValue,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropDownValue = newValue!;
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: 'Select Role',
                        child: Text(
                          'Select Role',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Alumni',
                        child: Text('Alumni'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Roll No Field
                TextField(
                  controller: rollnoCont,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Roll No',
                    hintStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: passwordCont,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    hintStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Forget Password',
                    style: TextStyle(
                      color: Color.fromARGB(255, 117, 96, 85),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlumnexRegPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        dynamic data = {
                          'roll': dropDownValue,
                          'rollno': rollnoCont.text,
                          'password': passwordCont.text,
                        };
                        print(data);
                        int n = await DataBaseConnection().LoginPage(data);
                        if (200 == n) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("User Login Success")),
  );

  userID = rollnoCont.text;
  userRoll = dropDownValue;

  // Save locally
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("userID", userID);
  await prefs.setString("user", userID);
  await prefs.setString("userRoll", userRoll);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => AlumnexIndexPage(
        rollno: rollnoCont.text,
        roll: dropDownValue,
      ),
    ),
  );
} else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Roll numner or Passwaord is Invalid",
                              ),
                            ),
                          );
                        }

                        
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                
              ],
              
            ),
          ),
        ),
      ),
    );
  }
}
