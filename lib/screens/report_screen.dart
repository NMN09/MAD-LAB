import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/db_service.dart';

class ReportScreen extends StatefulWidget {
  final String userId;

  ReportScreen({required this.userId});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  String category = 'Safety'; // Default
  Uint8List? _imageBytes;
  String _fileName = '';
  bool isUploading = false;

  final List<String> categories = [
    'Safety',
    'Infrastructure',
    'Facilities',
    'Cleanliness'
  ];

  Future getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name;
      });
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Report Issue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Issue Details',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide clear information and an image of the problem.',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Short description of the problem',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (val) => val!.isEmpty ? 'Please enter a title' : null,
                onChanged: (val) => setState(() => title = val),
              ),
              const SizedBox(height: 20.0),
              
              DropdownButtonFormField(
                value: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) => setState(() => category = val.toString()),
              ),
              const SizedBox(height: 20.0),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us more about where and what the issue is...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 4,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter a description' : null,
                onChanged: (val) => setState(() => description = val),
              ),
              const SizedBox(height: 30.0),
              
              // Image Section
              Text(
                'Evidence (Required)',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: getImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Tap to capture / upload', style: TextStyle(color: Colors.grey[500])),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    onPressed: getImage,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40.0),
              
              isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        child: Text(
                          'Submit Report',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_imageBytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select an image first.')),
                              );
                              return;
                            }

                            setState(() => isUploading = true);

                            try {
                              // Convert bytes to Base64 data URI string
                              String base64Image = 'data:image/jpeg;base64,' + base64Encode(_imageBytes!);

                              await _db.submitComplaint(
                                title: title,
                                description: description,
                                category: category,
                                imageBase64: base64Image,
                                userId: widget.userId,
                                userEmail: '',
                              );
                              Navigator.pop(context); // Go back after success
                            } catch (e) {
                              setState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error uploading: ' + e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
