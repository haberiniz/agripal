
import 'package:flutter/material.dart';
class IllnessCropScreen extends StatefulWidget {
  const IllnessCropScreen({super.key});

  @override
  State<IllnessCropScreen> createState() => _IllnessCropScreenState();
}

class _IllnessCropScreenState extends State<IllnessCropScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Illness Crop Screen'),
      ),
      body: const Center(
        child: Text('Illness Crop Screen'),
      ),
    );
  }
}