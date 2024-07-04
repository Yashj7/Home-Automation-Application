import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  runApp(MyApp());
}

class AppConfig {
  final String apiUrl;
  AppConfig({required this.apiUrl});

  static Future<AppConfig> forEnvironment() async {
    final contents = await rootBundle.loadString(
      'assets/config/prod.json',
    );
    final json = jsonDecode(contents);
    return AppConfig(apiUrl: json['apiUrl']);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyAppState>(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Home Automation App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/home': (context) => MyHomePage(users: User(0)),
          '/room': (context) => HomePage(users: User(0)),
          '/profile': (context) => ProfilePage(users: User(0)),
          '/roompage': (context) =>
              RoomDetailPage(homeid: 0, roomid: 0, roomname: ''),
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  bool isLoggedIn = false;

  void resetLoginState() {
    isLoggedIn = false;
    notifyListeners();
  }
}

class User {
  // ignore: non_constant_identifier_names
  late int home_id;
  User(this.home_id);
}

class LoginPage extends StatefulWidget {
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  bool obscureText = true;
  bool isLoading = false;
  bool isLoggedIn = false;

  void resetLoginState() {
    setState(() {
      email = '';
      password = '';
      obscureText = true;
      isLoading = false;
      isLoggedIn = false;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoggedIn = false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  Future<void> _login(String email, String password) async {
    bool loginSuccessful = false;
    final User users = User(0);

    while (!loginSuccessful) {
      try {
        setState(() {
          isLoading = true;
        });
        final AppConfig config = await AppConfig.forEnvironment();
        final apiUrl = config.apiUrl;
        final response = await http.get(
          Uri.parse('$apiUrl/login?name=$email&pass=$password'),
        );

        if (response.statusCode == 200) {
          List<dynamic> jsonResponse = jsonDecode(response.body);
          Map<String, dynamic> resMap = jsonResponse.first;

          if (resMap.containsKey('home_id')) {
            var homeid = resMap['home_id'];
            users.home_id = homeid;
          } else {
            print('Response does not contain home_id');
          }
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(users: users),
            ),
          );
          Fluttertoast.showToast(
              msg: "Login Successful",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
          loginSuccessful = true;
        } else if (response.statusCode == 401) {
          print('Failed to fetch data: ${response.statusCode}');
          Fluttertoast.showToast(
              msg: "Invalid email or password",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        } else {
          Fluttertoast.showToast(
              msg: "An error occurred. Please try again later.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      } catch (e) {
        print('Error: $e');
        Fluttertoast.showToast(
            msg: "An error occurred. Please try again later.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return SizedBox();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  backgroundColor: Colors.blue.shade800,
                  elevation: 4,
                  padding: EdgeInsets.all(40),
                ),
                child: Text(
                  'H. A. A.',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelText: 'User ID',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
                obscureText: obscureText,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: obscureText
                        ? Icon(Icons.visibility_off)
                        : Icon(Icons.visibility),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(email, password),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.users}) : super(key: key);
  final User users;
  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomePage(users: widget.users),
          ProfilePage(users: widget.users),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.users}) : super(key: key);
  final User users;
  @override
  State createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('Img.png'),
              ),
              SizedBox(height: 20),
              Text(
                '${widget.users}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '${widget.users}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                isSemanticButton: _enabled,
                onPressed: () {
                  setState(() {
                    _enabled = !_enabled;
                  });
                },
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                enabled: _enabled,
                decoration: InputDecoration(
                  labelText: '9658737000',
                  prefixIcon: Icon(Icons.phone),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                enabled: _enabled,
                decoration: InputDecoration(
                  labelText: 'yashjadhav7000@gmail.com',
                  prefixIcon: Icon(Icons.mail),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                enabled: _enabled,
                decoration: InputDecoration(
                  labelText: '13/09/2002',
                  prefixIcon: Icon(Icons.cake),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Provider.of<MyAppState>(context, listen: false)
                      .resetLoginState();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                },
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
class homeDetails {
  // ignore: non_constant_identifier_names
  late String home_name = '';
  // ignore: non_constant_identifier_names
  late String room_type = '';
  // ignore: non_constant_identifier_names
  late int room_id = 0;
  homeDetails(this.home_name, this.room_type, this.room_id);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.users}) : super(key: key);
  final User users;

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late homeDetails hd;
  int len = 0;
  late String name = '';
  int count = 0;

  @override
  void initState() {
    super.initState();
    hd = homeDetails('', '', 0);
    fetchdetails(widget.users.home_id);
  }

  late List<dynamic> roomTypeList = [];
  late List<dynamic> roomIdList = [];
  var icon = Icon(Icons.king_bed);

  Future<void> _refreshRoomList() async {
    setState(() {
      fetchdetails(widget.users.home_id);
    });
  }

  Future<void> fetchdetails(int homeid) async {
    final AppConfig config = await AppConfig.forEnvironment();
    final apiUrl = config.apiUrl;
    final response = await http.get(
      Uri.parse('$apiUrl/home?home_id=${widget.users.home_id}'),
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      roomTypeList.clear();
      roomIdList.clear();
      Map<String, dynamic> resMap = jsonResponse.first;
      for (resMap in jsonResponse) {
        if (resMap.containsKey('home_name') &&
            resMap.containsKey('room_type') &&
            resMap.containsKey('room_id')) {
          var roomType = resMap['room_type'];
          var roomId = resMap['room_id'];
          var homename = resMap['home_name'];
          roomTypeList.add(roomType);
          roomIdList.add(roomId);
          len = roomTypeList.length;
          if (count == 0) {
            setState(() {
              hd.home_name = homename;
            });
            count = count + 1;
          }
        } else {
          print('Response does not contain details');
        }
      }
    } else if (response.statusCode == 401) {
      print('Failed to fetch data: ${response.statusCode}');
    } else {
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again later.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> addroom(int homeid, String homename, String roomtype) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.post(
        Uri.parse(
            '$apiUrl/addroom?home_id=$homeid&home_name=$homename&room_type=$roomtype'),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Room added",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (response.statusCode == 401) {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteRoom(int roomid) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/deleteroom?room_id=$roomid'),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Room deleted",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (response.statusCode == 401) {
        print('Failed to delete room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          hd.home_name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<String>(
          context: context,
          builder: (BuildContext context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Add Room'),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      labelText: 'Room name',
                      prefixIcon: Icon(Icons.king_bed_rounded),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Close'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (name.isEmpty) {
                            Fluttertoast.showToast(
                                msg: "Name Required",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          } else {
                            addroom(widget.users.home_id, hd.home_name, name);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRoomList,
        child: FutureBuilder<void>(
          future: fetchdetails(widget.users.home_id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () {
                        fetchdetails(widget.users.home_id);
                      },
                      child: Text('Retry'),
                    )
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: len,
                itemBuilder: (context, len) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: icon,
                        title: Text(roomTypeList[len]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailPage(
                                homeid: widget.users.home_id,
                                roomid: roomIdList[len],
                                roomname: roomTypeList[len],
                              ),
                            ),
                          );
                        },
                        trailing: PopupMenuButton(
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry>[
                            PopupMenuItem(
                              onTap: () {
                                deleteRoom(roomIdList[len]);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded),
                                  SizedBox(width: 8),
                                  Text('Info'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class RoomDetails {
  // ignore: non_constant_identifier_names
  late String device_type = '';
  // ignore: non_constant_identifier_names
  late int device_id = 0;
  // ignore: non_constant_identifier_names
  late int state = 0;
  RoomDetails(this.device_type, this.device_id, this.state);
}

@immutable
class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage(
      {Key? key,
      required this.homeid,
      required this.roomid,
      required this.roomname})
      : super(key: key);
  final int homeid;
  final int roomid;
  final String roomname;

  @override
  State createState() => _RoomDetailState();
}

class _RoomDetailState extends State<RoomDetailPage> {
  late RoomDetails rd;
  int rlen = 0;
  int dlen = 0;
  late List<dynamic> deviceTypeList = [];
  late List<dynamic> deviceStateList = [];
  late List<dynamic> deviceIdList = [];
  late List<dynamic> addDeviceTypeList = [];
  late List<dynamic> addDeviceIdList = [];

  @override
  void initState() {
    super.initState();
    fetchdetails(widget.roomid);
  }

  Future<void> fetchdetails(int roomid) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/room?room_id=$roomid'),
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        deviceTypeList.clear();
        deviceIdList.clear();
        deviceStateList.clear();
        Map<String, dynamic> resMap = jsonResponse.first;
        for (resMap in jsonResponse) {
          var devicetype = resMap['device_type'];
          deviceTypeList.add(devicetype);
          var deviceid = resMap['device_id'];
          deviceIdList.add(deviceid);
          var devicestate = resMap['state'];
          deviceStateList.add(devicestate);
        }
        rlen = deviceTypeList.length;
        setState(() {});
      } else if (response.statusCode == 401) {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchdevices(int homeid) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/devices?home_id=$homeid'),
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        addDeviceTypeList.clear();
        addDeviceIdList.clear();
        Map<String, dynamic> resMap = jsonResponse.first;
        for (resMap in jsonResponse) {
          var addDevicetype = resMap['device_type'];
          addDeviceTypeList.add(addDevicetype);
          var addDeviceid = resMap['device_id'];
          addDeviceIdList.add(addDeviceid);
          dlen = addDeviceTypeList.length;
          setState(() {});
        }
      } else if (response.statusCode == 401) {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomname,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return FutureBuilder<void>(
                future: fetchdevices(widget.homeid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    if (addDeviceTypeList.isEmpty) {
                      return AlertDialog(
                        title: Text('No Devices Available'),
                        content: Text('There are no devices available to add.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    } else {
                      return Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text('Add Device to room'),
                              const SizedBox(height: 15),
                              // ignore: sized_box_for_whitespace
                              Container(
                                height: 200,
                                child: ListView.builder(
                                  itemCount: dlen,
                                  itemBuilder: (context, dlen) {
                                    return DeviceDetailCard(
                                      title: addDeviceTypeList[dlen],
                                      deviceid: addDeviceIdList[dlen],
                                      roomid: widget.roomid,
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchdetails(widget.roomid);
        },
        child: Builder(
          builder: (context) {
            if (rlen == 0) {
              return Center(child: Text('No rooms available.'));
            } else {
              return ListView.builder(
                itemCount: rlen,
                itemBuilder: (context, rlen) {
                  return RoomDetailCard(
                    title: deviceTypeList[rlen],
                    deviceid: deviceIdList[rlen],
                    state: deviceStateList[rlen],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class RoomDetailCard extends StatefulWidget {
  const RoomDetailCard(
      {Key? key,
      required this.title,
      required this.deviceid,
      required this.state})
      : super(key: key);
  final String title;
  final int deviceid;
  final int state;

  @override
  State createState() => _RoomDetailCardState();
}

class _RoomDetailCardState extends State<RoomDetailCard> {
  bool _switchValue = false;
  late RoomDetailCard rdc;

  @override
  void initState() {
    super.initState();
    if (widget.state == 2) {
      _switchValue = true;
    } else if (widget.state == 1) {
      _switchValue = false;
    }
  }

  Future<void> changestate(int deviceid, int state) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/changestate?device_id=$deviceid&state=$state'),
      );
      if (response.statusCode == 200) {
        print('Fetched data successfully');
      } else if (response.statusCode == 401) {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteDevice(int deviceid) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/deletedevice?device_id=$deviceid'),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Device deleted",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (response.statusCode == 401) {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.deviceid} ${widget.title}'),
              // ignore: avoid_unnecessary_containers
              Container(
                child: Row(
                  children: [
                    Switch(
                      value: _switchValue,
                      onChanged: (value) {
                        setState(() {
                          _switchValue = value;
                        });
                        changestate(widget.deviceid, value ? 2 : 1);
                      },
                    ),
                    PopupMenuButton(
                      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () {
                            deleteDevice(widget.deviceid);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded),
                              SizedBox(width: 8),
                              Text('Info'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceDetailCard extends StatefulWidget {
  const DeviceDetailCard(
      {Key? key,
      required this.title,
      required this.deviceid,
      required this.roomid})
      : super(key: key);
  final String title;
  final int deviceid;
  final int roomid;

  @override
  State createState() => _DeviceDetailCardState();
}

class _DeviceDetailCardState extends State<DeviceDetailCard> {
  Future<void> addDeviceRoom(int roomid, int deviceid) async {
    try {
      final AppConfig config = await AppConfig.forEnvironment();
      final apiUrl = config.apiUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/adddevice?room_id=$roomid&device_id=$deviceid'),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Device added",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (response.statusCode == 401) {
        print('Failed to add device : ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.deviceid} ${widget.title}'),
              TextButton.icon(
                onPressed: () async {
                  addDeviceRoom(widget.roomid, widget.deviceid);
                  Navigator.pop(context);
                  setState(() {});
                },
                icon: Icon(Icons.ac_unit_sharp),
                label: Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
