import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IllnessCropScreen extends StatefulWidget {
  const IllnessCropScreen({super.key});

  @override
  State<IllnessCropScreen> createState() => _IllnessCropScreenState();
}

class _IllnessCropScreenState extends State<IllnessCropScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _isLoading = true);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://plant-disease-api-2-5ykk.onrender.com/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        setState(() {
          _result = jsonData;
        });
      } else {
        setState(() => _result = {'error': 'فشل التحليل، حاول مرة أخرى'});
      }
    } catch (e) {
      setState(() => _result = {'error': 'خطأ في الاتصال بالخادم'});
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌿 كاشف أمراض النباتات'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(_image!, height: 200, width: 200, fit: BoxFit.cover),
                ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text('جاري تحليل الصورة...', style: TextStyle(fontSize: 16)),
              ],
              if (_result != null && !_isLoading) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_result!.containsKey('error'))
                          Text(
                            '⚠️ ${_result!['error']}',
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                          )
                        else if (_result!['status'] == 'rejected')
                          Text(
                            '🚫 ${_result!['message']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                          )
                        else ...[
                          Row(
                            children: [
                              Icon(_result!['healthy'] ? Icons.verified : Icons.warning,
                                  color: _result!['healthy'] ? Colors.green : Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _result!['healthy'] ? '✅ النبات سليم' : '⚠️ النبات مريض',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text('🌱 التشخيص: ${_result!['disease']}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('💊 العلاج: ${_result!['treatment']}', style: const TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('التقاط صورة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('اختر من المعرض'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}