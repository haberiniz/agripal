// irrigation_page.dart
// 🌾 Système Agricole Algérien Intelligent v3.0
// Design élégant avec animations et couleurs officielles

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// ============================================================
// 🎨 COULEURS DE L'APPLICATION
// ============================================================
class AppColors {
  static const Color primaryDark = Color(0xFF524133);
  static const Color primary = Color(0xFF55833D);
  static const Color backgroundSoft = Color(0xFFE3EED4);
  static const Color accent = Color(0xFFE1D4C2);
  static const Color textDark = Color(0xFF3E2F24);
  static const Color textLight = Color(0xFFF5F0E8);
  static const Color backgr = Color.fromARGB(255, 255, 255, 255);

  // Extra helpers
  static const Color cardBg = Color(0xFFFAF8F3);
  static const Color divider = Color(0xFFD4C9B5);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);
}

// ============================================================
// 📍 58 WILAYAS D'ALGÉRIE
// ============================================================
const List<String> kWilayas = [
  'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna',
  'Béjaïa', 'Biskra', 'Béchar', 'Blida', 'Bouira',
  'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret', 'Tizi Ouzou',
  'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda',
  'Skikda', 'Sidi Bel Abbès', 'Annaba', 'Guelma', 'Constantine',
  'Médéa', 'Mostaganem', "M'Sila", 'Mascara', 'Ouargla',
  'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arreridj', 'Boumerdès',
  'El Tarf', 'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela',
  'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 'Naâma',
  'Aïn Témouchent', 'Ghardaïa', 'Relizane', 'Timimoun',
  'Bordj Badji Mokhtar', 'Ouled Djellal', 'Béni Abbès', 'In Salah',
  'In Guezzam', 'Touggourt', 'Djanet', "El M'Ghair", 'El Menia',
];

// ============================================================
// 🌾 50+ CULTURES GROUPÉES
// ============================================================
const Map<String, List<String>> kCulturesByCategory = {
  '🌾 Céréales': [
    'Blé dur', 'Blé tendre', 'Orge', 'Maïs', 'Sorgho', 'Avoine',
  ],
  '🥦 Maraîchage': [
    'Tomate', 'Pomme de terre', 'Oignon', 'Ail', 'Poivron',
    'Courgette', 'Aubergine', 'Carotte', 'Laitue', 'Pastèque',
    'Melon', 'Piment fort', 'Navet', 'Artichaut',
  ],
  '🫘 Légumineuses': [
    'Pois chiche', 'Lentille', 'Fève', 'Haricot vert', 'Petits pois',
  ],
  '🌳 Arboriculture': [
    'Olivier', 'Palmier dattier', 'Figuier', 'Grenadier', 'Vigne',
    'Amandier', 'Abricotier', 'Pêcher', 'Prunier', 'Cerisier',
    'Agrumes (Oranger)', 'Citronnier',
  ],
  '🏭 Industrie': [
    'Tournesol', 'Betterave sucrière', 'Coton', 'Tabac',
  ],
  '🌿 Fourrages': [
    'Luzerne', 'Vesce-avoine',
  ],
  '🌴 Oasis': [
    'Henné', 'Tomate saharienne',
  ],
  '🏠 Sous serre': [
    'Concombre sous serre', 'Tomate sous serre',
  ],
  '🌺 Aromates': [
    'Coriandre', 'Aneth', 'Cumin', 'Géranium rosat', 'Safran',
  ],
};

List<String> get kAllCultures =>
    kCulturesByCategory.values.expand((l) => l).toList();

// ============================================================
// 🌦️ MAIN PAGE
// ============================================================
class IrrigationPage extends StatefulWidget {
  const IrrigationPage({Key? key}) : super(key: key);

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage>
    with TickerProviderStateMixin {
  // --- State ---
  String _selectedWilaya = 'Blida';
  String _selectedCulture = 'Tomate';
  DateTime _datePlantation = DateTime.now().subtract(Duration(days: 45));
  Map<String, dynamic>? _data;
  bool _loading = false;
  String _error = '';

  // API base – change to your deployed URL
  final String _apiBase = 'https://agri-irrigation-api.onrender.com';

  // --- Animations ---
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _waveAnim = Tween(begin: 0.0, end: 2 * pi).animate(_waveCtrl);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  // ---- Fetch ----
  Future<void> _fetchRecommendation() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      _data = null;
    });
    _fadeCtrl.reset();

    final dateStr =
        '${_datePlantation.year}-${_datePlantation.month.toString().padLeft(2, '0')}-${_datePlantation.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
        '$_apiBase/irrigation?wilaya=${Uri.encodeComponent(_selectedWilaya)}&culture=${Uri.encodeComponent(_selectedCulture)}&date_plantation=$dateStr');

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        setState(() => _data = json.decode(res.body));
        _fadeCtrl.forward();
      } else {
        setState(() => _error = 'Erreur serveur: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Connexion échouée: $e');
    }

    setState(() => _loading = false);
  }

  // ---- Date Picker ----
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datePlantation,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textLight,
            surface: AppColors.backgroundSoft,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _datePlantation = picked);
  }

  // ---- Culture Picker Dialog ----
  Future<void> _pickCulture() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CulturePickerSheet(
        selected: _selectedCulture,
        categories: kCulturesByCategory,
      ),
    );
    if (result != null) setState(() => _selectedCulture = result);
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildCalculateButton(),
                const SizedBox(height: 20),
                if (_error.isNotEmpty) _buildErrorCard(),
                if (_loading) _buildLoadingWidget(),
                if (_data != null) ...[
                  _buildWeatherCard(),
                  const SizedBox(height: 12),
                  _buildIrrigationCard(),
                  const SizedBox(height: 12),
                  _buildForecastCard(),
                  const SizedBox(height: 12),
                  _buildAdviceCard(),
                  const SizedBox(height: 32),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔷 APP BAR avec animation vague
  // ============================================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _waveAnim,
          builder: (_, __) => CustomPaint(
            painter: _WavePainter(phase: _waveAnim.value),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Text('🌾', style: TextStyle(fontSize: 48)),
                    Text(
                      'Système Agricole Algérien',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'نظام الري الذكي الجزائري',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📋 CARTE DE SAISIE
  // ============================================================
  Widget _buildInputCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('📍 Informations de base'),
          const SizedBox(height: 16),

          // Wilaya
          _DropdownField<String>(
            label: 'Wilaya (Région)',
            icon: Icons.location_on,
            value: _selectedWilaya,
            items: kWilayas
                .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                .toList(),
            onChanged: (v) => setState(() => _selectedWilaya = v!),
          ),
          const SizedBox(height: 14),

          // Culture (custom picker)
          InkWell(
            onTap: _pickCulture,
            borderRadius: BorderRadius.circular(12),
            child: _FieldDecoration(
              label: 'Culture',
              icon: Icons.grass,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCulture,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textDark),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Date de plantation
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: _FieldDecoration(
              label: 'Date de plantation',
              icon: Icons.calendar_today,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_datePlantation.day.toString().padLeft(2, '0')}/${_datePlantation.month.toString().padLeft(2, '0')}/${_datePlantation.year}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textDark),
                    ),
                  ),
                  const Icon(Icons.edit_calendar,
                      color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔘 BOUTON CALCULER
  // ============================================================
  Widget _buildCalculateButton() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _loading ? 1.0 : _pulseAnim.value,
        child: child,
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _fetchRecommendation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.textLight))
              : const Icon(Icons.water_drop_rounded, size: 24),
          label: Text(
            _loading ? 'Analyse en cours...' : 'Calculer la recommandation',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ❌ ERREUR
  // ============================================================
  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_error,
                  style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }

  // ============================================================
  // ⏳ LOADING
  // ============================================================
  Widget _buildLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Récupération des données météo en temps réel...',
              style: TextStyle(color: AppColors.primaryDark)),
          SizedBox(height: 4),
          Text('جاري جلب بيانات الطقس الحقيقية...',
              style: TextStyle(color: AppColors.primary, fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================================
  // 🌤️ CARTE MÉTÉO ACTUELLE
  // ============================================================
  Widget _buildWeatherCard() {
    final d = _data!;
    final forecast = d['forecast_7j'] as List? ?? [];
    final today = forecast.isNotEmpty ? forecast[0] : null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('🌦️ Météo Temps Réel – ${d['wilaya']}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WeatherMiniCard(
                    icon: '☀️',
                    label: 'Jours secs',
                    value: '${d['jours_sans_pluie']} j',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WeatherMiniCard(
                    icon: '🌡️',
                    label: 'Temp. demain',
                    value: today != null
                        ? '${today['temp_max']}°C'
                        : '–',
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WeatherMiniCard(
                    icon: '💧',
                    label: 'Pluie 7j',
                    value:
                        '${d['analyse_pluie']?['total_7j'] ?? 0} mm',
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.terrain,
                      color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type de sol: ${d['soil_type']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                fontSize: 13)),
                        Text('Rétention: ${d['soil_retention']}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 💧 CARTE IRRIGATION
  // ============================================================
  Widget _buildIrrigationCard() {
    final d = _data!;
    final urgence = d['niveau_urgence'] as String? ?? '';
    final quantite = d['quantite_eau'] as num? ?? 0;
    final stade = d['stade'] as String? ?? '';
    final prog = d['progression_pct'] as int? ?? 0;

    Color urgenceColor = AppColors.success;
    if (urgence.contains('FORTE')) urgenceColor = AppColors.danger;
    else if (urgence.contains('MODÉRÉE') || urgence.contains('NORMALE')) urgenceColor = AppColors.warning;
    else if (urgence.contains('LÉGÈRE')) urgenceColor = const Color(0xFFFFD54F);

    return FadeTransition(
      opacity: _fadeAnim,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('💧 Recommandation d\'Irrigation'),
            const SizedBox(height: 14),

            // Urgence badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: urgenceColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: urgenceColor.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(urgence,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: urgenceColor)),
                  const SizedBox(height: 4),
                  Text(
                    quantite > 0
                        ? '$quantite L/m² – ${d['frequence_recommandee'] ?? ''}'
                        : 'Aucune irrigation nécessaire',
                    style: TextStyle(
                        color: urgenceColor.withOpacity(0.8), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quantité eau (jauge)
            if (quantite > 0) ...[
              const Text('Volume recommandé:',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (quantite / 12).clamp(0.0, 1.0),
                  minHeight: 18,
                  backgroundColor: AppColors.accent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(urgenceColor),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('$quantite L/m²',
                    style: TextStyle(
                        color: urgenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],

            // Stade
            _InfoRow(
                icon: Icons.eco,
                label: 'Stade végétatif',
                value: '$stade ($prog%)'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: prog / 100,
                minHeight: 10,
                backgroundColor: AppColors.accent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Raison
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d['raison_ajustement'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Type irrigation
            _IrrigationTypeWidget(
              typeIrrigation: d['type_irrigation'] ?? '',
              detail: d['irrigation_detail'] as Map? ?? {},
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📅 PRÉVISIONS 7 JOURS
  // ============================================================
  Widget _buildForecastCard() {
    final forecast = (_data!['forecast_7j'] as List? ?? []);
    return FadeTransition(
      opacity: _fadeAnim,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('📅 Prévisions Météo – 7 Jours'),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = forecast[i];
                  final hasPluie = p['a_pluie'] == true;
                  return _ForecastDayCard(
                    date: p['date'] ?? '',
                    jour: p['jour'] ?? i + 1,
                    tempMax: (p['temp_max'] as num?)?.toDouble() ?? 0,
                    tempMin: (p['temp_min'] as num?)?.toDouble() ?? 0,
                    precip: (p['precipitation'] as num?)?.toDouble() ?? 0,
                    hasPluie: hasPluie,
                    desc: p['description'] ?? '',
                    vent: (p['vent_kmh'] as num?)?.toDouble() ?? 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 💡 CONSEILS DÉTAILLÉS
  // ============================================================
  Widget _buildAdviceCard() {
    final conseils = (_data!['conseils_detailles'] as List? ?? []);
    final stress = (_data!['stress_hydrique'] as num?)?.toDouble() ?? 1.0;
    final culture = _data!['culture'] ?? '';
    final cat = _data!['categorie_culture'] ?? '';
    final culturear = _data!['culture_ar'] ?? '';

    return FadeTransition(
      opacity: _fadeAnim,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('💡 Conseils & Détails'),
            const SizedBox(height: 10),

            // Culture info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grass, color: AppColors.textLight, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(culture,
                          style: const TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('$culturear  •  $cat',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('Stress: ${(stress * 100 - 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: stress > 1.2
                                  ? AppColors.danger
                                  : AppColors.backgroundSoft,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text('hydrique',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            ...conseils.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.toString(),
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🧩 WIDGETS RÉUTILISABLES
// ============================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldDecoration(
      label: label,
      icon: icon,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FieldDecoration extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _FieldDecoration({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _WeatherMiniCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _WeatherMiniCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _IrrigationTypeWidget extends StatelessWidget {
  final String typeIrrigation;
  final Map detail;

  const _IrrigationTypeWidget(
      {required this.typeIrrigation, required this.detail});

  @override
  Widget build(BuildContext context) {
    if (typeIrrigation.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('Irrigation: $typeIrrigation',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13)),
            ],
          ),
          if (detail['description'] != null) ...[
            const SizedBox(height: 4),
            Text(detail['description'].toString(),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDark)),
          ],
          if (detail['efficacite'] != null) ...[
            const SizedBox(height: 2),
            Text('Efficacité: ${detail['efficacite']}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500)),
          ],
          if (detail['debit'] != null) ...[
            const SizedBox(height: 2),
            Text('Débit: ${detail['debit']}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.primaryDark)),
          ],
        ],
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  final String date;
  final int jour;
  final double tempMax;
  final double tempMin;
  final double precip;
  final bool hasPluie;
  final String desc;
  final double vent;

  const _ForecastDayCard({
    required this.date,
    required this.jour,
    required this.tempMax,
    required this.tempMin,
    required this.precip,
    required this.hasPluie,
    required this.desc,
    required this.vent,
  });

  @override
  Widget build(BuildContext context) {
    final parts = date.split('-');
    final label = parts.length == 3 ? '${parts[2]}/${parts[1]}' : 'J$jour';
    final iconStr = desc.isNotEmpty ? desc.split(' ')[0] : (hasPluie ? '🌧' : '☀️');
    final bgColor = hasPluie
        ? AppColors.info.withOpacity(0.1)
        : AppColors.backgroundSoft;
    final borderColor = hasPluie
        ? AppColors.info.withOpacity(0.3)
        : AppColors.divider;

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(iconStr, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text('${tempMax.round()}° / ${tempMin.round()}°',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textDark,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            hasPluie ? '💧 ${precip}mm' : '💨 ${vent.round()}km/h',
            style: TextStyle(
                fontSize: 10,
                color: hasPluie ? AppColors.info : AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🌿 CULTURE PICKER BOTTOM SHEET
// ============================================================
class _CulturePickerSheet extends StatefulWidget {
  final String selected;
  final Map<String, List<String>> categories;

  const _CulturePickerSheet(
      {required this.selected, required this.categories});

  @override
  State<_CulturePickerSheet> createState() => _CulturePickerSheetState();
}

class _CulturePickerSheetState extends State<_CulturePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = <String, List<String>>{};
    for (final e in widget.categories.entries) {
      final items = e.value
          .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
          .toList();
      if (items.isNotEmpty) filtered[e.key] = items;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Choisir une culture 🌾',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: filtered.entries.map((e) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Text(e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              fontSize: 13)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: e.value.map((c) {
                        final isSelected = c == widget.selected;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.backgroundSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                            ),
                            child: Text(c,
                                style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textLight
                                        : AppColors.textDark,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🌊 WAVE PAINTER pour l'AppBar
// ============================================================
class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    for (int w = 0; w < 2; w++) {
      final path = Path();
      path.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.6 +
            sin((x / size.width * 2 * pi) + phase + w * pi / 2) * 20 -
            w * 15;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}