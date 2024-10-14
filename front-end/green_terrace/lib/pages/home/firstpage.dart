import 'package:flutter/material.dart';
import 'package:green_terrace/pages/home/community.dart';
import 'package:green_terrace/pages/home/home.dart';
import 'package:green_terrace/pages/home/market.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _selectedIndex = 0;
  void _navigateBottomBar(int index){
    setState(() {
        if(_selectedIndex != index){
          _selectedIndex = index;
        }
      });
  }
  //List of pages
  final List _pages = [
    //home
    Home(),
    //market
    Market(),
    //community
    Community(),
  ];
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Defining the theme colors
        primaryColor: Colors.green, // Green for buttons, AppBar, etc.
        scaffoldBackgroundColor: Colors.black, // Black background for screens
        iconTheme: IconThemeData(color: Colors.green), // Green icons
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.green,
          ),
           bodyMedium: TextStyle(
            color: Colors.green,
          ),
           bodySmall: TextStyle(
            color: Colors.green,
          ),
          displaySmall: TextStyle(
            color: Colors.green,
          ),
          headlineSmall: TextStyle(
            color: Colors.grey[900]
          ),
          headlineLarge: TextStyle(
            color: Colors.green
          ),
          titleSmall: TextStyle(
            color: Colors.green,
          ),
          titleLarge: TextStyle(
            color: Colors.green,
          ),
          titleMedium: TextStyle(
            color: Colors.green,
          ),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.grey[900],
          textColor: Colors.green,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black, // Black AppBar background
          titleTextStyle: TextStyle(
            color: Colors.green[500],
            fontSize: 25,
            fontFamily: ""
            ), // White AppBar text
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.green, // Green buttons
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[900]
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              "Green Terrace",
              )
            ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navigateBottomBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
              ),
              BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: "Market",
              ),
              BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Community",
            )
          ]
        ),
      ),
    );
  }
}