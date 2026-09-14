import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    _cameras = await availableCameras();
    // Gunakan kamera depan
    final frontCamera = _cameras?.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    if (frontCamera != null) {
      _controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final image = await _controller!.takePicture();
    setState(() => _capturedImage = image);
  }

  void _uploadFace() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final token = await StorageService().getToken();
      final uri = Uri.parse('${ApiClient.baseUrl}/face/register');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('image', _capturedImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      setState(() => _isUploading = false);

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi Wajah Berhasil!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal mendaftar wajah'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Wajah')),
      body: Column(
        children: [
          Expanded(
            child: _capturedImage != null
                ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover, width: double.infinity)
                : _isCameraInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isUploading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_capturedImage != null)
                        OutlinedButton(
                          onPressed: () => setState(() => _capturedImage = null),
                          child: const Text('Ulangi Foto'),
                        ),
                      ElevatedButton.icon(
                        onPressed: _capturedImage == null ? _takePicture : _uploadFace,
                        icon: Icon(_capturedImage == null ? Icons.camera_alt : Icons.cloud_upload),
                        label: Text(_capturedImage == null ? 'Ambil Foto Wajah' : 'Simpan Wajah'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}