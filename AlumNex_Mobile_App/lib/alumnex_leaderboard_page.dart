import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_view_profile_page.dart';
import 'package:flutter/material.dart';
import 'alumnex_database_connection_page.dart';

class AlumnexLeaderboardPage extends StatefulWidget {
  final String rollno;
  final String roll;

  const AlumnexLeaderboardPage({
    super.key,
    required this.rollno,
    required this.roll,
  });

  @override
  State<AlumnexLeaderboardPage> createState() =>
      _AlumnexLeaderboardPageState();
}

class _AlumnexLeaderboardPageState extends State<AlumnexLeaderboardPage> {


  // Theme colors
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

late Future<List<dynamic>> leaderboard;

  @override
  void initState() {
    super.initState();
    leaderboard = _loadLeaderboard();
  }

  Future<List<dynamic>> _loadLeaderboard() async {
    final data = await DataBaseConnection().getLeaderboard();
    return data;
  }

  Widget _buildTopThree(List<dynamic> data) {
    print("data on leaderboard"+data.toString());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: secondaryColor.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          if (index >= data.length) return Container(); // Safety check
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlumnexViewProfilePage(
                    temprollno: data[index]['_id'],
                    temproll: data[index]['rollno'],
                    rollno: widget.rollno,
                    roll: widget.roll,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primaryColor,
                      backgroundImage: NetworkImage(
                        '$urI/get-profile/${data[index]["_id"]}',
                      ),
                      onBackgroundImageError: (_, __) {},
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                      child: Text(
                        "#${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                
                Text(
                  
                  (data[index]?['fields']?['Full Name'] == null ||
   data[index]?['fields']?['Full Name'] == "Nill")
      ? (data[index]?['_id'] ?? "Unknown")
      : data[index]?['fields']?['Full Name'] ?? "Unknown",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${data[index]['total_likes']} Likes",
                  style: TextStyle(color: accentColor),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: primaryColor,
      ),
       body: FutureBuilder<List<dynamic>>(
  future: leaderboard,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(
          child: Text(
        'Error: ${snapshot.error}',
        style: TextStyle(color: accentColor),
      ));
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
          child: Text(
        'No leaderboard data available',
        style: TextStyle(color: accentColor),
      ));
    } else {
      final data = snapshot.data!;
      final topThree = data.take(3).toList();
      final others = data.length > 3 ? data.sublist(3) : [];

      return Column(
        children: [
          _buildTopThree(topThree),
          Expanded(
            child: ListView.builder(
              itemCount: others.length,
              itemBuilder: (context, index) {
                return Card(
                  color: primaryColor.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  child: ListTile(
                    leading: ClipOval(
                      child: Image.network(
                        '$urI/get-profile/${others[index]["_id"]}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 30,
                            backgroundColor: primaryColor,
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      (others[index]?['fields']?['Full Name'] == null ||
   others[index]?['fields']?['Full Name'] == "Nill")
      ? (others[index]?['_id'] ?? "Unknown")
      : others[index]?['fields']?['Full Name'] ?? "Unknown",
                    
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Total Likes: ${others[index]['total_likes']}',
                      style: TextStyle(color: accentColor),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlumnexViewProfilePage(
                            temprollno: others[index]['_id'],
                            temproll: others[index]['rollno'],
                            rollno: widget.rollno,
                            roll: widget.roll,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  },
),

    );
  }
}
