import 'package:flutter/material.dart';
import 'package:green_terrace/pages/community.dart';
import 'package:green_terrace/pages/home.dart';
import 'package:green_terrace/pages/market.dart';

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
    return  Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 136, 247, 140),
          title: Center(
            child: Text(
              "Green Terrace",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
      );
  }
}