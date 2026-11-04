import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final AuthService _authService = AuthService();

  UserModel? _user;
  String _baseUrl = '';
  bool _isLoading = true;
  bool _hasActiveWorkstation = false;
  Map<String, dynamic>? _workstationData;
  bool _isDisconnectingWorkstation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final user = await _storage.getUser();
    final url = await _storage.getBaseUrl();
    setState(() {
      _user = user;
      _baseUrl = url;
      _isLoading = false;
    });
    _loadWorkstationStatus();
  }

  Future<void> _loadWorkstationStatus() async {
    final status = await _authService.checkActiveWorkstation();
    if (!mounted) return;
    setState(() {
      _hasActiveWorkstation = status['has_active_session'] == true;
      _workstationData = status['session'];
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Keluar dari vi-token?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Keluar dari vi-token akan otomatis memutuskan seluruh sesi komputer workstation aktif yang sedang berjalan. Lanjutkan?',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _confirmDisconnectWorkstation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Putuskan Sesi Komputer?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Layar browser workstation di komputer akan langsung logout seketika dan operator harus memindai ulang QR untuk masuk. Lanjutkan?',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isDisconnectingWorkstation = true;
              });

              final res = await _authService.remoteLogout();

              if (!mounted) return;
              setState(() {
                _isDisconnectingWorkstation = false;
              });

              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('Sesi komputer workstation berhasil diputuskan!'),
                  ),
                );
                _loadWorkstationStatus();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red[800],
                    content: Text(res['message'] ?? 'Gagal memutuskan sesi komputer'),
                  ),
                );
              }
            },
            child: const Text('Ya, Putuskan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Manual Session Input (Sangat berguna saat testing di Emulator / PC tanpa kamera fisik)
  void _showManualInputModal() {
    final sessionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Input Session ID Manual', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan fitur ini jika testing di emulator atau tanpa webcam/kamera fisik:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sessionController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'Paste Session ID dari layar browser...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              String raw = sessionController.text.trim();
              if (raw.startsWith('vipharma:qr:')) {
                raw = raw.replaceFirst('vipharma:qr:', '');
              }
              if (raw.isNotEmpty) {
                Navigator.pop(ctx);
                _authorizeManual(raw);
              }
            },
            child: const Text('Otorisasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _authorizeManual(String sessionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
    );

    final res = await _authService.authorizeQR(sessionId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (res['success'] == true) {
      _loadWorkstationStatus();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Sukses!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Sesi browser vi-pharma berhasil diotorisasi! Layar web sekarang menampilkan pilihan cabang.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red[800], content: Text(res['message'] ?? 'Gagal otorisasi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            Text(
              'vi-token',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: () async {
                _loadProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                            child: Text(
                              (_user?.name.isNotEmpty == true) ? _user!.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.name ?? 'User',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _user?.role.toUpperCase() ?? 'ROLE',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '@${_user?.username ?? ''}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Workstation Card (Remote Logout Feature)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _hasActiveWorkstation
                            ? const Color(0xFF10B981).withOpacity(0.08)
                            : const Color(0xFF1E293B).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasActiveWorkstation
                              ? const Color(0xFF10B981).withOpacity(0.35)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _hasActiveWorkstation ? const Color(0xFF10B981) : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _hasActiveWorkstation ? 'Workstation Komputer Terhubung' : 'Workstation Tidak Terhubung',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _hasActiveWorkstation ? Colors.white : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                                tooltip: 'Segarkan status workstation',
                                onPressed: _loadWorkstationStatus,
                              ),
                            ],
                          ),
                          if (_hasActiveWorkstation) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.desktop_windows_outlined, size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _workstationData != null && _workstationData!['branch_name'] != null
                                          ? 'Cabang: ${_workstationData!['branch_name']}'
                                          : 'Sesi web browser workstation aktif',
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.18),
                                  foregroundColor: const Color(0xFFFCA5A5),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isDisconnectingWorkstation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(color: Color(0xFFFCA5A5), strokeWidth: 2),
                                      )
                                    : const Icon(Icons.lock_reset, size: 16),
                                label: Text(
                                  _isDisconnectingWorkstation ? 'Memutuskan Sesi...' : '🔒 Putuskan Sesi Komputer',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _isDisconnectingWorkstation ? null : _confirmDisconnectWorkstation,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'Pindai QR pada monitor komputer untuk login ke sistem kasir & farmasi.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Scan Action Card
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                        _loadWorkstationStatus();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF047857), Color(0xFF065F46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 34),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Pindai QR vi-pharma',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Arahkan kamera ke monitor komputer untuk otorisasi login',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Fallback Manual Input Button (Great for PC emulator)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[300],
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.keyboard_outlined, size: 18),
                      label: const Text('Input Session ID Manual (Testing / Emulator)', style: TextStyle(fontSize: 12)),
                      onPressed: _showManualInputModal,
                    ),

                    const SizedBox(height: 24),

                    // Server Info Footer
                    Center(
                      child: Text(
                        'Target Server: $_baseUrl',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }
}
