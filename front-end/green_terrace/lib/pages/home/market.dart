import 'package:flutter/material.dart';
import 'package:green_terrace/models/market_page.dart';

class Market extends StatelessWidget {
  const Market({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      body: MarketPage(),
    );
  }
}