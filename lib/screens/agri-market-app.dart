import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary = Color(0xFF55833D);
  static const Color primaryDark = Color(0xFF3F642D);
  static const Color backgroundSoft = Color(0xFFF6F8F4);
  static const Color textDark = Color(0xFF1F2937);
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AgriMarketApp());
}

class AgriMarketApp extends StatelessWidget {
  const AgriMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السوق الزراعي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MarketplacePage(),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

enum SupplierCategory {
  fertilizers,
  seeds,
  irrigationTools,
  farmingEquipment,
  plantProtection,
  agriculturalServices,
}

extension SupplierCategoryExt on SupplierCategory {
  String get label => switch (this) {
        SupplierCategory.fertilizers => 'الأسمدة',
        SupplierCategory.seeds => 'البذور',
        SupplierCategory.irrigationTools => 'أدوات الري',
        SupplierCategory.farmingEquipment => 'المعدات الزراعية',
        SupplierCategory.plantProtection => 'حماية النبات',
        SupplierCategory.agriculturalServices => 'خدمات زراعية',
      };

  Color get color => switch (this) {
        SupplierCategory.fertilizers => const Color(0xFF524133),
        SupplierCategory.seeds => const Color(0xFF55833D),
        SupplierCategory.irrigationTools => const Color(0xFF1B6CA8),
        SupplierCategory.farmingEquipment => const Color(0xFF524133),
        SupplierCategory.plantProtection => const Color(0xFF55833D),
        SupplierCategory.agriculturalServices => const Color(0xFF7C6A52),
      };

  Color get bgColor => color.withOpacity(0.12);

  IconData get icon => switch (this) {
        SupplierCategory.fertilizers => Icons.science_outlined,
        SupplierCategory.seeds => Icons.grass_outlined,
        SupplierCategory.irrigationTools => Icons.water_drop_outlined,
        SupplierCategory.farmingEquipment => Icons.agriculture_outlined,
        SupplierCategory.plantProtection => Icons.health_and_safety_outlined,
        SupplierCategory.agriculturalServices => Icons.handshake_outlined,
      };

  String get emoji => switch (this) {
        SupplierCategory.fertilizers => '🔬',
        SupplierCategory.seeds => '🌱',
        SupplierCategory.irrigationTools => '💧',
        SupplierCategory.farmingEquipment => '🚜',
        SupplierCategory.plantProtection => '🛡️',
        SupplierCategory.agriculturalServices => '🤝',
      };
}

class Supplier {
  final String id;
  final String name;
  final SupplierCategory category;
  final String description;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isSponsored;
  final String? logoEmoji;
  final List<String> tags;
  final String phone;

  const Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.rating,
    required this.reviewCount,
    this.isVerified = false,
    this.isSponsored = false,
    this.logoEmoji,
    this.tags = const [],
    this.phone = '',
  });
}

// ─── Sample Data — موردون جزائريون ────────────────────────────────────────────

final List<Supplier> _defaultSuppliers = [
  const Supplier(
    id: '1',
    name: 'مؤسسة بن عمر للبذور',
    category: SupplierCategory.seeds,
    description: 'بذور خضروات وحبوب محلية عالية الإنتاجية مكيّفة مع المناخ الجزائري. نوفر بذور البطاطا، الطماطم، الفلفل والشعير.',
    location: 'عنابة، الجزائر',
    rating: 4.6,
    reviewCount: 134,
    isVerified: true,
    logoEmoji: '🌾',
    tags: ['بذور محلية', 'خضروات', 'حبوب'],
    phone: '0661234501',
  ),
  const Supplier(
    id: '2',
    name: 'شركة السهول الخضراء للأسمدة',
    category: SupplierCategory.fertilizers,
    description: 'أسمدة عضوية ومركبة NPK مناسبة لتربة الشمال الجزائري. متوفرة بالجملة والتجزئة لجميع ولايات الجزائر.',
    location: 'سطيف، الجزائر',
    rating: 4.5,
    reviewCount: 89,
    isVerified: true,
    logoEmoji: '🧪',
    tags: ['NPK', 'عضوي', 'جملة وتجزئة'],
    phone: '0551234502',
  ),
  const Supplier(
    id: '3',
    name: 'مؤسسة الواحة لمعدات الري',
    category: SupplierCategory.irrigationTools,
    description: 'توريد وتركيب أنظمة الري بالتنقيط والرش للمساحات الصغيرة والكبيرة. خبرة أكثر من 15 سنة في ولايات الجنوب والهضاب.',
    location: 'بسكرة، الجزائر',
    rating: 4.7,
    reviewCount: 212,
    isVerified: true,
    logoEmoji: '💧',
    tags: ['ري بالتنقيط', 'تركيب', 'ضمان'],
    phone: '0771234503',
  ),
  const Supplier(
    id: '4',
    name: 'EAMA — المعدات الزراعية',
    category: SupplierCategory.farmingEquipment,
    description: 'مؤسسة جزائرية متخصصة في بيع وإيجار وصيانة الجرارات والحصادات والمحاريث. وكيل معتمد لماركات دولية.',
    location: 'تيارت، الجزائر',
    rating: 4.4,
    reviewCount: 167,
    isVerified: true,
    logoEmoji: '🚜',
    tags: ['جرارات', 'صيانة', 'إيجار'],
    phone: '0661234504',
  ),
  const Supplier(
    id: '5',
    name: 'مزرعة الأطلس — خضر وفواكه',
    category: SupplierCategory.agriculturalServices,
    description: 'توريد مباشر للخضر والفواكه الموسمية من المزرعة إلى الزبون. نوفر خدمة التوصيل للأسواق والمطاعم والجمعيات.',
    location: 'تيزي وزو، الجزائر',
    rating: 4.8,
    reviewCount: 298,
    isVerified: true,
    logoEmoji: '🍅',
    tags: ['طازج', 'توصيل', 'موسمي'],
    phone: '0551234505',
  ),
  const Supplier(
    id: '6',
    name: 'محل الفلاح لمبيدات النبات',
    category: SupplierCategory.plantProtection,
    description: 'مبيدات حشرية وفطرية ومبيدات أعشاب معتمدة من وزارة الفلاحة. استشارة مجانية لمكافحة الآفات الزراعية.',
    location: 'وهران، الجزائر',
    rating: 4.3,
    reviewCount: 75,
    isVerified: true,
    logoEmoji: '🛡️',
    tags: ['مبيدات معتمدة', 'استشارة مجانية'],
    phone: '0771234506',
  ),
  const Supplier(
    id: '7',
    name: 'تعاونية التمور الذهبية',
    category: SupplierCategory.agriculturalServices,
    description: 'تسويق وتصدير تمور دقلة نور ودجلة بيضاء من وادي ريغ وسوف. نوفر التعبئة والتغليف حسب المواصفات الدولية.',
    location: 'الوادي، الجزائر',
    rating: 4.9,
    reviewCount: 341,
    isVerified: true,
    logoEmoji: '🌴',
    tags: ['دقلة نور', 'تصدير', 'تعبئة دولية'],
    phone: '0661234507',
  ),
];

final List<Supplier> _defaultSponsored = [
  const Supplier(
    id: 'sp1',
    name: 'Fertial — سوناطراك للأسمدة',
    category: SupplierCategory.fertilizers,
    description: 'أسمدة نيتروجينية وفوسفاتية بأسعار تنافسية من أكبر منتج للأسمدة في الجزائر. توزيع في كامل التراب الوطني.',
    location: 'عنابة / أرزيو، الجزائر',
    rating: 4.8,
    reviewCount: 520,
    isVerified: true,
    isSponsored: true,
    logoEmoji: '🏭',
    tags: ['نيتروجين', 'فوسفات', 'وطني'],
    phone: '0381234508',
  ),
  const Supplier(
    id: 'sp2',
    name: 'مجمع AGRODIV الزراعي',
    category: SupplierCategory.seeds,
    description: 'شركة وطنية لإنتاج وتوزيع البذور المحسّنة. نوفر بذور معتمدة للحبوب والخضر والأعلاف لكل الولايات.',
    location: 'الجزائر العاصمة، الجزائر',
    rating: 4.7,
    reviewCount: 634,
    isVerified: true,
    isSponsored: true,
    logoEmoji: '🌱',
    tags: ['بذور معتمدة', 'وطني', 'جملة'],
    phone: '0211234509',
  ),
];

// ─── Plan Model ───────────────────────────────────────────────────────────────

enum PublishPlan { small, medium, more }

extension PublishPlanExt on PublishPlan {
  String get planName => switch (this) {
        PublishPlan.small => 'Small',
        PublishPlan.medium => 'Medium',
        PublishPlan.more => 'More',
      };
  String get price => switch (this) {
        PublishPlan.small => '1500 دج',
        PublishPlan.medium => '3000 دج',
        PublishPlan.more => '5000 دج',
      };
  String get desc => switch (this) {
        PublishPlan.small => 'ظهور عادي في القائمة',
        PublishPlan.medium => 'ظهور أكثر + أولوية في البحث',
        PublishPlan.more => 'ظهور غير محدود + قسم مميز',
      };
  bool get isRecommended => this == PublishPlan.medium;
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with TickerProviderStateMixin {
  SupplierCategory? _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // All mutable suppliers (default + user-added)
  late List<Supplier> _allMutableSuppliers;
  late List<Supplier> _allMutableSponsored;

  @override
  void initState() {
    super.initState();
    _allMutableSuppliers = List.from(_defaultSuppliers);
    _allMutableSponsored = List.from(_defaultSponsored);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Supplier> get _filteredRegular => _allMutableSuppliers.where((s) {
        final matchCat =
            _selectedCategory == null || s.category == _selectedCategory;
        final matchSearch = _searchQuery.isEmpty ||
            s.name.toLowerCase().contains(_searchQuery) ||
            s.description.toLowerCase().contains(_searchQuery) ||
            s.location.toLowerCase().contains(_searchQuery) ||
            s.tags.any((t) => t.toLowerCase().contains(_searchQuery));
        return matchCat && matchSearch;
      }).toList();

  void _addSupplier(Supplier s) {
    setState(() {
      if (s.isSponsored) {
        _allMutableSponsored.insert(0, s);
      } else {
        _allMutableSuppliers.insert(0, s);
      }
    });
  }

  void _deleteSupplier(String id) {
    setState(() {
      _allMutableSuppliers = _allMutableSuppliers.where((s) => s.id != id).toList();
      _allMutableSponsored = _allMutableSponsored.where((s) => s.id != id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف الإعلان بنجاح'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف الإعلان', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('هل تريد حذف إعلان "$name" نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteSupplier(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSupplierSheet(onPublish: _addSupplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sponsored = _allMutableSponsored;
    final regular = _filteredRegular;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSoft,
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddModal,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 28),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryFilters()),
              if (sponsored.isNotEmpty &&
                  _selectedCategory == null &&
                  _searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                    child: _buildSectionHeader('⭐ الشركاء المميزون',
                        sponsored: true)),
                SliverToBoxAdapter(child: _buildSponsoredRow(sponsored)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '${regular.length} مورد موثق',
                  trailing:
                      '${_allMutableSuppliers.where((s) => s.isVerified).length} إجمالي',
                ),
              ),
              if (regular.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SupplierCard(
                      supplier: regular[i],
                      onDelete: () => _confirmDelete(regular[i].id, regular[i].name),
                    ),
                    childCount: regular.length,
                  ),
                ),
              SliverToBoxAdapter(child: _buildBottomCTA()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      surfaceTintColor: Colors.transparent,
      actions: [
        TextButton.icon(
          onPressed: _openAddModal,
          icon: const Icon(Icons.add, color: Colors.white, size: 16),
          label: const Text(
            'إضافة إعلان',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🌾', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'السوق الزراعي الجزائري',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'موردون جزائريون موثوقون للبذور والأسمدة والمعدات والخدمات',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 12,
                      height: 1.4,
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

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتجات أو موردين أو مدن...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.grey.shade400,
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _CategoryChip(
              label: 'الكل',
              icon: Icons.apps_rounded,
              color: AppColors.primary,
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            const SizedBox(width: 8),
            ...SupplierCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryChip(
                    label: cat.label,
                    icon: cat.icon,
                    color: cat.color,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() {
                      _selectedCategory =
                          _selectedCategory == cat ? null : cat;
                    }),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {bool sponsored = false, String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          if (sponsored)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
              ),
              child: const Text('مدفوع',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF856404),
                      letterSpacing: 0.5)),
            ),
          if (sponsored) const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const Spacer(),
          if (trailing != null)
            Text(trailing,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSponsoredRow(List<Supplier> suppliers) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suppliers.length,
        itemBuilder: (ctx, i) => _SponsoredCard(
          supplier: suppliers[i],
          onDelete: () => _confirmDelete(suppliers[i].id, suppliers[i].name),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('لا يوجد موردون',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('جرب بحثاً أو فئة مختلفة',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('طوّر أعمالك 🚀',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
              'انضم إلى آلاف الموردين الجزائريين الذين يصلون إلى المزارعين في كل ولايات الجزائر.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  fontSize: 12,
                  height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CTAButton(
                  label: 'أصبح مورداً',
                  icon: Icons.storefront_outlined,
                  onTap: _openAddModal,
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CTAButton(
                  label: 'طلب عرض سعر',
                  icon: Icons.request_quote_outlined,
                  onTap: () {},
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : color.withOpacity(0.25), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color)),
        ]),
      ),
    );
  }
}

// ─── Phone Dialog ─────────────────────────────────────────────────────────────

void showPhoneDialog(BuildContext context, Supplier supplier) {
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: supplier.category.bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(supplier.logoEmoji ?? '🏢',
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 12),
            Text(supplier.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    supplier.phone,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Clipboard.setData(
                        ClipboardData(text: supplier.phone));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رقم الهاتف ✓'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('نسخ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}

// ─── Sponsored Card ───────────────────────────────────────────────────────────

class _SponsoredCard extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onDelete;
  const _SponsoredCard({required this.supplier, required this.onDelete});

  @override
  State<_SponsoredCard> createState() => _SponsoredCardState();
}

class _SponsoredCardState extends State<_SponsoredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 210,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                s.category.color.withOpacity(0.12),
                s.category.color.withOpacity(0.04)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: s.category.color.withOpacity(0.25), width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(s.logoEmoji ?? '🏢',
                    style: const TextStyle(fontSize: 26)),
                const Spacer(),
                // Delete button
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.delete_outline,
                        size: 14, color: Colors.red.shade400),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('★ مميز',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF856404))),
                ),
              ]),
              const SizedBox(height: 10),
              Text(s.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(s.description,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(children: [
                Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                const SizedBox(width: 3),
                Text(s.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => showPhoneDialog(context, s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: s.category.color,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.phone, size: 11, color: Colors.white),
                      SizedBox(width: 4),
                      Text('اتصال',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supplier Card ────────────────────────────────────────────────────────────

class _SupplierCard extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onDelete;

  const _SupplierCard({required this.supplier, required this.onDelete});

  @override
  State<_SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends State<_SupplierCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: s.category.bgColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(s.logoEmoji ?? '🏢',
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          if (s.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        size: 10, color: Color(0xFF059669)),
                                    SizedBox(width: 3),
                                    Text('موثق',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669))),
                                  ]),
                            ),
                          ],
                          // Delete button — visible for ALL cards
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 10, color: Colors.red.shade400),
                                    const SizedBox(width: 3),
                                    Text('حذف',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade400)),
                                  ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: s.category.bgColor,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.category.icon,
                                    size: 10, color: s.category.color),
                                const SizedBox(width: 4),
                                Text(s.category.label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: s.category.color)),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(s.description,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                if (s.tags.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: s.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.backgroundSoft,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Text(s.location,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Icon(Icons.star_rounded,
                      size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 3),
                  Text('${s.rating.toStringAsFixed(1)} (${s.reviewCount})',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(width: 10),
                  // Phone button — opens dialog showing the number
                  GestureDetector(
                    onTap: () => showPhoneDialog(context, s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: s.category.color,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('اتصال',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ]),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CTA Button ───────────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _CTAButton(
      {required this.label,
      required this.icon,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  filled ? Colors.transparent : Colors.white.withOpacity(0.6),
              width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 15,
              color: filled ? AppColors.textDark : Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: filled ? AppColors.textDark : Colors.white)),
        ]),
      ),
    );
  }
}

// ─── Add Supplier Sheet ───────────────────────────────────────────────────────

class _AddSupplierSheet extends StatefulWidget {
  final void Function(Supplier) onPublish;
  const _AddSupplierSheet({required this.onPublish});

  @override
  State<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<_AddSupplierSheet> {
  int _step = 0; // 0=info, 1=plan, 2=payment, 3=success

  final _nameCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  SupplierCategory _category = SupplierCategory.fertilizers;

  PublishPlan? _selectedPlan;

  final _cardNameCtrl = TextEditingController();
  final _cardNumCtrl = TextEditingController();
  final _cardExpCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _productCtrl, _priceCtrl, _locationCtrl,
      _descCtrl, _phoneCtrl, _cardNameCtrl, _cardNumCtrl,
      _cardExpCtrl, _cardCvvCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _productCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'يرجى ملء الحقول الإلزامية (الاسم، المنتج، رقم الهاتف)')),
        );
        return;
      }
    }
    if (_step == 1) {
      if (_selectedPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار خطة أولاً')),
        );
        return;
      }
    }
    if (_step == 2) {
      if (_cardNameCtrl.text.trim().isEmpty ||
          _cardNumCtrl.text.trim().isEmpty ||
          _cardExpCtrl.text.trim().isEmpty ||
          _cardCvvCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى ملء جميع بيانات البطاقة')),
        );
        return;
      }
      final s = Supplier(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        category: _category,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : _productCtrl.text.trim(),
        location: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : 'الجزائر',
        rating: 5.0,
        reviewCount: 0,
        isVerified: true,
        isSponsored: _selectedPlan == PublishPlan.more,
        logoEmoji: '🏢',
        tags: [
          _productCtrl.text.trim(),
          if (_priceCtrl.text.trim().isNotEmpty) _priceCtrl.text.trim(),
        ],
        phone: _phoneCtrl.text.trim(),
      );
      widget.onPublish(s);
    }
    setState(() => _step++);
  }

  void _prevStep() => setState(() => _step--);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Text(
                  _step == 0
                      ? 'نشر إعلان جديد'
                      : _step == 1
                          ? 'اختر خطة النشر'
                          : _step == 2
                              ? 'الدفع'
                              : 'تم النشر!',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (_step < 3)
                Row(children: List.generate(3, (i) {
                  final done = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      height: 4,
                      decoration: BoxDecoration(
                          color: done
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  );
                })),
              const SizedBox(height: 20),
              if (_step == 0) _buildStep1(),
              if (_step == 1) _buildStep2(),
              if (_step == 2) _buildStep3(),
              if (_step == 3) _buildSuccess(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الخطوة 1/3 — معلومات الإعلان',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      const SizedBox(height: 16),
      _Field(
          label: 'اسم الشركة / المورد *',
          ctrl: _nameCtrl,
          hint: 'مثال: مؤسسة بن علي للأسمدة'),
      _Field(
          label: 'المنتج / الخدمة المعروضة *',
          ctrl: _productCtrl,
          hint: 'مثال: أسمدة عضوية، بذور خضر، معدات ري'),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('الفئة',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SupplierCategory>(
              value: _category,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(10),
              items: SupplierCategory.values
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child:
                          Text(c.label, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ]),
      _Field(
          label: 'السعر / نطاق السعر',
          ctrl: _priceCtrl,
          hint: 'مثال: من 2000 إلى 8000 دج'),
      _Field(
          label: 'الولاية / المدينة',
          ctrl: _locationCtrl,
          hint: 'مثال: عنابة، سطيف، الجزائر العاصمة'),
      _Field(
          label: 'وصف مختصر',
          ctrl: _descCtrl,
          hint: 'اكتب وصفاً مختصراً للمنتج أو الخدمة...',
          maxLines: 3),
      _Field(
          label: 'رقم الهاتف للتواصل *',
          ctrl: _phoneCtrl,
          hint: 'مثال: 0661234567',
          keyboard: TextInputType.phone),
      _NavButtons(onNext: _nextStep, nextLabel: 'التالي ← اختر الخطة'),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الخطوة 2/3 — اختر خطة النشر',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      const SizedBox(height: 16),
      Row(
        children: PublishPlan.values.map((p) {
          final selected = _selectedPlan == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlan = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.backgroundSoft : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          selected ? AppColors.primary : Colors.grey.shade200,
                      width: selected ? 2 : 1.5),
                ),
                child: Column(children: [
                  if (p.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('موصى به',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  Text(p.planName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(p.price,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text(p.desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          height: 1.4)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      if (_selectedPlan != null)
        Center(
          child: Text(
            'اخترت: ${_selectedPlan!.planName} — ${_selectedPlan!.price}',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic),
          ),
        ),
      const SizedBox(height: 8),
      _NavButtons(
          onNext: _nextStep, onBack: _prevStep, nextLabel: 'التالي ← الدفع'),
    ]);
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الخطوة 3/3 — معلومات الدفع',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.credit_card_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('بيانات البطاقة',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          _Field(
              label: 'اسم صاحب البطاقة',
              ctrl: _cardNameCtrl,
              hint: 'محمد أمين بن علي'),
          _Field(
              label: 'رقم البطاقة',
              ctrl: _cardNumCtrl,
              hint: '1234 5678 9012 3456',
              keyboard: TextInputType.number,
              inputFormatters: [_CardNumberFormatter()]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _Field(
                    label: 'تاريخ الانتهاء',
                    ctrl: _cardExpCtrl,
                    hint: 'MM/YY',
                    keyboard: TextInputType.number,
                    inputFormatters: [_ExpFormatter()])),
            const SizedBox(width: 12),
            Expanded(
                child: _Field(
                    label: 'رمز CVV',
                    ctrl: _cardCvvCtrl,
                    hint: '123',
                    keyboard: TextInputType.number,
                    maxLen: 3)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ملخص الطلب',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('الخطة',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(_selectedPlan?.planName ?? '-',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('المبلغ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(_selectedPlan?.price ?? '-',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _NavButtons(
          onNext: _nextStep,
          onBack: _prevStep,
          nextLabel: '✅ تأكيد النشر'),
    ]);
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('تم نشر إعلانك بنجاح!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
              'إعلانك الآن مرئي للمزارعين والموردين في الجزائر.\nسيتواصل معك العملاء على الرقم: ${_phoneCtrl.text.trim()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.6)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إغلاق',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Reusable Field ───────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final int? maxLen;
  final TextInputType keyboard;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.maxLen,
    this.keyboard = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        maxLength: maxLen,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }
}

// ─── Nav Buttons ──────────────────────────────────────────────────────────────

class _NavButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;

  const _NavButtons(
      {required this.onNext, this.onBack, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(nextLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
      if (onBack != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('→ رجوع', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    ]);
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 16));
    final formatted =
        limited.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 4));
    final formatted = limited.length >= 3
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}