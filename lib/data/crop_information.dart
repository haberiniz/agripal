// crop_information.dart
// قاعدة بيانات المحاصيل الزراعية - 20 محصول شائع
// يُستخدم من قِبل recommendation_screen.dart

class CropInfo {
  final String cropId;
  final String cropName;
  final String emoji;
  final int cycleDays;
  final String description;
  final ClimateInfo climate;
  final SoilRequirements soil;
  final IrrigationGuide irrigation;
  final List<FertilizationStage> fertilization;
  final List<CropDisease> diseases;
  final List<String> companionGood;
  final List<String> companionBad;
  final List<String> doList;
  final List<String> dontList;
  final List<GrowthStage> growthStages;
  final String plantingMethod;
  final String harvestMethod;

  const CropInfo({
    required this.cropId,
    required this.cropName,
    required this.emoji,
    required this.cycleDays,
    required this.description,
    required this.climate,
    required this.soil,
    required this.irrigation,
    required this.fertilization,
    required this.diseases,
    required this.companionGood,
    required this.companionBad,
    required this.doList,
    required this.dontList,
    required this.growthStages,
    required this.plantingMethod,
    required this.harvestMethod,
  });
}

class ClimateInfo {
  final double minTempC;
  final double maxTempC;
  final double optimalTempC;
  final double minHumidityPct;
  final double maxHumidityPct;
  final double annualRainfallMm;
  final String sunExposure; // full, partial
  final String windTolerance; // low, medium, high

  const ClimateInfo({
    required this.minTempC,
    required this.maxTempC,
    required this.optimalTempC,
    required this.minHumidityPct,
    required this.maxHumidityPct,
    required this.annualRainfallMm,
    required this.sunExposure,
    required this.windTolerance,
  });
}

class SoilRequirements {
  final List<String> suitableSoils;
  final double minPH;
  final double maxPH;
  final double optimalPH;
  final String drainage;
  final String organicMatter;
  final String texture;

  const SoilRequirements({
    required this.suitableSoils,
    required this.minPH,
    required this.maxPH,
    required this.optimalPH,
    required this.drainage,
    required this.organicMatter,
    required this.texture,
  });
}

class IrrigationGuide {
  final double waterNeedMmPerWeek; // احتياج مائي أسبوعي بالملم
  final double waterNeedLitersPerHectarePerWeek;
  final String frequency; // وتيرة الري
  final String bestTime; // أفضل وقت للري
  final Map<String, double> stageWaterMultiplier; // مضاعف الماء حسب المرحلة
  final Map<String, String> irrigationTypeAdvice; // نصيحة حسب نوع الري
  final Map<String, String> soilTypeAdvice; // نصيحة حسب نوع التربة
  final List<String> generalTips;

  const IrrigationGuide({
    required this.waterNeedMmPerWeek,
    required this.waterNeedLitersPerHectarePerWeek,
    required this.frequency,
    required this.bestTime,
    required this.stageWaterMultiplier,
    required this.irrigationTypeAdvice,
    required this.soilTypeAdvice,
    required this.generalTips,
  });
}

class FertilizationStage {
  final String stageName;
  final int fromDay;
  final int toDay;
  final String fertilizerType;
  final String fertilizerName;
  final double quantityPer100Sqm; // كمية لكل 100 م²
  final String applicationMethod; // طريقة التطبيق
  final String applicationTime;
  final String notes;

  const FertilizationStage({
    required this.stageName,
    required this.fromDay,
    required this.toDay,
    required this.fertilizerType,
    required this.fertilizerName,
    required this.quantityPer100Sqm,
    required this.applicationMethod,
    required this.applicationTime,
    required this.notes,
  });
}

class CropDisease {
  final String name;
  final String type; // فطري، بكتيري، فيروسي، حشري
  final String imageAsset; // مسار صورة مستقبلية
  final String cause;
  final List<String> symptoms;
  final List<String> prevention;
  final List<String> treatment;

  const CropDisease({
    required this.name,
    required this.type,
    required this.imageAsset,
    required this.cause,
    required this.symptoms,
    required this.prevention,
    required this.treatment,
  });
}

class GrowthStage {
  final String name;
  final int fromDay;
  final int toDay;
  final String description;
  final String emoji;

  const GrowthStage({
    required this.name,
    required this.fromDay,
    required this.toDay,
    required this.description,
    required this.emoji,
  });
}

// ══════════════════════════════════════════════════════════════════
// قاعدة البيانات الرئيسية
// ══════════════════════════════════════════════════════════════════

class CropDatabase {
  static const Map<String, CropInfo> crops = {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. البطاطس
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'بطاطس': CropInfo(
      cropId: 'potato',
      cropName: 'البطاطس',
      emoji: '🥔',
      cycleDays: 120,
      description:
          'البطاطس محصول درني من أهم محاصيل العالم، يُزرع في المناطق المعتدلة وشبه الجافة. يُعدّ مصدرًا غذائيًا رئيسيًا غنيًا بالكربوهيدرات وفيتامين C والبوتاسيوم. تتميز زراعته بسرعة الإنتاج وعالية الإنتاجية.',
      climate: ClimateInfo(
        minTempC: 7,
        maxTempC: 25,
        optimalTempC: 18,
        minHumidityPct: 40,
        maxHumidityPct: 80,
        annualRainfallMm: 500,
        sunExposure: 'كامل',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'رملية', 'طينية رملية'],
        minPH: 5.0,
        maxPH: 6.5,
        optimalPH: 5.8,
        drainage: 'جيد - يكره التشبع بالماء',
        organicMatter: 'غنية بالمادة العضوية',
        texture: 'خفيفة إلى متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 35,
        waterNeedLitersPerHectarePerWeek: 350000,
        frequency: 'مرتين إلى ثلاث مرات أسبوعياً',
        bestTime: 'الصباح الباكر (6:00 - 8:00 ص) أو المساء (5:00 - 7:00 م)',
        stageWaterMultiplier: {
          'مرحلة الإنبات': 0.6,
          'نمو خضري': 0.9,
          'تكوين الدرنات': 1.3,
          'نضج': 0.7,
        },
        irrigationTypeAdvice: {
          'بالتنقيط': 'مثالي للبطاطس - يحافظ على رطوبة التربة بانتظام دون ترطيب الأوراق مما يقلل الأمراض الفطرية. ضع أنابيب التنقيط على عمق 10 سم.',
          'بالرش': 'مقبول لكن تجنب الري المساء حتى لا تبقى الأوراق مبللة ليلاً - يزيد خطر اللفحة المتأخرة. اري صباحاً فقط.',
          'بالغمر (فيضي)': 'غير موصى به للبطاطس - يزيد خطر تعفن الدرنات ونقل الأمراض. إن اضطررت فاجعل الري خفيفاً وسريع التصريف.',
          'يدوي': 'يصعب التحكم بالكمية. اسقِ ببطء حول النبات لا عليه مباشرة. استخدم خرطوم برأس ناعم.',
          'رش محوري': 'مناسب للمساحات الكبيرة. ضبط الكمية بدقة مهم. تجنب الري في أوقات الحرارة الشديدة.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل كمية الماء بنسبة 30% واطل الفترات بين الري. التربة الطينية تحتجز الماء طويلاً - خطر التعفن مرتفع.',
          'رملية': 'زد كمية الماء بنسبة 25% وقلل الفترات بين الري. الرمل يُصرف سريعاً. أضف مادة عضوية لتحسين الاحتفاظ بالماء.',
          'طميية (لومي)': 'التربة المثالية للبطاطس. اتبع الجدول الأساسي بدون تعديل.',
          'طينية رملية': 'زد الري قليلاً (15%) مع متابعة مستوى الرطوبة بانتظام.',
          'حصوية': 'ري متكرر وقليل في كل مرة. هذه التربة فقيرة بالاحتفاظ بالماء.',
          'عضوية (خصبة)': 'احتفاظ جيد بالماء. اتبع الجدول مع تقليل طفيف في الصيف.',
        },
        generalTips: [
          'توقف عن الري قبل 2 أسبوع من الحصاد لتصلب القشرة',
          'انتبه لعلامات الإجهاد المائي: اصفرار الأوراق أو تجعدها',
          'تجنب الري فوق الأوراق مباشرة لتفادي اللفحة المتأخرة',
          'في الحرارة الشديدة (+35°م) زد الري وتجنب أوقات الذروة',
          'راقب التربة على عمق 10 سم - يجب أن تكون رطبة لا مشبعة',
        ],
      ),
      fertilization: [
        FertilizationStage(
          stageName: 'تحضير التربة',
          fromDay: -14,
          toDay: 0,
          fertilizerType: 'عضوي عميق',
          fertilizerName: 'سماد عضوي متحلل (كومبوست)',
          quantityPer100Sqm: 30.0,
          applicationMethod: 'خلط عميق مع التربة على عمق 30 سم قبل الزراعة',
          applicationTime: 'قبل أسبوعين من الزراعة',
          notes: 'يحسن بنية التربة ويوفر العناصر الغذائية الأساسية',
        ),
        FertilizationStage(
          stageName: 'مرحلة الإنبات',
          fromDay: 0,
          toDay: 30,
          fertilizerType: 'كيميائي سطحي',
          fertilizerName: 'NPK 20-20-20 (نيتروجين-فوسفور-بوتاسيوم)',
          quantityPer100Sqm: 1.5,
          applicationMethod: 'رش محلول مخفف على التربة حول النباتات. نسبة التخفيف 5 غ/لتر ماء',
          applicationTime: 'اليوم 15 من الزراعة',
          notes: 'يحفز نمو الجذور والبراعم الأولى',
        ),
        FertilizationStage(
          stageName: 'النمو الخضري',
          fromDay: 30,
          toDay: 60,
          fertilizerType: 'كيميائي سطحي',
          fertilizerName: 'يوريا 46% N + كبريتات البوتاسيوم',
          quantityPer100Sqm: 2.0,
          applicationMethod: 'تسميد تحت السطح بجانب النباتات على بُعد 8 سم ثم ري فوري',
          applicationTime: 'اليوم 35 والثاني اليوم 50',
          notes: 'تعزيز النمو الخضري وتقوية الساق. تجنب وضع السماد مباشرة على الساق',
        ),
        FertilizationStage(
          stageName: 'تكوين الدرنات',
          fromDay: 60,
          toDay: 90,
          fertilizerType: 'كيميائي عميق',
          fertilizerName: 'كبريتات البوتاسيوم (K2SO4) + سوبر فوسفات',
          quantityPer100Sqm: 2.5,
          applicationMethod: 'تسميد عميق بجوار النباتات على عمق 10 سم. ري خفيف بعده مباشرة',
          applicationTime: 'اليوم 60-65 من الزراعة',
          notes: 'البوتاسيوم ضروري لتضخم الدرنات وتحسين جودتها ومقاومة الأمراض',
        ),
        FertilizationStage(
          stageName: 'النضج',
          fromDay: 90,
          toDay: 120,
          fertilizerType: 'إيقاف التسميد',
          fertilizerName: 'لا تسميد في هذه المرحلة',
          quantityPer100Sqm: 0,
          applicationMethod: 'توقف عن التسميد تماماً',
          applicationTime: 'من اليوم 90 حتى الحصاد',
          notes: 'التسميد في هذه المرحلة يضر بجودة الدرنات ويؤخر النضج',
        ),
      ],
      diseases: [
        CropDisease(
          name: 'اللفحة المتأخرة (Phytophthora infestans)',
          type: 'فطري',
          imageAsset: 'assets/diseases/potato_blight.jpg',
          cause: 'فطر Phytophthora infestans - ينتشر في الجو الرطب والبارد (15-20°م)',
          symptoms: [
            'بقع بنية داكنة على الأوراق مع هالة صفراء',
            'تعفن أسفل الأوراق مع نمو أبيض فطري',
            'تعفن الدرنات بلون بني صدئي',
            'انتشار سريع خلال أيام في الطقس الرطب',
          ],
          prevention: [
            'اختر أصناف مقاومة للمرض',
            'تجنب الري الزائد ورطوبة الأوراق',
            'ضمان تهوية جيدة بين النباتات',
            'رش مبيد وقائي نحاسي كل 10 أيام في موسم الأمطار',
          ],
          treatment: [
            'رش Mancozeb أو Cymoxanil بمعدل 250 غ/100 لتر ماء',
            'إزالة وحرق النباتات المصابة فوراً',
            'تجنب الري الزائد بعد ظهور المرض',
            'تكرار الرش كل 7 أيام حتى زوال الأعراض',
          ],
        ),
        CropDisease(
          name: 'تعفن الساق والدرنات (Rhizoctonia)',
          type: 'فطري',
          imageAsset: 'assets/diseases/potato_rhizoctonia.jpg',
          cause: 'فطر Rhizoctonia solani في التربة ذات الرطوبة العالية',
          symptoms: [
            'اسوداد قاعدة الساق (ساق أسود)',
            'ظهور كتل سوداء صغيرة على الدرنات',
            'ذبول واصفرار النباتات',
            'تأخر الإنبات وضعف النمو',
          ],
          prevention: [
            'استخدم بذار صحي معقم',
            'تجنب الزراعة في تربة باردة ومبللة',
            'تناوب المحاصيل - لا تزرع بطاطس في نفس المكان سنتين متتاليتين',
            'عدم الإفراط في الري',
          ],
          treatment: [
            'معالجة البذار بـ Thiram أو Iprodione قبل الزراعة',
            'تحسين تصريف التربة',
            'رش Flutolanil على قاعدة النباتات',
          ],
        ),
        CropDisease(
          name: 'دودة درنات البطاطس (Phthorimaea)',
          type: 'حشري',
          imageAsset: 'assets/diseases/potato_moth.jpg',
          cause: 'فراشة Phthorimaea operculella - تضع بيضها في التربة والأوراق',
          symptoms: [
            'نفق داخل أوراق البطاطس',
            'تعفن وتشوه الدرنات',
            'ظهور يرقات صغيرة بيضاء داخل الدرنات',
          ],
          prevention: [
            'تغطية الدرنات جيداً بالتربة أثناء التخليد',
            'حصاد مبكر قبل نهاية الموسم',
            'تخزين مبرد للمحصول',
            'رش حشري وقائي في موسم الخطر',
          ],
          treatment: [
            'رش Chlorpyrifos أو Spinosad',
            'استخدام مصائد الفرمون للمراقبة',
            'إزالة النباتات المصابة وحرقها',
          ],
        ),
      ],
      companionGood: ['فاصولياء', 'ملفوف', 'ذرة', 'بصل', 'كزبرة', 'بازلاء'],
      companionBad: ['طماطم', 'فلفل', 'باذنجان', 'عباد الشمس', 'يقطين'],
      doList: [
        'اختر أصناف بذار معتمدة وصحية',
        'احرص على تخليد النباتات (تغطية الدرنات بالتراب) منتظماً',
        'راقب المحصول أسبوعياً للكشف المبكر عن الأمراض',
        'سجّل تواريخ الري والتسميد',
        'أجرِ تناوب المحاصيل كل سنة',
        'اترك الدرنات تجف في الأرض يوم بعد الحصاد قبل الجمع',
      ],
      dontList: [
        'لا تزرع بعد طماطم أو فلفل أو باذنجان (نفس الفصيلة)',
        'لا تفرط في الري خاصة في مرحلة الإنبات',
        'لا تقطع الساق أثناء التخليد',
        'لا تستخدم سماداً نيتروجينياً زائداً (يقلل الجودة)',
        'لا تحصد في يوم مطري',
        'لا تعرض الدرنات للشمس بعد الحصاد (تتلون وتصير سامة)',
      ],
      growthStages: [
        GrowthStage(name: 'الإنبات والإنتاش', fromDay: 0, toDay: 25, description: 'تنبت البذار وتظهر البراعم الأولى فوق التربة. الجذور تتطور تدريجياً.', emoji: '🌱'),
        GrowthStage(name: 'النمو الخضري', fromDay: 25, toDay: 60, description: 'نمو سريع للأوراق والسيقان. تكوين نظام جذري قوي ومنتشر.', emoji: '🌿'),
        GrowthStage(name: 'تكوين الدرنات', fromDay: 60, toDay: 90, description: 'بداية تكوين الدرنات تحت التربة. أهم مرحلة - تحتاج ماءً وبوتاسيوماً كافيَين.', emoji: '🥔'),
        GrowthStage(name: 'تضخم الدرنات', fromDay: 90, toDay: 110, description: 'تضخم سريع للدرنات. الأوراق تبدأ بالاصفرار التدريجي.', emoji: '💛'),
        GrowthStage(name: 'النضج والحصاد', fromDay: 110, toDay: 120, description: 'اصفرار وجفاف الأوراق. الدرنات تصبح كاملة النضج. وقت الحصاد.', emoji: '🌾'),
      ],
      plantingMethod: '''
**كيفية زراعة البطاطس:**
1. **اختيار البذار**: استخدم درنات صحية معتمدة بوزن 40-60 غ. تجنب الدرنات التجارية التي قد تكون معالجة بمضادات الإنبات.
2. **تقطيع الدرنات الكبيرة**: قطّعها لقطع بكل منها 2-3 عيون (براعم). اترك القطع تجف 24 ساعة في مكان هوائي.
3. **تحضير التربة**: احرث التربة جيداً على عمق 30 سم. أضف سماداً عضوياً متحللاً وخلطه مع التربة.
4. **الزراعة**: احفر أخاديد بعمق 10-12 سم وبمسافة 30 سم بين الدرنات و75 سم بين الأسطر.
5. **التغطية**: غطِّ الدرنات بطبقة تراب 8-10 سم.
6. **التخليد**: بعد ظهور النباتات (3-4 أسابيع)، ارفع التراب حول قاعدة الساق لتغطية الدرنات المتكونة.
      ''',
      harvestMethod: 'توقف عن الري قبل أسبوعين. عندما تصفر الأوراق 80% احصد الدرنات بلطف بمجرفة. اتركها تجف في ظل هواء ليوم واحد قبل التخزين.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2. الطماطم
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'طماطم': CropInfo(
      cropId: 'tomato',
      cropName: 'الطماطم',
      emoji: '🍅',
      cycleDays: 100,
      description:
          'الطماطم من أكثر الخضروات زراعةً في العالم. غنية بالليكوبين وفيتامين C ومضادات الأكسدة. تحتاج مناخاً دافئاً ومشمساً وتُنتج محاصيل غزيرة إذا أُعطيت العناية الصحيحة.',
      climate: ClimateInfo(
        minTempC: 10,
        maxTempC: 35,
        optimalTempC: 22,
        minHumidityPct: 45,
        maxHumidityPct: 75,
        annualRainfallMm: 400,
        sunExposure: 'كامل - 8 ساعات يومياً على الأقل',
        windTolerance: 'منخفض - تحتاج دعامات',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'عضوية (خصبة)'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'ممتاز - لا تتحمل التشبع',
        organicMatter: 'غنية جداً',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 40,
        waterNeedLitersPerHectarePerWeek: 400000,
        frequency: 'يومياً في الحرارة أو كل يومين في الاعتدال',
        bestTime: 'الصباح (7:00 - 9:00 ص)',
        stageWaterMultiplier: {
          'شتلة': 0.5,
          'نمو خضري': 0.9,
          'إزهار': 1.0,
          'تكوين الثمار': 1.4,
          'نضج': 0.8,
        },
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل للطماطم. يحافظ على رطوبة منتظمة ويقلل أمراض الأوراق. يُستحسن ري مستمر بكميات صغيرة.',
          'بالرش': 'غير مثالي - يرطب الأوراق ويزيد الأمراض الفطرية. اري صباحاً فقط لتجف الأوراق.',
          'بالغمر (فيضي)': 'تجنبه قدر الإمكان. إن استخدمته فاجعل كميات الماء خفيفة وتأكد من تصريف سريع.',
          'يدوي': 'اسقِ عند قاعدة النبات فقط. تجنب رش الأوراق. الانتظام مهم جداً.',
          'رش محوري': 'مقبول للمساحات الكبيرة. اضبط الكميات بدقة وتجنب الري المسائي.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الكميات بنسبة 35% واطل الفترات. خطر التشبع عالٍ.',
          'رملية': 'زد الكميات بنسبة 30% وقلل الفترات. أضف مادة عضوية.',
          'طميية (لومي)': 'اتبع الجدول بانتظام.',
          'طينية رملية': 'اتبع الجدول مع تقليل خفيف.',
          'حصوية': 'ري متكرر وكثيف مع إضافة مادة عضوية.',
          'عضوية (خصبة)': 'ممتازة - اتبع الجدول مع مراقبة عدم التشبع.',
        },
        generalTips: [
          'انتظام الري يمنع تشقق الثمار ومرض تعفن القمة',
          'تجنب الجفاف المفاجئ بعد فترة ري - يسبب تشقق الثمار',
          'في الطقس الحار جداً اسقِ مرتين يومياً بكميات صغيرة',
          'قلل الري قبل الحصاد بأسبوع لتحسين نكهة الثمار',
        ],
      ),
      fertilization: [
        FertilizationStage(
          stageName: 'قبل الزراعة',
          fromDay: -14,
          toDay: 0,
          fertilizerType: 'عضوي عميق',
          fertilizerName: 'كومبوست ناضج + سماد دجاج',
          quantityPer100Sqm: 25.0,
          applicationMethod: 'خلط مع التربة على عمق 25 سم قبل الزراعة بأسبوعين',
          applicationTime: 'قبل الزراعة بأسبوعين',
          notes: 'أساس تغذية الطماطم طوال الموسم',
        ),
        FertilizationStage(
          stageName: 'مرحلة الشتلة',
          fromDay: 0,
          toDay: 25,
          fertilizerType: 'كيميائي سائل',
          fertilizerName: 'NPK 10-52-10 (عالي الفوسفور)',
          quantityPer100Sqm: 0.5,
          applicationMethod: 'محلول مائي يُسقى على التربة. 5 غ لكل 10 لترات ماء',
          applicationTime: 'اليوم 10 من الزراعة',
          notes: 'يحفز نمو الجذور في مرحلة الشتلة',
        ),
        FertilizationStage(
          stageName: 'مرحلة الإزهار',
          fromDay: 25,
          toDay: 55,
          fertilizerType: 'كيميائي متوازن',
          fertilizerName: 'NPK 20-20-20 + كالسيوم + ماغنيسيوم',
          quantityPer100Sqm: 2.0,
          applicationMethod: 'تسميد بجانب النباتات على بُعد 10 سم. يُرش أيضاً محلول الكالسيوم على الأوراق',
          applicationTime: 'كل أسبوعين: اليوم 30 و45',
          notes: 'الكالسيوم يمنع تعفن قمة الثمار. الماغنيسيوم يمنع اصفرار الأوراق',
        ),
        FertilizationStage(
          stageName: 'مرحلة الثمار',
          fromDay: 55,
          toDay: 85,
          fertilizerType: 'كيميائي عالي البوتاسيوم',
          fertilizerName: 'NPK 8-12-36 + نيترات الكالسيوم',
          quantityPer100Sqm: 2.5,
          applicationMethod: 'تسميد في مياه الري (fertigation) أو تحت التربة بجانب النباتات',
          applicationTime: 'كل أسبوع: اليوم 55 و65 و75',
          notes: 'البوتاسيوم يحسن لون وجودة ونكهة الثمار. نيترات الكالسيوم يمنع التشقق',
        ),
      ],
      diseases: [
        CropDisease(
          name: 'اللفحة المبكرة (Alternaria solani)',
          type: 'فطري',
          imageAsset: 'assets/diseases/tomato_early_blight.jpg',
          cause: 'فطر Alternaria solani - يظهر في الحرارة والرطوبة العالية',
          symptoms: [
            'بقع بنية دائرية على الأوراق السفلية أولاً',
            'حلقات متركزة داخل البقعة كحلقات شجرة',
            'اصفرار ثم سقوط الأوراق',
            'قد تصيب الثمار بشكل أسود',
          ],
          prevention: [
            'تناوب المحاصيل كل 3 سنوات',
            'تهوية جيدة بين النباتات',
            'إزالة الأوراق السفلية المريضة',
            'رش وقائي بالكوبر أوكسيكلور',
          ],
          treatment: [
            'رش Chlorothalonil أو Mancozeb',
            'إزالة الأوراق المصابة وحرقها',
            'تكرار الرش كل 7 أيام',
          ],
        ),
        CropDisease(
          name: 'تعفن قمة الثمرة (Blossom End Rot)',
          type: 'فسيولوجي',
          imageAsset: 'assets/diseases/tomato_ber.jpg',
          cause: 'نقص الكالسيوم بسبب جفاف التربة أو عدم انتظام الري',
          symptoms: [
            'بقعة سوداء جافة في قمة الثمرة',
            'تحول الثمرة للسواد عند الطرف',
            'لا تنتقل من نبات لآخر',
          ],
          prevention: [
            'انتظام الري دون تذبذب',
            'رش الأوراق بمحلول كالسيوم',
            'تجنب التسميد الزائد بالنيتروجين',
          ],
          treatment: [
            'رش نيترات الكالسيوم على الأوراق (10 غ/لتر)',
            'ضبط الري بانتظام',
            'إضافة مادة عضوية للتربة',
          ],
        ),
      ],
      companionGood: ['ريحان', 'بقدونس', 'بصل', 'جزر', 'خس', 'أسبرغس'],
      companionBad: ['بطاطس', 'فلفل', 'باذنجان', 'شمر', 'ملفوف'],
      doList: [
        'ربط النباتات على دعامات للمنع من الانكسار',
        'إزالة السرطانات (الأفرع الجانبية) بانتظام في الأصناف اللانهائية النمو',
        'رش وقائي بالكوبر في موسم الأمطار',
        'تقليم الأوراق السفلية لتحسين التهوية',
        'اختر أصناف مقاومة للفيروسات',
      ],
      dontList: [
        'لا تزرع في نفس مكان البطاطس أو الفلفل',
        'لا ترش الأوراق بالماء وقت الحرارة',
        'لا تقطع الثمار وهي خضراء تماماً',
        'لا تفرط في التسميد بالنيتروجين (أوراق كثيرة وثمار قليلة)',
      ],
      growthStages: [
        GrowthStage(name: 'الشتلة', fromDay: 0, toDay: 20, description: 'نقل الشتلة من المشتل إلى الأرض. جذور تتأقلم مع التربة الجديدة.', emoji: '🌱'),
        GrowthStage(name: 'النمو الخضري', fromDay: 20, toDay: 45, description: 'نمو سريع للأوراق والساق. تكوين مجموع جذري قوي.', emoji: '🌿'),
        GrowthStage(name: 'الإزهار', fromDay: 45, toDay: 65, description: 'ظهور الأزهار الصفراء. مرحلة حساسة تحتاج انتظام الري والتلقيح.', emoji: '🌸'),
        GrowthStage(name: 'تكوين الثمار', fromDay: 65, toDay: 85, description: 'تحول الأزهار لثمار خضراء صغيرة تنمو تدريجياً.', emoji: '🍅'),
        GrowthStage(name: 'النضج والحصاد', fromDay: 85, toDay: 100, description: 'تحمر الثمار وتنضج. الحصاد يكون تدريجياً كل 3-4 أيام.', emoji: '🔴'),
      ],
      plantingMethod: '''
**كيفية زراعة الطماطم:**
1. **الإكثار بالشتلات**: ابدأ بزراعة البذور في صوانٍ أو أكياس صغيرة قبل 6 أسابيع من موعد الزراعة.
2. **نقل الشتلات**: عندما يبلغ الطول 15-20 سم وللشتلة 4-6 أوراق حقيقية، انقلها للأرض.
3. **المسافات**: 50-70 سم بين النباتات في السطر، 100-120 سم بين الأسطر.
4. **الزراعة**: ازرع الشتلة بعمق أكبر قليلاً مما كانت في المشتل - الجذور الإضافية تتكون على الساق المدفونة.
5. **الدعامات**: ركز دعامات فور الزراعة لتفادي إيذاء الجذور لاحقاً.
      ''',
      harvestMethod: 'الحصاد تدريجي كلما احمرت الثمار. اقطع بمقص نظيف مع جزء من العنق.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 3. الفلفل
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'فلفل': CropInfo(
      cropId: 'pepper',
      cropName: 'الفلفل',
      emoji: '🌶️',
      cycleDays: 90,
      description: 'الفلفل بأصنافه الحلوة والحارة من أهم الخضروات المغذية. غني بفيتامين C والكاروتين. يتحمل الحرارة ويحتاج ضوءاً وافراً لإنتاج ثمار جيدة.',
      climate: ClimateInfo(
        minTempC: 15,
        maxTempC: 32,
        optimalTempC: 24,
        minHumidityPct: 50,
        maxHumidityPct: 75,
        annualRainfallMm: 450,
        sunExposure: 'كامل',
        windTolerance: 'منخفض',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'جيد جداً',
        organicMatter: 'غنية',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 30,
        waterNeedLitersPerHectarePerWeek: 300000,
        frequency: 'كل يومين إلى ثلاثة أيام',
        bestTime: 'الصباح الباكر (6:00 - 8:00)',
        stageWaterMultiplier: {'شتلة': 0.5, 'نمو': 0.9, 'إزهار': 1.1, 'ثمار': 1.3, 'نضج': 0.7},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل. يوفر رطوبة منتظمة ويقلل الأمراض.',
          'بالرش': 'تجنب الري وقت الإزهار - يؤدي لسقوط الأزهار.',
          'بالغمر (فيضي)': 'غير مناسب - يضر بالجذور.',
          'يدوي': 'اسقِ عند الجذور فقط بانتظام.',
          'رش محوري': 'مقبول مع ضبط دقيق للكميات.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الكميات بنسبة 30%.',
          'رملية': 'زد الكميات بنسبة 30%.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول مع تقليل خفيف.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: [
          'الجفاف المفاجئ يسبب سقوط الأزهار وتشقق الثمار',
          'في الحرارة الشديدة اسقِ أكثر لخفض درجة حرارة التربة',
          'تجنب الري الزائد في مرحلة الإنبات',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست', quantityPer100Sqm: 20, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل أسبوعين', notes: ''),
        FertilizationStage(stageName: 'نمو خضري', fromDay: 20, toDay: 50, fertilizerType: 'NPK متوازن', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 1.5, applicationMethod: 'تسميد سطحي بجانب النباتات', applicationTime: 'اليوم 25', notes: 'يعزز نمو النبات'),
        FertilizationStage(stageName: 'إزهار وثمار', fromDay: 50, toDay: 80, fertilizerType: 'عالي البوتاسيوم', fertilizerName: 'NPK 9-18-36', quantityPer100Sqm: 2.0, applicationMethod: 'تسميد مع الري', applicationTime: 'اليوم 50 و65', notes: 'يحسن جودة الثمار'),
      ],
      diseases: [
        CropDisease(
          name: 'عفن فيتوفتورا (Phytophthora capsici)',
          type: 'فطري',
          imageAsset: 'assets/diseases/pepper_phytophthora.jpg',
          cause: 'فطر Phytophthora capsici في التربة الرطبة',
          symptoms: ['تعفن الساق عند مستوى التربة', 'ذبول مفاجئ للنبات', 'تعفن الثمار بلون بني'],
          prevention: ['تصريف جيد للتربة', 'تناوب المحاصيل', 'تجنب الري الزائد'],
          treatment: ['رش Metalaxyl', 'تحسين التصريف', 'إزالة النباتات المصابة'],
        ),
      ],
      companionGood: ['ريحان', 'بصل', 'بقدونس', 'جزر'],
      companionBad: ['بطاطس', 'طماطم', 'باذنجان', 'شمر'],
      doList: ['دعم النباتات بعصي', 'تقليم منتظم للأفرع الزائدة', 'رش كالسيوم لتجنب التشقق'],
      dontList: ['لا ترش الأوراق وقت الإزهار', 'لا تزرع بعد الطماطم أو البطاطس', 'لا تفرط في النيتروجين'],
      growthStages: [
        GrowthStage(name: 'شتلة', fromDay: 0, toDay: 20, description: 'تأقلم الشتلة', emoji: '🌱'),
        GrowthStage(name: 'نمو خضري', fromDay: 20, toDay: 45, description: 'نمو الأوراق والساق', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 45, toDay: 60, description: 'ظهور أزهار بيضاء', emoji: '🌸'),
        GrowthStage(name: 'تكوين الثمار', fromDay: 60, toDay: 80, description: 'نمو الثمار الخضراء', emoji: '🌶️'),
        GrowthStage(name: 'نضج', fromDay: 80, toDay: 90, description: 'تحمير أو تلوين الثمار', emoji: '🔴'),
      ],
      plantingMethod: 'ابدأ بالشتلات في المشتل قبل 6 أسابيع. انقل للأرض بمسافة 40×70 سم.',
      harvestMethod: 'احصد الفلفل الأخضر عند اكتمال حجمه أو الأحمر عند تلونه الكامل.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 4. البصل
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'بصل': CropInfo(
      cropId: 'onion',
      cropName: 'البصل',
      emoji: '🧅',
      cycleDays: 110,
      description: 'البصل محصول ذو أهمية غذائية واقتصادية كبيرة، يزرع في مناطق واسعة حول العالم. يتحمل درجات حرارة متنوعة ويُعدّ أساس المطبخ الجزائري والمتوسطي.',
      climate: ClimateInfo(
        minTempC: 5,
        maxTempC: 30,
        optimalTempC: 20,
        minHumidityPct: 40,
        maxHumidityPct: 70,
        annualRainfallMm: 350,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'رملية', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'خفيفة إلى متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 25,
        waterNeedLitersPerHectarePerWeek: 250000,
        frequency: 'مرة إلى مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.7, 'نمو خضري': 1.0, 'تضخم البصلة': 1.2, 'نضج': 0.3},
        irrigationTypeAdvice: {
          'بالتنقيط': 'ممتاز للبصل. يقلل تعفن العنق.',
          'بالرش': 'مقبول لكن اري صباحاً.',
          'بالغمر (فيضي)': 'مقبول إن كان التصريف جيداً.',
          'يدوي': 'اسقِ عند الجذور.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري بنسبة 25%.',
          'رملية': 'زد الري وقصّر الفترات.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: [
          'توقف عن الري كلياً قبل أسبوعين من الحصاد',
          'الري الزائد في النضج يسبب تعفن العنق',
          'مراقبة مستوى الرطوبة مهمة لتفادي الفطريات',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست', quantityPer100Sqm: 15, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل أسبوعين', notes: ''),
        FertilizationStage(stageName: 'نمو خضري', fromDay: 25, toDay: 60, fertilizerType: 'NPK', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 1.5, applicationMethod: 'سطحي بجانب النباتات', applicationTime: 'اليوم 30', notes: 'يعزز نمو الأوراق'),
        FertilizationStage(stageName: 'تضخم البصلة', fromDay: 60, toDay: 90, fertilizerType: 'بوتاسيوم', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 2.0, applicationMethod: 'تسميد عميق خفيف', applicationTime: 'اليوم 60', notes: 'يكبر البصلة ويحسن التخزين'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الزغبي (Peronospora)',
          type: 'فطري',
          imageAsset: 'assets/diseases/onion_downy.jpg',
          cause: 'فطر Peronospora destructor في الطقس الرطب',
          symptoms: ['بقع بنفسجية على الأوراق', 'ذبول الأوراق', 'تحول الأوراق للأصفر'],
          prevention: ['تناوب المحاصيل', 'تهوية جيدة', 'رش وقائي'],
          treatment: ['رش Metalaxyl أو Cymoxanil', 'إزالة الأوراق المصابة'],
        ),
      ],
      companionGood: ['جزر', 'طماطم', 'خس', 'فريز'],
      companionBad: ['بازلاء', 'فاصولياء', 'تفاح', 'كرات'],
      doList: ['اختيار بذار صحية', 'زراعة بعمق 2-3 سم', 'إزالة الحشائش باستمرار'],
      dontList: ['لا تزرع بجوار البازلاء أو الفاصولياء', 'لا تسقِ بزيادة قرب الحصاد'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 20, description: 'إنبات البذار وظهور الشتلات', emoji: '🌱'),
        GrowthStage(name: 'نمو خضري', fromDay: 20, toDay: 60, description: 'نمو الأوراق الخضراء الأنبوبية', emoji: '🌿'),
        GrowthStage(name: 'تضخم البصلة', fromDay: 60, toDay: 90, description: 'تضخم القاعدة لتكوين البصلة', emoji: '🧅'),
        GrowthStage(name: 'نضج', fromDay: 90, toDay: 110, description: 'انكسار الأوراق وجفافها - علامة النضج', emoji: '🌾'),
      ],
      plantingMethod: 'زرع مباشر بالبذار أو بالشتلات. المسافة 10 سم بين النباتات و30 سم بين الأسطر.',
      harvestMethod: 'اقلع البصل عندما تنكسر وتجف الأوراق. اتركه يجف في ظل هواء أسبوعاً قبل التخزين.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 5. الثوم
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'ثوم': CropInfo(
      cropId: 'garlic',
      cropName: 'الثوم',
      emoji: '🧄',
      cycleDays: 180,
      description: 'الثوم من أقدم المحاصيل الطبية والغذائية. يزرع خلال الشتاء في المناطق شبه الجافة ويحتاج فترة برودة لنمو الفصوص. له خصائص مضادة للبكتيريا والفطريات.',
      climate: ClimateInfo(
        minTempC: 0,
        maxTempC: 28,
        optimalTempC: 15,
        minHumidityPct: 40,
        maxHumidityPct: 65,
        annualRainfallMm: 300,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'رملية', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.8,
        drainage: 'ممتاز',
        organicMatter: 'غنية',
        texture: 'خفيفة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 20,
        waterNeedLitersPerHectarePerWeek: 200000,
        frequency: 'مرة واحدة أو مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.8, 'نمو': 1.0, 'تكوين الرأس': 1.1, 'نضج': 0.2},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل للثوم.',
          'بالرش': 'مقبول في الصباح فقط.',
          'بالغمر (فيضي)': 'تجنبه لخطر تعفن الرأس.',
          'يدوي': 'اسقِ عند الجذور.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل بنسبة 30% وتجنب التشبع.',
          'رملية': 'زد بنسبة 20% وقصّر الفترات.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر وقليل.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: [
          'توقف عن الري قبل 3 أسابيع من الحصاد',
          'الري الزائد يسبب تعفن الرأس',
          'الثوم يتحمل الجفاف نسبياً مقارنة بالخضروات الأخرى',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'زراعة الفصوص', fromDay: 0, toDay: 30, fertilizerType: 'عضوي', fertilizerName: 'كومبوست + سوبر فوسفات', quantityPer100Sqm: 15, applicationMethod: 'خلط مع التربة قبل الزراعة', applicationTime: 'عند الزراعة', notes: 'فوسفور يحفز نمو الجذور'),
        FertilizationStage(stageName: 'نمو خضري', fromDay: 30, toDay: 90, fertilizerType: 'نيتروجين', fertilizerName: 'يوريا 46%', quantityPer100Sqm: 1.0, applicationMethod: 'سطحي بجانب النباتات مع ري', applicationTime: 'اليوم 40 و70', notes: 'يعزز نمو الأوراق وبناء الرأس'),
        FertilizationStage(stageName: 'تكوين الرأس', fromDay: 90, toDay: 150, fertilizerType: 'بوتاسيوم', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 1.5, applicationMethod: 'تسميد سطحي خفيف', applicationTime: 'اليوم 100', notes: 'يكبر الرأس ويحسن الجودة والتخزين'),
      ],
      diseases: [
        CropDisease(
          name: 'صدأ الثوم (Puccinia)',
          type: 'فطري',
          imageAsset: 'assets/diseases/garlic_rust.jpg',
          cause: 'فطر Puccinia allii في الطقس الرطب',
          symptoms: ['بقع برتقالية أو صفراء على الأوراق', 'انتشار سريع'],
          prevention: ['تناوب المحاصيل', 'تهوية جيدة'],
          treatment: ['رش Triadimefon أو Mancozeb'],
        ),
      ],
      companionGood: ['طماطم', 'جزر', 'خس', 'فريز', 'ورد'],
      companionBad: ['بازلاء', 'فاصولياء', 'ملفوف'],
      doList: ['اختر فصوصاً كبيرة وصحية للزراعة', 'ازرع بعمق 3-5 سم', 'الزراعة الشتوية تعطي أفضل نتيجة'],
      dontList: ['لا تزرع في تربة ثقيلة أو متشبعة', 'لا تفرط في الري قرب النضج'],
      growthStages: [
        GrowthStage(name: 'إنبات الفصوص', fromDay: 0, toDay: 21, description: 'ظهور الجذور والبراعم', emoji: '🌱'),
        GrowthStage(name: 'نمو خضري', fromDay: 21, toDay: 90, description: 'نمو الأوراق الأنبوبية', emoji: '🌿'),
        GrowthStage(name: 'تكوين الرأس', fromDay: 90, toDay: 150, description: 'تضخم الفصوص وتكوين الرأس', emoji: '🧄'),
        GrowthStage(name: 'نضج', fromDay: 150, toDay: 180, description: 'جفاف الأوراق وتصلب الجلد الخارجي', emoji: '🌾'),
      ],
      plantingMethod: 'افصل الرأس إلى فصوص. ازرع كل فص بعمق 3-5 سم بمسافة 10 سم × 30 سم.',
      harvestMethod: 'اقلع الثوم عندما تصفر 3/4 الأوراق. اتركه يجف في ظل هواء 2-3 أسابيع.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 6. الذرة
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'ذرة': CropInfo(
      cropId: 'corn',
      cropName: 'الذرة',
      emoji: '🌽',
      cycleDays: 100,
      description: 'الذرة من أهم محاصيل الحبوب والعلف. تنمو بسرعة وتعطي إنتاجاً عالياً. مهمة للغذاء البشري والحيواني وصناعة الزيت.',
      climate: ClimateInfo(
        minTempC: 10,
        maxTempC: 38,
        optimalTempC: 28,
        minHumidityPct: 40,
        maxHumidityPct: 80,
        annualRainfallMm: 500,
        sunExposure: 'كامل',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'طينية'],
        minPH: 5.8,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'غنية',
        texture: 'متوسطة إلى ثقيلة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 45,
        waterNeedLitersPerHectarePerWeek: 450000,
        frequency: 'مرتين إلى ثلاث مرات أسبوعياً',
        bestTime: 'الصباح أو المساء',
        stageWaterMultiplier: {'إنبات': 0.5, 'نمو نباتي': 0.9, 'إزهار': 1.5, 'حبوب': 1.2, 'نضج': 0.6},
        irrigationTypeAdvice: {
          'بالتنقيط': 'جيد لتوفير الماء في الذرة.',
          'بالرش': 'مناسب لكن تجنب وقت الإزهار.',
          'بالغمر (فيضي)': 'شائع الاستخدام مع الذرة - تأكد من التصريف.',
          'يدوي': 'صعب على مساحات كبيرة.',
          'رش محوري': 'الأفضل للمساحات الكبيرة.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل بنسبة 20%.',
          'رملية': 'زد بنسبة 35%.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: [
          'مرحلة الإزهار (النشاء والحريرة) هي الأحرج - لا توقف الري أبداً',
          'الذرة تحتاج ماءً وفيراً في الصيف - راقب أوراق الذرة إذا لفّت فهي عطشى',
          'تجنب الجفاف في مرحلة تكوين الحبوب',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'NPK شامل', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 2.0, applicationMethod: 'خلط مع التربة عند الحراثة', applicationTime: 'قبل الزراعة بأسبوع', notes: ''),
        FertilizationStage(stageName: 'نمو نباتي', fromDay: 25, toDay: 55, fertilizerType: 'نيتروجين', fertilizerName: 'يوريا 46% أو نترات الأمونيوم', quantityPer100Sqm: 3.0, applicationMethod: 'سطحي بجانب النباتات', applicationTime: 'اليوم 30 والثاني اليوم 50', notes: 'الذرة تحتاج نيتروجيناً وفيراً لنمو الساق والأوراق'),
        FertilizationStage(stageName: 'إزهار وحبوب', fromDay: 55, toDay: 80, fertilizerType: 'بوتاسيوم وفوسفور', fertilizerName: 'NPK 12-12-36', quantityPer100Sqm: 2.0, applicationMethod: 'مع الري', applicationTime: 'اليوم 60', notes: 'يدعم تشكل وامتلاء الحبوب'),
      ],
      diseases: [
        CropDisease(
          name: 'صدأ الذرة (Puccinia sorghi)',
          type: 'فطري',
          imageAsset: 'assets/diseases/corn_rust.jpg',
          cause: 'فطر Puccinia sorghi في الطقس الرطب الدافئ',
          symptoms: ['بقع برتقالية على الأوراق', 'مسحوق برتقالي ينتشر'],
          prevention: ['أصناف مقاومة', 'رش وقائي بالمبيدات الفطرية'],
          treatment: ['رش Mancozeb أو Propiconazole'],
        ),
      ],
      companionGood: ['فاصولياء', 'كوسة', 'بطيخ', 'خيار'],
      companionBad: ['طماطم', 'كرفس'],
      doList: ['زرع بمسافات منتظمة لتلقيح أفضل', 'إضافة نيتروجين وفير', 'الري المنتظم في الإزهار'],
      dontList: ['لا توقف الري وقت الإزهار', 'لا تقلل النيتروجين'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات البذور وظهور الشتلات', emoji: '🌱'),
        GrowthStage(name: 'نمو نباتي', fromDay: 10, toDay: 55, description: 'نمو الساق والأوراق بسرعة', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 55, toDay: 70, description: 'ظهور نشاء وحريرة الذرة - تلقيح', emoji: '🌸'),
        GrowthStage(name: 'امتلاء الحبوب', fromDay: 70, toDay: 90, description: 'تكبر الكيزان وتمتلئ الحبوب', emoji: '🌽'),
        GrowthStage(name: 'نضج', fromDay: 90, toDay: 100, description: 'جفاف الحريرة وتصلب الحبوب', emoji: '🌾'),
      ],
      plantingMethod: 'زراعة مباشرة بعمق 5 سم. مسافة 25 سم بين النباتات و75 سم بين الأسطر.',
      harvestMethod: 'احصد عندما تجف الحريرة وتتصلب الحبوب. للذرة الطازجة احصد 20 يوم بعد الإزهار.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 7. القمح
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'قمح': CropInfo(
      cropId: 'wheat',
      cropName: 'القمح',
      emoji: '🌾',
      cycleDays: 150,
      description: 'القمح المحصول الاستراتيجي الأول في الجزائر والعالم. يُزرع في الخريف ويُحصد في الربيع. يحتاج مناخاً معتدلاً وأمطاراً كافية.',
      climate: ClimateInfo(
        minTempC: 0,
        maxTempC: 30,
        optimalTempC: 18,
        minHumidityPct: 40,
        maxHumidityPct: 75,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 7.0,
        drainage: 'جيد إلى متوسط',
        organicMatter: 'متوسطة إلى غنية',
        texture: 'متوسطة إلى ثقيلة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 30,
        waterNeedLitersPerHectarePerWeek: 300000,
        frequency: 'مرة إلى مرتين أسبوعياً حسب الأمطار',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.8, 'تفريخ': 1.0, 'إزهار': 1.3, 'امتلاء الحبوب': 1.1, 'نضج': 0.2},
        irrigationTypeAdvice: {
          'بالتنقيط': 'غير اقتصادي للقمح عادة.',
          'بالرش': 'مناسب للقمح مع حذر وقت الإزهار.',
          'بالغمر (فيضي)': 'الأكثر شيوعاً للقمح.',
          'يدوي': 'غير عملي للمساحات الكبيرة.',
          'رش محوري': 'الأفضل للمساحات الكبيرة.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري - التربة تحتفظ بالماء جيداً.',
          'رملية': 'زد الري وقصّر الفترات.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: [
          'القمح يعتمد كثيراً على الأمطار في الجزائر',
          'ري إضافي في مرحلة الإزهار وامتلاء الحبوب يرفع الإنتاج بشكل كبير',
          'احذر الري في أوقات المطر والصقيع',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور وبوتاسيوم', fertilizerName: 'سوبر فوسفات + كبريتات البوتاسيوم', quantityPer100Sqm: 2.0, applicationMethod: 'خلط عميق مع التربة', applicationTime: 'عند الحراثة', notes: 'أساس تغذية القمح'),
        FertilizationStage(stageName: 'إنبات وتفريخ', fromDay: 20, toDay: 60, fertilizerType: 'نيتروجين', fertilizerName: 'يوريا 46%', quantityPer100Sqm: 2.5, applicationMethod: 'بث سطحي ثم ري خفيف', applicationTime: 'اليوم 30 والثاني اليوم 55', notes: 'التفريخ الجيد يضمن كثافة السنابل'),
        FertilizationStage(stageName: 'إزهار', fromDay: 90, toDay: 110, fertilizerType: 'رش ورقي', fertilizerName: 'يوريا + ماغنيسيوم (رش ورقي)', quantityPer100Sqm: 0.5, applicationMethod: 'رش ورقي 2% يوريا', applicationTime: 'اليوم 95', notes: 'يملأ الحبوب ويحسن الجودة'),
      ],
      diseases: [
        CropDisease(
          name: 'صدأ القمح (Puccinia)',
          type: 'فطري',
          imageAsset: 'assets/diseases/wheat_rust.jpg',
          cause: 'فطريات الصدأ الثلاثة: البرتقالي والأصفر والأسود',
          symptoms: ['بثرات برتقالية أو صفراء أو سوداء على الأوراق', 'اصفرار وجفاف مبكر'],
          prevention: ['أصناف مقاومة', 'رش وقائي', 'تناوب المحاصيل'],
          treatment: ['رش Triadimefon أو Propiconazole عند الإصابة الأولى'],
        ),
      ],
      companionGood: ['بازلاء', 'فول', 'بقوليات بشكل عام'],
      companionBad: ['شعير (خطر مشاركة الأمراض)'],
      doList: ['اختر أصناف مقاومة للصدأ', 'زرع في الوقت المناسب (أكتوبر-نوفمبر)', 'سماد النيتروجين على مرحلتين'],
      dontList: ['لا تتأخر في الزراعة', 'لا تزرع في تربة متشبعة', 'لا تهمل مرض الصدأ'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 15, description: 'إنبات البذور وظهور الشتلات', emoji: '🌱'),
        GrowthStage(name: 'تفريخ', fromDay: 15, toDay: 60, description: 'تفرع الساق وتكثف النباتات', emoji: '🌿'),
        GrowthStage(name: 'مد', fromDay: 60, toDay: 100, description: 'طول الساق وظهور السنابل', emoji: '🌾'),
        GrowthStage(name: 'إزهار وحبوب', fromDay: 100, toDay: 130, description: 'تلقيح وامتلاء الحبوب', emoji: '🌸'),
        GrowthStage(name: 'نضج', fromDay: 130, toDay: 150, description: 'اصفرار وجفاف النبات كاملاً', emoji: '🟡'),
      ],
      plantingMethod: 'بذر ميكانيكي أو يدوي بمعدل 120-150 كغ/هكتار. الزراعة بعمق 3-5 سم.',
      harvestMethod: 'حصاد بالحصادة الآلية عندما تصفر السنابل وتجف الحبوب كلياً.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 8. الشعير
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'شعير': CropInfo(
      cropId: 'barley',
      cropName: 'الشعير',
      emoji: '🌾',
      cycleDays: 130,
      description: 'الشعير أكثر المحاصيل تحملاً للجفاف والملوحة. يُستخدم علفاً وغذاءً وفي صناعة المالت. يتكيف مع المناطق الجافة وشبه الجافة بكفاءة عالية.',
      climate: ClimateInfo(
        minTempC: -5,
        maxTempC: 32,
        optimalTempC: 17,
        minHumidityPct: 30,
        maxHumidityPct: 70,
        annualRainfallMm: 300,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ جداً',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'حصوية'],
        minPH: 6.0,
        maxPH: 8.0,
        optimalPH: 7.0,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'أي نوع تقريباً',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 22,
        waterNeedLitersPerHectarePerWeek: 220000,
        frequency: 'مرة إلى مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.8, 'تفريخ': 1.0, 'إزهار': 1.2, 'نضج': 0.2},
        irrigationTypeAdvice: {
          'بالتنقيط': 'غير اقتصادي.',
          'بالرش': 'جيد.',
          'بالغمر (فيضي)': 'شائع.',
          'يدوي': 'غير عملي.',
          'رش محوري': 'الأنسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['الشعير يتحمل الجفاف أكثر من القمح', 'ري في الإزهار يرفع الإنتاج بشكل ملحوظ'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور', fertilizerName: 'سوبر فوسفات', quantityPer100Sqm: 1.5, applicationMethod: 'خلط مع التربة', applicationTime: 'عند الحراثة', notes: ''),
        FertilizationStage(stageName: 'نمو مبكر', fromDay: 20, toDay: 60, fertilizerType: 'نيتروجين', fertilizerName: 'يوريا', quantityPer100Sqm: 2.0, applicationMethod: 'بث سطحي', applicationTime: 'اليوم 30 و55', notes: 'يعزز التفريخ'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الدقيقي (Erysiphe graminis)',
          type: 'فطري',
          imageAsset: 'assets/diseases/barley_powdery.jpg',
          cause: 'فطر Erysiphe graminis في الطقس الجاف الدافئ',
          symptoms: ['مسحوق أبيض دقيقي على الأوراق', 'اصفرار تحت الطبقة البيضاء'],
          prevention: ['أصناف مقاومة', 'تهوية جيدة'],
          treatment: ['رش Triadimefon'],
        ),
      ],
      companionGood: ['بازلاء', 'فول'],
      companionBad: ['قمح (مشاركة أمراض)'],
      doList: ['زراعة مبكرة في الخريف', 'اختيار أصناف مقاومة للجفاف'],
      dontList: ['لا تزرع في التربة الحامضة جداً'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 12, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'تفريخ', fromDay: 12, toDay: 55, description: 'تفرع كثيف', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 55, toDay: 90, description: 'ظهور السنابل', emoji: '🌾'),
        GrowthStage(name: 'نضج', fromDay: 90, toDay: 130, description: 'جفاف وحصاد', emoji: '🟡'),
      ],
      plantingMethod: 'بذر بمعدل 100-130 كغ/هكتار بعمق 3-4 سم.',
      harvestMethod: 'حصاد آلي عند جفاف السنابل كاملاً.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 9. دوار الشمس
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'دوار الشمس': CropInfo(
      cropId: 'sunflower',
      cropName: 'دوار الشمس',
      emoji: '🌻',
      cycleDays: 110,
      description: 'دوار الشمس محصول زيتي ممتاز يتحمل الحرارة والجفاف النسبي. يُنتج زيتاً نباتياً عالي الجودة وعلفاً للطيور. سريع النمو ومربح.',
      climate: ClimateInfo(
        minTempC: 8,
        maxTempC: 35,
        optimalTempC: 25,
        minHumidityPct: 30,
        maxHumidityPct: 70,
        annualRainfallMm: 450,
        sunExposure: 'كامل - كما يدل اسمه',
        windTolerance: 'منخفض - يحتاج دعماً',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'طينية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.8,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 35,
        waterNeedLitersPerHectarePerWeek: 350000,
        frequency: 'مرة إلى مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.5, 'نمو': 0.9, 'إزهار': 1.5, 'حبوب': 1.1, 'نضج': 0.3},
        irrigationTypeAdvice: {
          'بالتنقيط': 'جيد.',
          'بالرش': 'تجنب وقت الإزهار.',
          'بالغمر (فيضي)': 'مقبول.',
          'يدوي': 'صعب للمساحات الكبيرة.',
          'رش محوري': 'الأنسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['مرحلة الإزهار هي الأحرج - لا توقف الري', 'الجفاف في الإزهار يفرغ الحبوب'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'NPK', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 2.0, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: ''),
        FertilizationStage(stageName: 'نمو', fromDay: 25, toDay: 55, fertilizerType: 'نيتروجين', fertilizerName: 'يوريا', quantityPer100Sqm: 2.0, applicationMethod: 'سطحي مع ري', applicationTime: 'اليوم 30', notes: 'يدعم نمو الساق الطويلة'),
        FertilizationStage(stageName: 'إزهار وبذور', fromDay: 55, toDay: 85, fertilizerType: 'بوتاسيوم وبورون', fertilizerName: 'كبريتات البوتاسيوم + بورات الصوديوم', quantityPer100Sqm: 1.5, applicationMethod: 'رش ورقي للبورون + سطحي للبوتاسيوم', applicationTime: 'اليوم 60', notes: 'البورون ضروري لتلقيح دوار الشمس وامتلاء البذور'),
      ],
      diseases: [
        CropDisease(
          name: 'عفن الحامل (Sclerotinia)',
          type: 'فطري',
          imageAsset: 'assets/diseases/sunflower_sclerotinia.jpg',
          cause: 'فطر Sclerotinia sclerotiorum في الطقس الرطب البارد',
          symptoms: ['تعفن الرأس والرقبة', 'نمو أبيض قطني على المنطقة المصابة', 'انهيار النبات'],
          prevention: ['تناوب المحاصيل', 'تجنب الري الزائد', 'أصناف مقاومة'],
          treatment: ['رش Iprodione أو Boscalid', 'إزالة النباتات المصابة'],
        ),
      ],
      companionGood: ['خيار', 'ذرة', 'فاصولياء'],
      companionBad: ['بطاطس', 'فول'],
      doList: ['زرع بعد آخر صقيع', 'تدعيم النباتات في المناطق العرضة للريح', 'رش بورون في بداية الإزهار'],
      dontList: ['لا تزرع بجوار البطاطس', 'لا توقف الري في الإزهار'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو خضري', fromDay: 10, toDay: 55, description: 'نمو الساق الطويلة والأوراق', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 55, toDay: 75, description: 'فتح الزهرة الشمسية الكبيرة', emoji: '🌻'),
        GrowthStage(name: 'نضج البذور', fromDay: 75, toDay: 100, description: 'نضج وجفاف البذور', emoji: '🌰'),
        GrowthStage(name: 'حصاد', fromDay: 100, toDay: 110, description: 'جفاف الرأس وتصلب البذور', emoji: '🌾'),
      ],
      plantingMethod: 'زراعة مباشرة بعمق 4-5 سم. مسافة 30-35 سم بين النباتات و70 سم بين الأسطر.',
      harvestMethod: 'احصد عندما يتحول الجانب الخلفي للرأس للأصفر البني. قطع بمقص أو منجل.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 10. البطيخ
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'بطيخ': CropInfo(
      cropId: 'watermelon',
      cropName: 'البطيخ',
      emoji: '🍉',
      cycleDays: 90,
      description: 'البطيخ محصول صيفي بامتياز يحتاج حرارة عالية وشمساً وفيراً. ثماره كبيرة غنية بالماء والليكوبين. يحقق عائداً اقتصادياً مرتفعاً.',
      climate: ClimateInfo(
        minTempC: 18,
        maxTempC: 40,
        optimalTempC: 30,
        minHumidityPct: 30,
        maxHumidityPct: 60,
        annualRainfallMm: 400,
        sunExposure: 'كامل - يحب الحرارة الشديدة',
        windTolerance: 'منخفض - يكسر الأفرع',
      ),
      soil: SoilRequirements(
        suitableSoils: ['رملية', 'طميية (لومي)', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'ممتاز - لا يتحمل التشبع مطلقاً',
        organicMatter: 'غنية',
        texture: 'خفيفة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 50,
        waterNeedLitersPerHectarePerWeek: 500000,
        frequency: 'كل يومين تقريباً',
        bestTime: 'الصباح الباكر',
        stageWaterMultiplier: {'إنبات': 0.5, 'زحف': 0.8, 'إزهار': 1.0, 'ثمار صغيرة': 1.5, 'نضج': 0.6},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل للبطيخ. يقلل الأمراض الفطرية ويوفر الماء.',
          'بالرش': 'تجنبه - الرطوبة تسبب الأمراض الفطرية والتعفن.',
          'بالغمر (فيضي)': 'غير موصى به - يضر بجودة الثمار.',
          'يدوي': 'اسقِ عند الجذور فقط.',
          'رش محوري': 'مقبول مع حذر.',
        },
        soilTypeAdvice: {
          'طينية': 'خطر تعفن عالٍ. أضف رمل لتحسين التصريف.',
          'رملية': 'مثالية لكن ري متكرر أكثر.',
          'طميية (لومي)': 'جيدة. اتبع الجدول.',
          'طينية رملية': 'جيدة مع حذر.',
          'حصوية': 'ري متكرر جداً.',
          'عضوية (خصبة)': 'ممتازة. اتبع الجدول.',
        },
        generalTips: [
          'قلل الري عند قرب النضج لتحسين السكريات والنكهة',
          'الانقطاع المفاجئ للماء يسبب تشقق الثمار',
          'لا ترش ماء على الثمار المكتملة النمو',
        ],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست ناضج', quantityPer100Sqm: 20, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل أسبوعين', notes: ''),
        FertilizationStage(stageName: 'نمو ونمو زحفي', fromDay: 10, toDay: 40, fertilizerType: 'NPK متوازن', fertilizerName: 'NPK 12-12-17', quantityPer100Sqm: 1.5, applicationMethod: 'سطحي بجانب النبات', applicationTime: 'اليوم 15 و35', notes: 'يعزز النمو الزحفي والتفرع'),
        FertilizationStage(stageName: 'تكوين الثمار', fromDay: 40, toDay: 70, fertilizerType: 'عالي البوتاسيوم', fertilizerName: 'NPK 7-10-40 + كالسيوم', quantityPer100Sqm: 2.0, applicationMethod: 'مع الري (fertigation)', applicationTime: 'اليوم 45 و60', notes: 'يضخم الثمار ويرفع السكريات'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الزغبي (Pseudoperonospora)',
          type: 'فطري',
          imageAsset: 'assets/diseases/watermelon_downy.jpg',
          cause: 'فطر في الطقس الرطب الدافئ',
          symptoms: ['بقع صفراء على الأوراق', 'نمو أرجواني تحت الأوراق', 'ذبول سريع'],
          prevention: ['تهوية جيدة بين النباتات', 'تجنب رطوبة الأوراق', 'رش وقائي'],
          treatment: ['رش Cymoxanil أو Metalaxyl'],
        ),
      ],
      companionGood: ['ذرة', 'نعنع', 'بذر الشمر'],
      companionBad: ['خيار', 'كوسة', 'قرع', 'فلفل'],
      doList: ['ازرع على تلال أو خطوط مرتفعة لتصريف الماء', 'دع أفرعاً رئيسية 2-3 فقط', 'ضع تبن أو بلاستيك تحت الثمار'],
      dontList: ['لا تزرع بعد القرعيات', 'لا ترش الأوراق', 'لا تقطف قبل النضج'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات البذور', emoji: '🌱'),
        GrowthStage(name: 'زحف ونمو', fromDay: 10, toDay: 35, description: 'نمو الأفرع الزاحفة', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 35, toDay: 50, description: 'أزهار ذكر وأنثى', emoji: '🌸'),
        GrowthStage(name: 'نمو الثمار', fromDay: 50, toDay: 75, description: 'تضخم سريع للثمار', emoji: '🍉'),
        GrowthStage(name: 'نضج', fromDay: 75, toDay: 90, description: 'نضج وتحلي الثمار', emoji: '🔴'),
      ],
      plantingMethod: 'زراعة شتلات أو بذر مباشر. مسافة 100 سم × 200 سم. على تلال أو خطوط مرتفعة.',
      harvestMethod: 'علامات النضج: جفاف الخيط المتصل بالثمرة، صوت أجوف عند الدق، تلوين البطن الأصفر.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 11. الخيار
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'خيار': CropInfo(
      cropId: 'cucumber',
      cropName: 'الخيار',
      emoji: '🥒',
      cycleDays: 70,
      description: 'الخيار من أسرع الخضروات إنتاجاً وأكثرها طلباً في السوق. يحتاج دفئاً وتعريشاً وريّاً منتظماً. إنتاجيته عالية والحصاد متكرر كل 2-3 أيام.',
      climate: ClimateInfo(
        minTempC: 15,
        maxTempC: 35,
        optimalTempC: 26,
        minHumidityPct: 50,
        maxHumidityPct: 80,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'منخفض - يحتاج تعريشاً',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'عضوية (خصبة)'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'جيد جداً',
        organicMatter: 'غنية جداً',
        texture: 'خفيفة إلى متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 45,
        waterNeedLitersPerHectarePerWeek: 450000,
        frequency: 'يومياً أو كل يوم في الحرارة',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'شتلة': 0.5, 'نمو': 0.9, 'إزهار': 1.1, 'ثمار': 1.4, 'نضج': 0.8},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل مطلقاً. رطوبة منتظمة تمنع تشوه الثمار.',
          'بالرش': 'تجنبه - الرطوبة الزائدة تسبب البياض الدقيقي.',
          'بالغمر (فيضي)': 'غير مناسب.',
          'يدوي': 'اسقِ يومياً عند الجذور.',
          'رش محوري': 'مقبول مع ضبط.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل بنسبة 30%.',
          'رملية': 'زد بنسبة 30%.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'ممتازة.',
        },
        generalTips: ['انقطاع الري يسبب مرارة الثمار', 'ري يومي في الصيف ضروري', 'الخيار 95% ماء - لا تقصر في الري'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست غني', quantityPer100Sqm: 25, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: ''),
        FertilizationStage(stageName: 'نمو ونمو', fromDay: 10, toDay: 35, fertilizerType: 'NPK', fertilizerName: 'NPK 20-20-20', quantityPer100Sqm: 1.0, applicationMethod: 'مع الري أو سطحي خفيف', applicationTime: 'أسبوعياً', notes: 'الخيار نباهم سريع يحتاج تسميداً منتظماً'),
        FertilizationStage(stageName: 'إزهار وثمار', fromDay: 35, toDay: 65, fertilizerType: 'بوتاسيوم + كالسيوم', fertilizerName: 'NPK 8-12-36 + نيترات كالسيوم', quantityPer100Sqm: 1.5, applicationMethod: 'مع الري أسبوعياً', applicationTime: 'كل أسبوع', notes: 'يمنع تشوه الثمار وتشققها'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الدقيقي (Sphaerotheca)',
          type: 'فطري',
          imageAsset: 'assets/diseases/cucumber_powdery.jpg',
          cause: 'فطر Sphaerotheca cucurbitae في الطقس الجاف الحار',
          symptoms: ['مسحوق أبيض على الأوراق', 'اصفرار وجفاف الأوراق', 'تشوه الثمار'],
          prevention: ['تهوية جيدة', 'تجنب الإجهاد المائي', 'رش وقائي بالبوتاسيوم'],
          treatment: ['رش Myclobutanil أو Triadimefon', 'رش كبريت رطب وقائي'],
        ),
      ],
      companionGood: ['فاصولياء', 'ذرة', 'نعنع', 'بصل'],
      companionBad: ['بطيخ', 'طماطم', 'مريمية'],
      doList: ['تعريش مبكر لتحسين التهوية والإنتاج', 'حصاد متكرر كل 2-3 أيام لتحفيز الإنتاج', 'إزالة الثمار القديمة والمشوهة'],
      dontList: ['لا تترك ثمار تنضج على النبات', 'لا تنقطع عن الري', 'لا تزرع بعد القرعيات'],
      growthStages: [
        GrowthStage(name: 'شتلة', fromDay: 0, toDay: 15, description: 'تأقلم الشتلة', emoji: '🌱'),
        GrowthStage(name: 'نمو وتعريش', fromDay: 15, toDay: 35, description: 'صعود الأفرع والتعريش', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 35, toDay: 50, description: 'أزهار صفراء وتلقيح', emoji: '🌸'),
        GrowthStage(name: 'حصاد متكرر', fromDay: 50, toDay: 70, description: 'حصاد كل يومين إلى ثلاثة أيام', emoji: '🥒'),
      ],
      plantingMethod: 'شتلات أو بذر مباشر. مسافة 40 سم × 100 سم. مع تعريش على ارتفاع 1.5-2م.',
      harvestMethod: 'احصد الخيار عند طول 15-20 سم. لا تتركه يصفر. الحصاد المنتظم يزيد الإنتاج.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 12. الجزر
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'جزر': CropInfo(
      cropId: 'carrot',
      cropName: 'الجزر',
      emoji: '🥕',
      cycleDays: 80,
      description: 'الجزر خضروات جذرية غنية بالبيتا كاروتين وفيتامين A. يتحمل البرودة ويمكن زراعته في خريف وشتاء الجزائر. يحتاج تربة خفيفة عميقة لنمو جذور مستقيمة.',
      climate: ClimateInfo(
        minTempC: 5,
        maxTempC: 25,
        optimalTempC: 18,
        minHumidityPct: 45,
        maxHumidityPct: 75,
        annualRainfallMm: 350,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['رملية', 'طميية (لومي)'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'ممتاز',
        organicMatter: 'متوسطة - الزائد يشوه الجذور',
        texture: 'خفيفة جداً وعميقة 30 سم',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 25,
        waterNeedLitersPerHectarePerWeek: 250000,
        frequency: 'مرة إلى مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.9, 'نمو خضري': 0.8, 'نمو الجذر': 1.1, 'نضج': 0.6},
        irrigationTypeAdvice: {
          'بالتنقيط': 'ممتاز للجزر.',
          'بالرش': 'جيد في مرحلة الإنبات.',
          'بالغمر (فيضي)': 'تجنبه - يشوه الجذور.',
          'يدوي': 'اسقِ بانتظام وبلطف.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'غير مناسبة - تشوه الجذور. أضف رمل.',
          'رملية': 'مثالية.',
          'طميية (لومي)': 'جيدة.',
          'طينية رملية': 'مقبولة.',
          'حصوية': 'غير مناسبة.',
          'عضوية (خصبة)': 'تحذير: المادة العضوية الزائدة تشوه الجذور.',
        },
        generalTips: ['إنبات الجزر يحتاج رطوبة مستمرة في التربة', 'تجفيف التربة يسبب تشقق الجذور', 'الري المنتظم بكميات خفيفة أفضل'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'فوسفور وبوتاسيوم فقط', fertilizerName: 'سوبر فوسفات + كبريتات البوتاسيوم', quantityPer100Sqm: 1.5, applicationMethod: 'خلط عميق مع التربة', applicationTime: 'قبل الزراعة', notes: 'تجنب السماد العضوي الطازج - يشوه الجذور'),
        FertilizationStage(stageName: 'نمو', fromDay: 25, toDay: 60, fertilizerType: 'نيتروجين خفيف', fertilizerName: 'يوريا بكميات خفيفة جداً', quantityPer100Sqm: 0.8, applicationMethod: 'بث خفيف مع ري', applicationTime: 'اليوم 30', notes: 'النيتروجين الزائد يقلل حجم الجذور'),
      ],
      diseases: [
        CropDisease(
          name: 'البقعة الأوراقية (Alternaria dauci)',
          type: 'فطري',
          imageAsset: 'assets/diseases/carrot_blight.jpg',
          cause: 'فطر Alternaria dauci',
          symptoms: ['بقع بنية على حواف الأوراق', 'اصفرار وذبول'],
          prevention: ['تناوب المحاصيل', 'رش وقائي'],
          treatment: ['رش Mancozeb'],
        ),
      ],
      companionGood: ['بصل', 'طماطم', 'خس', 'بازلاء'],
      companionBad: ['شمر', 'شبت', 'بقدونس'],
      doList: ['حرث التربة عميقاً 30 سم', 'إزالة الحجارة والعوائق', 'بذر خفيف ثم تخفيف الشتلات'],
      dontList: ['لا تضف سماد طازج مباشر', 'لا تزرع في التربة الثقيلة', 'لا تدع التربة تجف'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 14, description: 'إنبات بطيء يحتاج رطوبة مستمرة', emoji: '🌱'),
        GrowthStage(name: 'نمو خضري', fromDay: 14, toDay: 45, description: 'نمو الأوراق الريشية', emoji: '🌿'),
        GrowthStage(name: 'نمو الجذر', fromDay: 45, toDay: 70, description: 'تضخم الجذر البرتقالي', emoji: '🥕'),
        GrowthStage(name: 'نضج', fromDay: 70, toDay: 80, description: 'اكتمال حجم الجذر ولونه', emoji: '🟠'),
      ],
      plantingMethod: 'بذر مباشر في أخاديد على عمق 1 سم. مسافة 5 سم بين النباتات و30 سم بين الأسطر.',
      harvestMethod: 'اقلع الجزر عند اكتمال اللون البرتقالي. الجذور تبقى في التربة أسابيع إضافية دون مشكلة.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 13. الباذنجان
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'باذنجان': CropInfo(
      cropId: 'eggplant',
      cropName: 'الباذنجان',
      emoji: '🍆',
      cycleDays: 100,
      description: 'الباذنجان خضروات حارة المنشأ تحب الدفء والشمس. يعطي إنتاجاً طويلاً ومتكرراً. شائع جداً في المطبخ الجزائري.',
      climate: ClimateInfo(
        minTempC: 15,
        maxTempC: 38,
        optimalTempC: 26,
        minHumidityPct: 50,
        maxHumidityPct: 75,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'منخفض',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية'],
        minPH: 5.8,
        maxPH: 6.8,
        optimalPH: 6.3,
        drainage: 'جيد',
        organicMatter: 'غنية',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 40,
        waterNeedLitersPerHectarePerWeek: 400000,
        frequency: 'كل يومين',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'شتلة': 0.5, 'نمو': 0.9, 'إزهار': 1.1, 'ثمار': 1.3, 'نضج': 0.8},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل.',
          'بالرش': 'تجنبه.',
          'بالغمر (فيضي)': 'غير مناسب.',
          'يدوي': 'عند الجذور.',
          'رش محوري': 'مقبول.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل بنسبة 30%.',
          'رملية': 'زد بنسبة 30%.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['انتظام الري مهم لمنع مرارة الثمار', 'الجفاف يسبب سقوط الأزهار'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست', quantityPer100Sqm: 20, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل أسبوعين', notes: ''),
        FertilizationStage(stageName: 'نمو وإزهار', fromDay: 20, toDay: 60, fertilizerType: 'NPK + كالسيوم', fertilizerName: 'NPK 15-15-15 + كالسيوم', quantityPer100Sqm: 2.0, applicationMethod: 'سطحي مع ري', applicationTime: 'كل 3 أسابيع', notes: 'الكالسيوم يمنع تعفن القمة'),
        FertilizationStage(stageName: 'ثمار', fromDay: 60, toDay: 90, fertilizerType: 'عالي بوتاسيوم', fertilizerName: 'NPK 10-10-30', quantityPer100Sqm: 1.5, applicationMethod: 'مع الري', applicationTime: 'اليوم 65 و80', notes: 'يحسن جودة الثمار ولونها'),
      ],
      diseases: [
        CropDisease(
          name: 'حفار ساق الباذنجان (Leucinodes)',
          type: 'حشري',
          imageAsset: 'assets/diseases/eggplant_borer.jpg',
          cause: 'يرقات فراشة Leucinodes orbonalis تحفر داخل الثمار والسيقان',
          symptoms: ['ثقوب صغيرة في الثمار', 'برازيرقات داخل الثمرة', 'ذبول فروع كاملة'],
          prevention: ['رش حشري منتظم', 'إزالة ثمار مصابة فوراً', 'مصائد الفرمون'],
          treatment: ['رش Spinosad أو Chlorpyrifos'],
        ),
      ],
      companionGood: ['فاصولياء', 'بازلاء', 'ريحان'],
      companionBad: ['طماطم', 'بطاطس', 'فلفل'],
      doList: ['تعريش النباتات', 'إزالة الثمار الفائتة', 'حصاد متكرر'],
      dontList: ['لا تزرع بعد الطماطم أو البطاطس', 'لا تفرط في الري'],
      growthStages: [
        GrowthStage(name: 'شتلة', fromDay: 0, toDay: 20, description: 'تأقلم الشتلة', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 20, toDay: 50, description: 'نمو الساق والأوراق', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 50, toDay: 65, description: 'أزهار بنفسجية', emoji: '💜'),
        GrowthStage(name: 'ثمار ونضج', fromDay: 65, toDay: 100, description: 'نمو الثمار ونضجها', emoji: '🍆'),
      ],
      plantingMethod: 'شتلات بمسافة 60 سم × 80 سم.',
      harvestMethod: 'احصد الباذنجان عند لمعان الجلد قبل أن تنضج البذور.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 14. الكوسة
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'كوسة': CropInfo(
      cropId: 'zucchini',
      cropName: 'الكوسة',
      emoji: '🥬',
      cycleDays: 60,
      description: 'الكوسة من أسرع الخضروات نمواً وإنتاجاً. تعطي ثماراً في وقت قياسي وتستمر في الإنتاج لأشهر. محبوبة في المطبخ وسهلة الزراعة.',
      climate: ClimateInfo(
        minTempC: 12,
        maxTempC: 35,
        optimalTempC: 25,
        minHumidityPct: 45,
        maxHumidityPct: 75,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'عضوية (خصبة)'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'غنية جداً',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 40,
        waterNeedLitersPerHectarePerWeek: 400000,
        frequency: 'كل يومين',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.5, 'نمو': 0.9, 'إزهار': 1.1, 'ثمار': 1.3},
        irrigationTypeAdvice: {
          'بالتنقيط': 'ممتاز.',
          'بالرش': 'تجنبه - يسبب البياض الدقيقي.',
          'بالغمر (فيضي)': 'غير مناسب.',
          'يدوي': 'عند الجذور.',
          'رش محوري': 'مقبول.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'ممتازة.',
        },
        generalTips: ['الكوسة عطشى في الصيف - لا توقف الري', 'الحصاد المتكرر يحفز الإنتاج'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'عضوي غني', fertilizerName: 'كومبوست ناضج', quantityPer100Sqm: 25, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: 'الكوسة تحب التربة الغنية'),
        FertilizationStage(stageName: 'نمو وإنتاج', fromDay: 15, toDay: 55, fertilizerType: 'NPK متوازن', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 1.5, applicationMethod: 'سطحي أسبوعياً', applicationTime: 'كل أسبوعين', notes: 'الكوسة نهامة تحتاج تسميداً منتظماً'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الدقيقي (Sphaerotheca fuliginea)',
          type: 'فطري',
          imageAsset: 'assets/diseases/zucchini_powdery.jpg',
          cause: 'فطر في الطقس الجاف الحار مع ليالٍ رطبة',
          symptoms: ['مسحوق أبيض على الأوراق', 'اصفرار وموت الأوراق'],
          prevention: ['تهوية جيدة', 'رش كبريت وقائي'],
          treatment: ['رش Triadimefon أو كبريت رطب'],
        ),
      ],
      companionGood: ['ذرة', 'فاصولياء', 'بقدونس'],
      companionBad: ['بطيخ', 'خيار', 'قرع'],
      doList: ['احصد الكوسة صغيرة كل يومين', 'أزل الأوراق العجوز لتحسين التهوية'],
      dontList: ['لا تترك الكوسة تكبر كثيراً على النبات', 'لا تزرع بعد القرعيات'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 7, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 7, toDay: 30, description: 'نمو كبير وسريع', emoji: '🌿'),
        GrowthStage(name: 'إزهار وإنتاج', fromDay: 30, toDay: 60, description: 'إزهار وحصاد متكرر', emoji: '🥬'),
      ],
      plantingMethod: 'بذر مباشر بعمق 3 سم. مسافة 60 × 100 سم.',
      harvestMethod: 'احصد الكوسة عند طول 15-20 سم. الحصاد المتكرر يطيل عمر النبات الإنتاجي.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 15. الفاصولياء
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'فاصولياء': CropInfo(
      cropId: 'beans',
      cropName: 'الفاصولياء',
      emoji: '🫘',
      cycleDays: 75,
      description: 'الفاصولياء بقولية غنية بالبروتين، تثبت النيتروجين في التربة مما يفيد المحاصيل اللاحقة. تزرع صيفاً وخريفاً وإنتاجها وفير.',
      climate: ClimateInfo(
        minTempC: 12,
        maxTempC: 32,
        optimalTempC: 22,
        minHumidityPct: 45,
        maxHumidityPct: 75,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.8,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 30,
        waterNeedLitersPerHectarePerWeek: 300000,
        frequency: 'مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.8, 'نمو': 0.9, 'إزهار': 1.2, 'قرون': 1.1, 'نضج': 0.5},
        irrigationTypeAdvice: {
          'بالتنقيط': 'جيد.',
          'بالرش': 'مقبول لكن تجنب وقت الإزهار.',
          'بالغمر (فيضي)': 'مقبول مع حذر.',
          'يدوي': 'عند الجذور.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل بنسبة 25%.',
          'رملية': 'زد بنسبة 25%.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['الفاصولياء لا تحتاج نيتروجيناً زائداً - تثبته بنفسها', 'تجنب الري على الأزهار'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور وبوتاسيوم', fertilizerName: 'سوبر فوسفات + بوتاسيوم', quantityPer100Sqm: 1.5, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: 'تجنب النيتروجين الزائد - البقوليات تثبته طبيعياً'),
        FertilizationStage(stageName: 'إزهار وقرون', fromDay: 30, toDay: 60, fertilizerType: 'بوتاسيوم', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 1.0, applicationMethod: 'سطحي خفيف', applicationTime: 'اليوم 35', notes: 'يحسن امتلاء القرون'),
      ],
      diseases: [
        CropDisease(
          name: 'صدأ الفاصولياء (Uromyces)',
          type: 'فطري',
          imageAsset: 'assets/diseases/bean_rust.jpg',
          cause: 'فطر Uromyces appendiculatus',
          symptoms: ['بقع برتقالية على الأوراق والقرون', 'اصفرار وسقوط الأوراق'],
          prevention: ['تناوب المحاصيل', 'رش وقائي'],
          treatment: ['رش Mancozeb أو Triadimefon'],
        ),
      ],
      companionGood: ['ذرة', 'كوسة', 'خيار', 'بطاطس'],
      companionBad: ['بصل', 'ثوم', 'كرات'],
      doList: ['إيقاع العصا لنوع المتسلق', 'حصاد القرون الخضراء مبكراً'],
      dontList: ['لا تزرع بعد البقوليات', 'لا تفرط في النيتروجين'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 8, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 8, toDay: 35, description: 'نمو الأوراق والسيقان', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 35, toDay: 50, description: 'أزهار بيضاء أو أرجوانية', emoji: '🌸'),
        GrowthStage(name: 'قرون ونضج', fromDay: 50, toDay: 75, description: 'نمو القرون ونضجها', emoji: '🫘'),
      ],
      plantingMethod: 'بذر مباشر بعمق 4-5 سم. مسافة 10 سم × 50 سم.',
      harvestMethod: 'احصد القرون الخضراء طازجة. للبذور الجافة اتركها تنضج كاملاً.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 16. البازلاء
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'بازلاء': CropInfo(
      cropId: 'peas',
      cropName: 'البازلاء',
      emoji: '🫛',
      cycleDays: 80,
      description: 'البازلاء بقولية شتوية تحب البرودة وتُزرع في الخريف والشتاء. حلوة الطعم غنية بالبروتين والفيتامينات. تثبت النيتروجين وتحسن التربة.',
      climate: ClimateInfo(
        minTempC: 0,
        maxTempC: 24,
        optimalTempC: 15,
        minHumidityPct: 50,
        maxHumidityPct: 80,
        annualRainfallMm: 450,
        sunExposure: 'كامل',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 25,
        waterNeedLitersPerHectarePerWeek: 250000,
        frequency: 'مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.9, 'نمو': 0.8, 'إزهار': 1.2, 'قرون': 1.0, 'نضج': 0.3},
        irrigationTypeAdvice: {
          'بالتنقيط': 'ممتاز.',
          'بالرش': 'تجنب وقت الإزهار.',
          'بالغمر (فيضي)': 'مقبول مع حذر.',
          'يدوي': 'بانتظام.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['البازلاء تحب البرودة ولا تتحمل الحرارة الشديدة', 'توقف عن الري عند النضج'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور', fertilizerName: 'سوبر فوسفات', quantityPer100Sqm: 1.5, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: 'تثبت النيتروجين بنفسها'),
        FertilizationStage(stageName: 'إزهار', fromDay: 30, toDay: 55, fertilizerType: 'بوتاسيوم خفيف', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 0.8, applicationMethod: 'سطحي خفيف', applicationTime: 'اليوم 35', notes: 'يحسن جودة القرون'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الدقيقي (Erysiphe pisi)',
          type: 'فطري',
          imageAsset: 'assets/diseases/peas_powdery.jpg',
          cause: 'فطر Erysiphe pisi في الطقس الجاف الدافئ',
          symptoms: ['مسحوق أبيض على الأوراق والقرون', 'ذبول النباتات'],
          prevention: ['أصناف مقاومة', 'تهوية جيدة'],
          treatment: ['رش Triadimefon'],
        ),
      ],
      companionGood: ['جزر', 'خس', 'ذرة', 'فجل'],
      companionBad: ['بصل', 'ثوم', 'كرات'],
      doList: ['زراعة مبكرة في الخريف', 'دعم بالعصي أو الشبك'],
      dontList: ['لا تزرع في الصيف', 'لا تفرط في النيتروجين'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو وتسلق', fromDay: 10, toDay: 40, description: 'تسلق الأفرع', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 40, toDay: 55, description: 'أزهار بيضاء', emoji: '🌸'),
        GrowthStage(name: 'قرون ونضج', fromDay: 55, toDay: 80, description: 'نمو القرون', emoji: '🫛'),
      ],
      plantingMethod: 'بذر مباشر بعمق 3-4 سم. مسافة 8 سم × 40 سم.',
      harvestMethod: 'احصد القرون الخضراء الممتلئة طازجة. للبذور الجافة اتركها تنضج كاملاً.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 17. العدس
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'عدس': CropInfo(
      cropId: 'lentil',
      cropName: 'العدس',
      emoji: '🫘',
      cycleDays: 110,
      description: 'العدس بقولية قديمة غنية بالبروتين والحديد. يتحمل الجفاف ويثبت النيتروجين. يزرع شتاءً في المناطق شبه الجافة.',
      climate: ClimateInfo(
        minTempC: 0,
        maxTempC: 28,
        optimalTempC: 18,
        minHumidityPct: 30,
        maxHumidityPct: 70,
        annualRainfallMm: 300,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية رملية', 'حصوية'],
        minPH: 6.0,
        maxPH: 8.0,
        optimalPH: 7.0,
        drainage: 'جيد',
        organicMatter: 'متوسطة',
        texture: 'أي',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 18,
        waterNeedLitersPerHectarePerWeek: 180000,
        frequency: 'مرة أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.8, 'نمو': 0.8, 'إزهار': 1.1, 'نضج': 0.2},
        irrigationTypeAdvice: {
          'بالتنقيط': 'جيد.',
          'بالرش': 'مقبول.',
          'بالغمر (فيضي)': 'مقبول مع حذر.',
          'يدوي': 'بانتظام.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['العدس يتحمل الجفاف أكثر من غيره', 'الري الزائد يضر به'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور', fertilizerName: 'سوبر فوسفات', quantityPer100Sqm: 1.0, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: 'لا يحتاج نيتروجيناً'),
      ],
      diseases: [
        CropDisease(
          name: 'لفحة العدس (Ascochyta)',
          type: 'فطري',
          imageAsset: 'assets/diseases/lentil_blight.jpg',
          cause: 'فطر Ascochyta lentis',
          symptoms: ['بقع بنية على الأوراق والقرون', 'ذبول النباتات'],
          prevention: ['بذار صحي', 'تناوب المحاصيل'],
          treatment: ['رش Mancozeb'],
        ),
      ],
      companionGood: ['قمح', 'شعير'],
      companionBad: ['بصل', 'ثوم'],
      doList: ['زراعة مبكرة خريف-شتاء', 'بذار معالج ضد الأمراض'],
      dontList: ['لا تزرع في تربة حامضة', 'لا تفرط في الري'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 10, toDay: 60, description: 'نمو شجيري', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 60, toDay: 80, description: 'أزهار صغيرة', emoji: '🌸'),
        GrowthStage(name: 'نضج', fromDay: 80, toDay: 110, description: 'نضج القرون والبذور', emoji: '🫘'),
      ],
      plantingMethod: 'بذر مباشر بعمق 3-4 سم. معدل 80-100 كغ/هكتار.',
      harvestMethod: 'احصد عند اصفرار وجفاف القرون. حصاد آلي أو يدوي.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 18. الخس
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'خس': CropInfo(
      cropId: 'lettuce',
      cropName: 'الخس',
      emoji: '🥬',
      cycleDays: 55,
      description: 'الخس أسرع الخضروات نضجاً ويزرع في الخريف والشتاء. يحب البرودة ويكره الحرارة الشديدة. إنتاجه سريع ومربح جداً في وقت قصير.',
      climate: ClimateInfo(
        minTempC: 5,
        maxTempC: 22,
        optimalTempC: 15,
        minHumidityPct: 55,
        maxHumidityPct: 80,
        annualRainfallMm: 300,
        sunExposure: 'جزئي مقبول',
        windTolerance: 'متوسط',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'عضوية (خصبة)'],
        minPH: 6.0,
        maxPH: 7.0,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'غنية جداً',
        texture: 'خفيفة إلى متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 30,
        waterNeedLitersPerHectarePerWeek: 300000,
        frequency: 'يومياً أو كل يوم',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.9, 'نمو': 1.1, 'نضج': 0.7},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل.',
          'بالرش': 'مناسب في الصباح.',
          'بالغمر (فيضي)': 'غير مناسب.',
          'يدوي': 'اسقِ يومياً.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري بشكل ملحوظ.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'ممتازة.',
        },
        generalTips: ['الخس يحتاج رطوبة مستمرة', 'الجفاف يسبب مرارة الأوراق وتشققها'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'عضوي غني', fertilizerName: 'كومبوست ناضج', quantityPer100Sqm: 20, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: ''),
        FertilizationStage(stageName: 'نمو', fromDay: 10, toDay: 40, fertilizerType: 'نيتروجين خفيف', fertilizerName: 'يوريا مخففة', quantityPer100Sqm: 0.8, applicationMethod: 'مع الري', applicationTime: 'اليوم 15 و30', notes: 'يعزز نمو الأوراق الخضراء'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الزغبي (Bremia lactucae)',
          type: 'فطري',
          imageAsset: 'assets/diseases/lettuce_downy.jpg',
          cause: 'فطر Bremia lactucae في الطقس البارد الرطب',
          symptoms: ['بقع صفراء على الأوراق', 'نمو أبيض زغبي أسفل الأوراق'],
          prevention: ['أصناف مقاومة', 'تهوية جيدة'],
          treatment: ['رش Metalaxyl'],
        ),
      ],
      companionGood: ['جزر', 'خيار', 'فجل', 'بصل'],
      companionBad: ['كرفس', 'بقدونس'],
      doList: ['زراعة في الخريف والشتاء', 'حصاد صباحاً لأفضل نضارة'],
      dontList: ['لا تزرع في الحرارة الشديدة', 'لا تنقطع عن الري'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 7, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 7, toDay: 40, description: 'نمو الأوراق', emoji: '🌿'),
        GrowthStage(name: 'نضج', fromDay: 40, toDay: 55, description: 'اكتمال الرأس أو الأوراق', emoji: '🥬'),
      ],
      plantingMethod: 'شتلات أو بذر مباشر. مسافة 25 × 30 سم.',
      harvestMethod: 'احصد صباحاً عند اكتمال الرأس. الخس السريع يُحصد ورقة ورقة.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 19. اليقطين (القرع)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'يقطين': CropInfo(
      cropId: 'pumpkin',
      cropName: 'اليقطين',
      emoji: '🎃',
      cycleDays: 110,
      description: 'اليقطين من القرعيات الكبيرة الغنية بالفيتامينات والمعادن. يحب الدفء ويحتاج مساحة كبيرة للنمو. يُستخدم غذاءً وعلفاً.',
      climate: ClimateInfo(
        minTempC: 15,
        maxTempC: 38,
        optimalTempC: 28,
        minHumidityPct: 40,
        maxHumidityPct: 70,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'منخفض',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'عضوية (خصبة)', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 7.5,
        optimalPH: 6.5,
        drainage: 'جيد',
        organicMatter: 'غنية',
        texture: 'متوسطة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 40,
        waterNeedLitersPerHectarePerWeek: 400000,
        frequency: 'كل يومين إلى ثلاثة',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.5, 'نمو': 0.8, 'إزهار': 1.2, 'ثمار': 1.4, 'نضج': 0.5},
        irrigationTypeAdvice: {
          'بالتنقيط': 'الأفضل.',
          'بالرش': 'تجنبه.',
          'بالغمر (فيضي)': 'مقبول.',
          'يدوي': 'عند الجذور.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'ممتازة.',
        },
        generalTips: ['قلل الري عند اقتراب النضج', 'الثمار الكبيرة تحتاج ماءً وفيراً'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -14, toDay: 0, fertilizerType: 'عضوي', fertilizerName: 'كومبوست + سماد عضوي', quantityPer100Sqm: 30, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل أسبوعين', notes: 'اليقطين نهام'),
        FertilizationStage(stageName: 'نمو وإزهار', fromDay: 20, toDay: 55, fertilizerType: 'NPK', fertilizerName: 'NPK 15-15-15', quantityPer100Sqm: 2.0, applicationMethod: 'سطحي', applicationTime: 'اليوم 25 و50', notes: ''),
        FertilizationStage(stageName: 'تضخم الثمار', fromDay: 55, toDay: 90, fertilizerType: 'بوتاسيوم', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 2.0, applicationMethod: 'مع الري', applicationTime: 'اليوم 60', notes: 'يضخم الثمار ويحسن تخزينها'),
      ],
      diseases: [
        CropDisease(
          name: 'البياض الدقيقي (Sphaerotheca)',
          type: 'فطري',
          imageAsset: 'assets/diseases/pumpkin_powdery.jpg',
          cause: 'فطر في الطقس الجاف الحار',
          symptoms: ['مسحوق أبيض على الأوراق', 'اصفرار وجفاف'],
          prevention: ['تهوية جيدة', 'رش كبريت وقائي'],
          treatment: ['رش Triadimefon'],
        ),
      ],
      companionGood: ['ذرة', 'فاصولياء', 'نعنع'],
      companionBad: ['بطاطس', 'خيار', 'بطيخ'],
      doList: ['دع فرعين رئيسيين فقط', 'ضع قش تحت الثمار لحمايتها'],
      dontList: ['لا تزرع بعد القرعيات', 'لا ترش الأوراق'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 10, description: 'إنبات سريع', emoji: '🌱'),
        GrowthStage(name: 'نمو وزحف', fromDay: 10, toDay: 40, description: 'نمو الأفرع الزاحفة الكبيرة', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 40, toDay: 60, description: 'أزهار كبيرة صفراء', emoji: '🌸'),
        GrowthStage(name: 'نمو الثمار', fromDay: 60, toDay: 95, description: 'تضخم الثمار تدريجياً', emoji: '🎃'),
        GrowthStage(name: 'نضج', fromDay: 95, toDay: 110, description: 'تصلب القشرة وجفاف الساق', emoji: '🟠'),
      ],
      plantingMethod: 'بذر مباشر أو شتلات. مسافة 100 × 200 سم. تحتاج مساحة واسعة.',
      harvestMethod: 'احصد عندما يصلب اللون ويجف الساق المتصل بالثمرة. اتركها تجف أسبوعاً قبل التخزين.',
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 20. الفول
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'فول': CropInfo(
      cropId: 'fava_beans',
      cropName: 'الفول',
      emoji: '🫘',
      cycleDays: 130,
      description: 'الفول بقولية شتوية مهمة في الجزائر والمتوسط. يتحمل البرودة ويثبت النيتروجين بشكل ممتاز. غني بالبروتين والحديد وحمض الفوليك.',
      climate: ClimateInfo(
        minTempC: -5,
        maxTempC: 25,
        optimalTempC: 16,
        minHumidityPct: 50,
        maxHumidityPct: 80,
        annualRainfallMm: 400,
        sunExposure: 'كامل',
        windTolerance: 'عالٍ',
      ),
      soil: SoilRequirements(
        suitableSoils: ['طميية (لومي)', 'طينية', 'طينية رملية'],
        minPH: 6.0,
        maxPH: 8.0,
        optimalPH: 6.8,
        drainage: 'متوسط إلى جيد',
        organicMatter: 'متوسطة',
        texture: 'متوسطة إلى ثقيلة',
      ),
      irrigation: IrrigationGuide(
        waterNeedMmPerWeek: 28,
        waterNeedLitersPerHectarePerWeek: 280000,
        frequency: 'مرتين أسبوعياً',
        bestTime: 'الصباح',
        stageWaterMultiplier: {'إنبات': 0.9, 'نمو': 0.8, 'إزهار': 1.3, 'قرون': 1.0, 'نضج': 0.2},
        irrigationTypeAdvice: {
          'بالتنقيط': 'جيد.',
          'بالرش': 'تجنب وقت الإزهار.',
          'بالغمر (فيضي)': 'مقبول.',
          'يدوي': 'بانتظام.',
          'رش محوري': 'مناسب.',
        },
        soilTypeAdvice: {
          'طينية': 'الفول يتحمل التربة الطينية نسبياً. قلل الري.',
          'رملية': 'زد الري.',
          'طميية (لومي)': 'اتبع الجدول.',
          'طينية رملية': 'اتبع الجدول.',
          'حصوية': 'ري متكرر.',
          'عضوية (خصبة)': 'اتبع الجدول.',
        },
        generalTips: ['الإزهار أكثر مرحلة تحتاج ماءً', 'الجفاف وقت الإزهار يسبب إجهاضاً للأزهار'],
      ),
      fertilization: [
        FertilizationStage(stageName: 'قبل الزراعة', fromDay: -7, toDay: 0, fertilizerType: 'فوسفور وبوتاسيوم', fertilizerName: 'سوبر فوسفات + بوتاسيوم', quantityPer100Sqm: 1.5, applicationMethod: 'خلط مع التربة', applicationTime: 'قبل الزراعة', notes: 'يثبت النيتروجين بنفسه'),
        FertilizationStage(stageName: 'إزهار وقرون', fromDay: 50, toDay: 90, fertilizerType: 'بوتاسيوم', fertilizerName: 'كبريتات البوتاسيوم', quantityPer100Sqm: 1.0, applicationMethod: 'سطحي خفيف', applicationTime: 'اليوم 55', notes: 'يدعم امتلاء القرون'),
      ],
      diseases: [
        CropDisease(
          name: 'الصدأ (Uromyces fabae)',
          type: 'فطري',
          imageAsset: 'assets/diseases/fava_rust.jpg',
          cause: 'فطر Uromyces fabae في الطقس الرطب',
          symptoms: ['بقع صدئية بنية برتقالية على الأوراق', 'اصفرار وسقوط الأوراق'],
          prevention: ['أصناف مقاومة', 'رش وقائي', 'تناوب المحاصيل'],
          treatment: ['رش Mancozeb أو Triadimefon'],
        ),
      ],
      companionGood: ['قمح', 'شعير', 'بطاطس', 'ذرة'],
      companionBad: ['بصل', 'ثوم', 'كرات'],
      doList: ['زراعة أكتوبر-نوفمبر', 'تقليم القمم عند الإزهار لتحسين الإنتاج'],
      dontList: ['لا تزرع في الصيف', 'لا تفرط في الري قرب الحصاد'],
      growthStages: [
        GrowthStage(name: 'إنبات', fromDay: 0, toDay: 14, description: 'إنبات بطيء', emoji: '🌱'),
        GrowthStage(name: 'نمو', fromDay: 14, toDay: 60, description: 'نمو الساق والأوراق', emoji: '🌿'),
        GrowthStage(name: 'إزهار', fromDay: 60, toDay: 85, description: 'أزهار بيضاء بقلب أسود', emoji: '🌸'),
        GrowthStage(name: 'قرون ونضج', fromDay: 85, toDay: 130, description: 'نمو القرون واسوادها', emoji: '🫘'),
      ],
      plantingMethod: 'بذر مباشر بعمق 5-6 سم. مسافة 20 سم × 60 سم.',
      harvestMethod: 'للبذور الطازجة احصد القرون الخضراء. للجافة اتركها تسود وتجف على النبات.',
    ),
  };

  static CropInfo? getCrop(String cropName) {
    return crops[cropName];
  }

  static List<String> getAllCropNames() {
    return crops.keys.toList();
  }
}