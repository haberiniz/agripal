import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/screens/home_screen.dart';
import 'package:agripal/core/constants/app_colors.dart';

class FarmLocationScreen extends StatefulWidget {
  const FarmLocationScreen({super.key});

  @override
  State<FarmLocationScreen> createState() => _FarmLocationScreenState();
}

class _FarmLocationScreenState extends State<FarmLocationScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _sheetAnim;
  late AnimationController _fabAnim;
  late Animation<double> _sheetSlide;
  late Animation<double> _fabScale;

  LatLng? _selectedLocation;
  LatLng? _currentPosition;
  bool _isDrawingMode = false;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  bool _showManualInput = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _searchDebounce;
  OverlayEntry? _overlayEntry;

  final List<LatLng> _polygonPoints = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  double _calculatedArea = 0;
  MapType _mapType = MapType.hybrid;

  // ← اسم الموقع الحقيقي المحدد (من GPS أو من البحث)
  String _realLocationName = '';

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _sheetSlide =
        CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic);
    _fabScale = CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut);
    _getUserLocation();
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    _fabAnim.dispose();
    _latController.dispose();
    _lngController.dispose();
    _areaController.dispose();
    _farmNameController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _removeSearchOverlay();
    super.dispose();
  }

  // ── GPS ───────────────────────────────────────────────────────────
  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showError('يرجى تفعيل خدمة GPS في الإعدادات');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _showError('يرجى منح إذن الموقع للتطبيق');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final loc = LatLng(position.latitude, position.longitude);

      // ← جلب اسم الموقع الحقيقي عبر Reverse Geocoding
      final realName =
          await _reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = loc;
          _selectedLocation = loc;
          _latController.text = loc.latitude.toStringAsFixed(6);
          _lngController.text = loc.longitude.toStringAsFixed(6);
          _realLocationName = realName;
          // ← عرض اسم الموقع الحقيقي في شريط البحث
          _searchController.text = realName;
        });
        final ctrl = await _mapController.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
        _updateSingleMarker(loc);
      }
    } catch (e) {
      if (mounted) _showError('تعذر تحديد الموقع، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // ── Reverse Geocoding (Nominatim) ─────────────────────────────────
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=ar',
      );
      final res =
          await http.get(uri, headers: {'User-Agent': 'AgriPalApp/1.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // أولوية: قرية > بلدة > مدينة > بلدية > ولاية
        return (addr['village'] as String?) ??
            (addr['town'] as String?) ??
            (addr['city'] as String?) ??
            (addr['municipality'] as String?) ??
            (addr['county'] as String?) ??
            (addr['state'] as String?) ??
            'موقعي';
      }
    } catch (_) {}
    return 'موقعي';
  }

  // ── Search via Nominatim (OpenStreetMap) ─────────────────────────
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      _removeSearchOverlay();
      return;
    }
    _searchDebounce = Timer(
        const Duration(milliseconds: 600), () => _doSearch(query.trim()));
  }

  Future<void> _doSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=5&accept-language=ar',
      );
      final res =
          await http.get(uri, headers: {'User-Agent': 'AgriPalApp/1.0'});
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _searchResults = data
                .map((e) => {
                      'name': e['display_name'] as String,
                      'lat': double.parse(e['lat'] as String),
                      'lng': double.parse(e['lon'] as String),
                    })
                .toList();
          });
          _showSearchOverlay();
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    if (_searchResults.isEmpty) return;

    final overlay = Overlay.of(context);
    final statusBarH = MediaQuery.of(context).padding.top;
    final topOffset = statusBarH + 12 + 44 + 10 + 48 + 4;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topOffset,
        left: 12,
        right: 12,
        child: Material(
          elevation: 20,
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _searchResults.map((result) {
                final name = result['name'] as String;
                final parts = name.split(',');
                final shortName = parts.first.trim();
                final subName = parts.skip(1).take(2).join(',').trim();
                return InkWell(
                  onTap: () {
                    _removeSearchOverlay();
                    _selectSearchResult(result);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shortName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              if (subName.isNotEmpty)
                                Text(subName,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeSearchOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final loc = LatLng(result['lat'] as double, result['lng'] as double);
    final fullName = result['name'] as String;
    final shortName = fullName.split(',').first.trim();

    setState(() {
      _selectedLocation = loc;
      _searchResults = [];
      _searchController.text = shortName;
      _latController.text = loc.latitude.toStringAsFixed(6);
      _lngController.text = loc.longitude.toStringAsFixed(6);
      // ← حفظ اسم الموقع الحقيقي من نتيجة البحث
      _realLocationName = shortName;
    });
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
    _updateSingleMarker(loc);
  }

  // ── Map ───────────────────────────────────────────────────────────
  void _onMapTap(LatLng position) {
    setState(() => _searchResults = []);
    _removeSearchOverlay();
    FocusScope.of(context).unfocus();
    if (_isDrawingMode) {
      setState(() {
        _polygonPoints.add(position);
        _updatePolygonDrawing();
      });
    } else {
      setState(() {
        _selectedLocation = position;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _updateSingleMarker(position);
      });
      // ← عند النقر على الخريطة نجلب اسم الموقع تلقائياً
      _reverseGeocode(position.latitude, position.longitude).then((name) {
        if (mounted) {
          setState(() {
            _realLocationName = name;
            _searchController.text = name;
          });
        }
      });
    }
  }

  void _updateSingleMarker(LatLng pos) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'موقع الأرض'),
        ),
      };
    });
  }

  void _updatePolygonDrawing() {
    if (_polygonPoints.isEmpty) {
      _polylines = {};
      _polygons = {};
      _markers = {};
      return;
    }
    _markers = _polygonPoints.asMap().entries.map((e) {
      return Marker(
        markerId: MarkerId('pt_${e.key}'),
        position: e.value,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(title: 'نقطة ${e.key + 1}'),
      );
    }).toSet();
    if (_polygonPoints.length >= 2) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('drawing'),
          points: [..._polygonPoints, _polygonPoints.first],
          color: AppColors.primary,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }
    if (_polygonPoints.length >= 3) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('farm'),
          points: _polygonPoints,
          fillColor: AppColors.primary.withValues(alpha: 0.25),
          strokeColor: AppColors.primary,
          strokeWidth: 3,
        ),
      };
      _calculatedArea = _calculatePolygonArea(_polygonPoints);
      _areaController.text = _calculatedArea >= 10000
          ? '${(_calculatedArea / 10000).toStringAsFixed(2)} هكتار'
          : '${_calculatedArea.toStringAsFixed(0)} م²';
    }
  }

  double _calculatePolygonArea(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    const R = 6371000.0;
    double area = 0;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      final lat1 = pts[i].latitude * pi / 180;
      final lat2 = pts[j].latitude * pi / 180;
      final dLng = (pts[j].longitude - pts[i].longitude) * pi / 180;
      area += dLng * (2 + sin(lat1) + sin(lat2));
    }
    return (area * R * R / 2).abs();
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _updatePolygonDrawing();
        if (_polygonPoints.length < 3) {
          _areaController.clear();
          _calculatedArea = 0;
        }
      });
    }
  }

  void _clearDrawing() {
    setState(() {
      _polygonPoints.clear();
      _polygons = {};
      _polylines = {};
      _markers = {};
      _calculatedArea = 0;
      _areaController.clear();
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode && _polygonPoints.length < 3) _clearDrawing();
    });
  }

  // ── Save ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_selectedLocation == null && _polygonPoints.length < 3) {
      _showError('يرجى تحديد موقع الأرض أو رسمها على الخريطة');
      return;
    }
    if (_farmNameController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم المزرعة');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = _polygonPoints.length >= 3
          ? _polygonPoints
                  .map((p) => p.latitude)
                  .reduce((a, b) => a + b) /
              _polygonPoints.length
          : _selectedLocation!.latitude;
      final lng = _polygonPoints.length >= 3
          ? _polygonPoints
                  .map((p) => p.longitude)
                  .reduce((a, b) => a + b) /
              _polygonPoints.length
          : _selectedLocation!.longitude;

      await prefs.setDouble('farm_lat', lat);
      await prefs.setDouble('farm_lng', lng);
      // ← احفظ اسم المزرعة (ما يختاره المستخدم)
      await prefs.setString('farm_name', _farmNameController.text.trim());

      // ← احفظ اسم الموقع الحقيقي (من GPS أو البحث أو Reverse Geocoding)
      String locationName = _realLocationName.trim();
      if (locationName.isEmpty) {
        // آخر محاولة: نجلبه الآن
        locationName = await _reverseGeocode(lat, lng);
      }
      await prefs.setString('farm_location_name', locationName);

      await prefs.setDouble('farm_area', _calculatedArea);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(36.7, 3.05),
              zoom: _currentPosition != null ? 17 : 6,
            ),
            mapType: _mapType,
            onMapCreated: (c) => _mapController.complete(c),
            onTap: _onMapTap,
            markers: _markers,
            polygons: _polygons,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Top Controls ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row
                  Row(
                    children: [
                      _glassCard(
                        child: const Icon(Icons.agriculture_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _glassCard(
                          wide: true,
                          child: const Text(
                            'حدد موقع أرضك',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _glassCard(
                        onTap: () => setState(() => _mapType =
                            _mapType == MapType.hybrid
                                ? MapType.normal
                                : MapType.hybrid),
                        child: Icon(
                          _mapType == MapType.hybrid
                              ? Icons.map_outlined
                              : Icons.satellite_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Search bar + زر موقعي ──
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            textDirection: TextDirection.rtl,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن قرية، مدينة...',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13),
                              prefixIcon: _isSearching
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    )
                                  : Icon(Icons.search_rounded,
                                      color: AppColors.primary, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults = [];
                                          _realLocationName = '';
                                        });
                                        _removeSearchOverlay();
                                      },
                                      child: Icon(Icons.close_rounded,
                                          color: Colors.grey.shade400,
                                          size: 18),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 13),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // زر موقعي
                      GestureDetector(
                        onTap:
                            _isLoadingLocation ? null : _getUserLocation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoadingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.my_location_rounded,
                                  color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Drawing banner ──
          if (_isDrawingMode)
            Positioned(
              top: 175,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('انقر على الخريطة لرسم حدود أرضك',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text('${_polygonPoints.length} نقطة',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),

          // ── FABs ──
          Positioned(
            right: 12,
            bottom: 390,
            child: Column(
              children: [
                ScaleTransition(
                  scale: _fabScale,
                  child: _buildFab(
                    icon: _isDrawingMode
                        ? Icons.close_rounded
                        : Icons.draw_rounded,
                    onTap: _toggleDrawingMode,
                    tooltip: _isDrawingMode ? 'إيقاف' : 'رسم الأرض',
                    active: _isDrawingMode,
                  ),
                ),
                if (_isDrawingMode && _polygonPoints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _fabScale,
                    child: _buildFab(
                        icon: Icons.undo_rounded,
                        onTap: _undoLastPoint,
                        tooltip: 'تراجع'),
                  ),
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _fabScale,
                    child: _buildFab(
                        icon: Icons.delete_outline_rounded,
                        onTap: _clearDrawing,
                        tooltip: 'مسح',
                        danger: true),
                  ),
                ],
              ],
            ),
          ),

          // ── Bottom Sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 1), end: Offset.zero)
                  .animate(_sheetSlide),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F1A0F)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, -4)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),

                      if (_calculatedArea > 0) _buildAreaBadge(),

                      _buildSectionLabel('اسم المزرعة'),
                      _buildTextField(
                        controller: _farmNameController,
                        hint: 'مثال: مزرعة الوادي الخضراء',
                        icon: Icons.agriculture_rounded,
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => setState(
                            () => _showManualInput = !_showManualInput),
                        child: Row(
                          children: [
                            _buildSectionLabel('الإحداثيات اليدوية'),
                            const Spacer(),
                            Icon(
                              _showManualInput
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      if (_showManualInput) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _latController,
                                hint: 'خط العرض',
                                icon: Icons.location_on_rounded,
                                keyboardType: TextInputType.number,
                                onChanged: _onManualCoordChanged,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _lngController,
                                hint: 'خط الطول',
                                icon: Icons.location_on_outlined,
                                keyboardType: TextInputType.number,
                                onChanged: _onManualCoordChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _areaController,
                          hint: 'المساحة (اختياري)',
                          icon: Icons.square_foot_rounded,
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildStatusRow(),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 20),
                                    SizedBox(width: 8),
                                    Text('حفظ والمتابعة',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onManualCoordChanged(_) {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      final pos = LatLng(lat, lng);
      setState(() => _selectedLocation = pos);
      _updateSingleMarker(pos);
      _mapController.future
          .then((c) => c.animateCamera(CameraUpdate.newLatLngZoom(pos, 16)));
      // ← جلب اسم الموقع من الإحداثيات اليدوية أيضاً
      _reverseGeocode(lat, lng).then((name) {
        if (mounted) {
          setState(() {
            _realLocationName = name;
            _searchController.text = name;
          });
        }
      });
    }
  }

  Widget _glassCard(
      {required Widget child, VoidCallback? onTap, bool wide = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: wide ? 14 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFab({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool active = false,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: danger
              ? Colors.red.shade600
              : active
                  ? AppColors.primary
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (active ? AppColors.primary : Colors.black)
                  .withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon,
            color: (active || danger) ? Colors.white : AppColors.primary,
            size: 22),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAreaBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.accent.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.square_foot_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مساحة الأرض المحسوبة',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey)),
              Text(_areaController.text,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final hasPolygon = _polygonPoints.length >= 3;
    final hasPin = _selectedLocation != null;
    return Row(
      children: [
        _statusChip(
          icon: Icons.draw_rounded,
          label: hasPolygon
              ? 'مرسومة (${_polygonPoints.length} نقطة)'
              : 'لم يتم رسم الأرض',
          ok: hasPolygon,
        ),
        const SizedBox(width: 8),
        _statusChip(
          icon: Icons.location_on_rounded,
          label: hasPin ? 'تم تحديد الموقع' : 'لا يوجد موقع',
          ok: hasPin,
        ),
      ],
    );
  }

  Widget _statusChip(
      {required IconData icon,
      required String label,
      required bool ok}) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ok
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ok
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: ok ? AppColors.primary : Colors.grey.shade400),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      ok ? AppColors.primary : Colors.grey.shade500,
                  fontWeight:
                      ok ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}