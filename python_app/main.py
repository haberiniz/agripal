import json
import sys
import os
from datetime import datetime, date, timedelta
import warnings
warnings.filterwarnings('ignore')

# ============================================================
# قاعدة البيانات (Data Base)
# ============================================================

# ربط كل ولاية بنوع التربة (مطابق لواجهة Flutter)
WILAYA_SOIL_MAPPING = {
    "أدرار": "Sols sableux (Erg)", "الشلف": "Sols alluviaux", "الأغواط": "Sols sableux (Erg)",
    "أم البواقي": "Vertisols", "باتنة": "Sols peu évolués d'érosion",
    "بجاية": "Sols bruns calcaires", "بسكرة": "Sols sableux (Erg)",
    "بشار": "Sols sableux (Erg)", "البليدة": "Sols alluviaux", "البويرة": "Sols bruns calcaires",
    "تمنراست": "Sols minéraux bruts (Reg)", "تبسة": "Sols bruns calcaires",
    "تلمسان": "Sols bruns calcaires", "تيارت": "Sols bruns calcaires",
    "تيزي وزو": "Sols peu évolués d'érosion", "الجزائر": "Sols alluviaux",
    "الجلفة": "Sols bruns calcaires", "جيجل": "Sols bruns calcaires",
    "سطيف": "Sols bruns calcaires", "سعيدة": "Sols bruns calcaires",
    "سكيكدة": "Sols bruns calcaires", "سيدي بلعباس": "Sols bruns calcaires",
    "عنابة": "Sols alluviaux", "قالمة": "Vertisols", "قسنطينة": "Vertisols",
    "المدية": "Sols bruns calcaires", "مستغانم": "Sols bruns calcaires",
    "المسيلة": "Sols bruns calcaires", "معسكر": "Sols bruns calcaires",
    "ورقلة": "Sols sableux (Erg)", "وهران": "Sols bruns calcaires",
    "البيض": "Sols bruns calcaires", "إليزي": "Sols minéraux bruts (Reg)",
    "برج بوعريريج": "Sols bruns calcaires", "بومرداس": "Sols bruns calcaires",
    "الطارف": "Sols hydromorphes (Oasis)", "تندوف": "Sols minéraux bruts (Reg)",
    "تيسمسيلت": "Sols bruns calcaires", "الوادي": "Sols sableux (Erg)",
    "خنشلة": "Sols bruns calcaires", "سوق أهراس": "Sols bruns calcaires",
    "تيبازة": "Sols alluviaux", "ميلة": "Vertisols", "عين الدفلى": "Sols alluviaux",
    "النعامة": "Sols bruns calcaires", "عين تموشنت": "Sols bruns calcaires",
    "غرداية": "Sols hydromorphes (Oasis)", "غليزان": "Sols bruns calcaires",
    "تيميمون": "Sols sableux (Erg)", "برج باجي مختار": "Sols minéraux bruts (Reg)",
    "أولاد جلال": "Sols sableux (Erg)", "بني عباس": "Sols sableux (Erg)",
    "عين صالح": "Sols minéraux bruts (Reg)", "عين قزام": "Sols minéraux bruts (Reg)",
    "تقرت": "Sols hydromorphes (Oasis)", "جانت": "Sols minéraux bruts (Reg)",
    "المغير": "Sols hydromorphes (Oasis)", "المنيعة": "Sols sableux (Erg)"
}

SOL_NUTRIENTS_COMPLET = {
    "Sols alluviaux": {
        "N": 85, "P": 45, "K": 180, "Ca": 2500, "Mg": 350, "S": 25,
        "Fe": 15, "Zn": 3.5, "B": 1.2, "Mn": 8,
        "ph": 7.0, "mo_pct": 3.5, "cec": 22, "efficacite": 0.80,
        "description": "Sols fertiles de vallée - Équilibrés"
    },
    "Sols bruns calcaires": {
        "N": 55, "P": 25, "K": 150, "Ca": 3500, "Mg": 250, "S": 18,
        "Fe": 8, "Zn": 1.8, "B": 0.8, "Mn": 5,
        "ph": 7.6, "mo_pct": 2.0, "cec": 18, "efficacite": 0.75,
        "description": "Sols calcaires - Carence fréquente en P et Zn"
    },
    "Vertisols": {
        "N": 70, "P": 35, "K": 200, "Ca": 2800, "Mg": 400, "S": 30,
        "Fe": 20, "Zn": 4.0, "B": 1.5, "Mn": 10,
        "ph": 7.5, "mo_pct": 3.0, "cec": 28, "efficacite": 0.85,
        "description": "Sols argileux - Excellente rétention"
    },
    "Sols peu évolués d'érosion": {
        "N": 25, "P": 10, "K": 80, "Ca": 1500, "Mg": 120, "S": 8,
        "Fe": 5, "Zn": 0.8, "B": 0.3, "Mn": 3,
        "ph": 7.0, "mo_pct": 1.0, "cec": 10, "efficacite": 0.55,
        "description": "Sols érodés - Carences multiples"
    },
    "Sols sableux (Erg)": {
        "N": 12, "P": 6, "K": 45, "Ca": 800, "Mg": 60, "S": 5,
        "Fe": 3, "Zn": 0.4, "B": 0.2, "Mn": 1.5,
        "ph": 8.0, "mo_pct": 0.3, "cec": 5, "efficacite": 0.50,
        "description": "Sols sableux - Très pauvres, lessivage intense"
    },
    "Sols minéraux bruts (Reg)": {
        "N": 5, "P": 2, "K": 25, "Ca": 500, "Mg": 30, "S": 2,
        "Fe": 2, "Zn": 0.2, "B": 0.1, "Mn": 1,
        "ph": 8.2, "mo_pct": 0.1, "cec": 3, "efficacite": 0.40,
        "description": "Sols squelettiques - Extrêmement pauvres"
    },
    "Sols hydromorphes (Oasis)": {
        "N": 40, "P": 20, "K": 110, "Ca": 1800, "Mg": 200, "S": 15,
        "Fe": 10, "Zn": 2.0, "B": 0.8, "Mn": 4,
        "ph": 7.5, "mo_pct": 1.5, "cec": 15, "efficacite": 0.65,
        "description": "Sols d'oasis - Fertilité modérée"
    }
}

SEUILS_EXCES = {
    "N": {"max": 300, "message": "Excès d'azote → Risque verse, nitrates, pollution nappe"},
    "P": {"max": 100, "message": "Excès de phosphore → Blocage Zn/Fe, eutrophisation"},
    "K": {"max": 300, "message": "Excès de potassium → Blocage Ca/Mg, déséquilibre cations"},
    "ratio_NK": {"min": 0.5, "max": 2.0, "message": "Ratio N/K déséquilibré → Ajuster fertilisation"},
    "ratio_PK": {"min": 0.2, "max": 1.0, "message": "Ratio P/K anormal → Vérifier disponibilité"},
    "ratio_CaMg": {"min": 3.0, "max": 8.0, "message": "Ratio Ca/Mg déséquilibré → Problème structure sol"},
    "ph_acide": {"max": 6.0, "message": "pH acide → Fixation P, toxicité Al/Mn"},
    "ph_basique": {"min": 8.0, "message": "pH basique → Blocage P, Fe, Zn, Mn"},
    "mo_faible": {"max": 1.0, "message": "Matière organique faible → Faible rétention eau/nutriments"},
    "cec_faible": {"max": 10, "message": "CEC faible → Faible capacité échange cationique"},
}

CROPS_DATABASE = {
    "قمح صلب": {
        "categorie": "Céréale", "cycle_jours": 180,
        "stades": {
            "الإنبات": {"duree": 15, "N": 25, "P": 40, "K": 30, "Ca": 10, "Mg": 5, "S": 3},
            "الخضري": {"duree": 55, "N": 70, "P": 35, "K": 55, "Ca": 15, "Mg": 8, "S": 5},
            "الاستطالة": {"duree": 30, "N": 60, "P": 25, "K": 45, "Ca": 10, "Mg": 7, "S": 4},
            "التسنبل": {"duree": 40, "N": 45, "P": 20, "K": 50, "Ca": 8, "Mg": 5, "S": 3},
            "النضج": {"duree": 40, "N": 10, "P": 15, "K": 20, "Ca": 5, "Mg": 3, "S": 2},
        },
        "temperature_optimale": [12, 25], "temperature_critique": [0, 35],
        "irrigation": {"الإنبات": 3, "الخضري": 5, "الاستطالة": 6, "التسنبل": 7, "النضج": 2},
    },
    "شعير": {
        "categorie": "Céréale", "cycle_jours": 150,
        "stades": {
            "الإنبات": {"duree": 12, "N": 20, "P": 35, "K": 25, "Ca": 8, "Mg": 4, "S": 2},
            "الخضري": {"duree": 45, "N": 60, "P": 30, "K": 45, "Ca": 12, "Mg": 7, "S": 4},
            "الاستطالة": {"duree": 25, "N": 50, "P": 20, "K": 40, "Ca": 10, "Mg": 6, "S": 3},
            "التسنبل": {"duree": 35, "N": 40, "P": 18, "K": 45, "Ca": 7, "Mg": 4, "S": 2},
            "النضج": {"duree": 33, "N": 8, "P": 12, "K": 18, "Ca": 4, "Mg": 2, "S": 1},
        },
        "temperature_optimale": [10, 28], "temperature_critique": [-2, 38],
        "irrigation": {"الإنبات": 2.5, "الخضري": 4.5, "الاستطالة": 5.5, "التسنبل": 6.5, "النضج": 1.5},
    },
    "طماطم": {
        "categorie": "Légume", "cycle_jours": 120,
        "stades": {
            "الشتلات": {"duree": 25, "N": 30, "P": 50, "K": 40, "Ca": 15, "Mg": 8, "S": 5},
            "النمو الخضري": {"duree": 35, "N": 65, "P": 35, "K": 55, "Ca": 20, "Mg": 10, "S": 7},
            "الازهار": {"duree": 20, "N": 45, "P": 45, "K": 60, "Ca": 25, "Mg": 12, "S": 8},
            "الاثمار": {"duree": 40, "N": 40, "P": 35, "K": 75, "Ca": 30, "Mg": 15, "S": 10},
        },
        "temperature_optimale": [18, 30], "temperature_critique": [8, 40],
        "irrigation": {"الشتلات": 4, "النمو الخضري": 6, "الازهار": 7, "الاثمار": 8},
    },
    "بطاطس": {
        "categorie": "Légume", "cycle_jours": 100,
        "stades": {
            "الإنبات": {"duree": 20, "N": 25, "P": 45, "K": 40, "Ca": 12, "Mg": 7, "S": 4},
            "النمو الخضري": {"duree": 30, "N": 55, "P": 30, "K": 50, "Ca": 18, "Mg": 10, "S": 6},
            "تكوين الدرنات": {"duree": 30, "N": 35, "P": 35, "K": 70, "Ca": 20, "Mg": 12, "S": 8},
            "النضج": {"duree": 20, "N": 10, "P": 15, "K": 25, "Ca": 8, "Mg": 5, "S": 3},
        },
        "temperature_optimale": [15, 25], "temperature_critique": [5, 35],
        "irrigation": {"الإنبات": 3.5, "النمو الخضري": 5.5, "تكوين الدرنات": 7, "النضج": 2.5},
    },
    "زيتون": {
        "categorie": "Arbre fruitier", "cycle_jours": 365,
        "stades": {
            "سكون شتوي": {"duree": 90, "N": 20, "P": 30, "K": 35, "Ca": 10, "Mg": 5, "S": 3},
            "إزهار": {"duree": 45, "N": 35, "P": 45, "K": 50, "Ca": 15, "Mg": 8, "S": 5},
            "نمو الثمار": {"duree": 120, "N": 40, "P": 35, "K": 60, "Ca": 20, "Mg": 10, "S": 7},
            "نضج": {"duree": 110, "N": 15, "P": 20, "K": 25, "Ca": 10, "Mg": 5, "S": 3},
        },
        "temperature_optimale": [10, 35], "temperature_critique": [-5, 45],
        "irrigation": {"سكون شتوي": 1, "إزهار": 3, "نمو الثمار": 5, "نضج": 2},
    },
}

FERTILIZER_DATABASE = {
    "Urea": {"name": "اليوريا", "icon": "🍚", "composition": {"N": 46, "P": 0, "K": 0}, "how": "نثر أو حقن", "when": "مراحل النمو الخضري"},
    "TSP": {"name": "سوبر فوسفات ثلاثي", "icon": "🦴", "composition": {"N": 0, "P": 46, "K": 0}, "how": "خلط مع التربة", "when": "قبل الزراعة أو عند الإنبات"},
    "Sulfate Potasse": {"name": "كبريتات البوتاسيوم", "icon": "🧂", "composition": {"N": 0, "P": 0, "K": 50}, "how": "نثر أو ري", "when": "مراحل الإزهار والإثمار"},
    "Nitrate Calcium": {"name": "نترات الكالسيوم", "icon": "🥛", "composition": {"N": 15.5, "Ca": 26}, "how": "ري أو رش ورقي", "when": "مراحل النمو الحرجة"},
    "Sulfate Magnésium": {"name": "كبريتات المغنيسيوم", "icon": "🧪", "composition": {"Mg": 16, "S": 13}, "how": "ري أو رش ورقي", "when": "عند ظهور أعراض النقص"},
    "DAP": {"name": "فوسفات ثنائي الأمونيوم", "icon": "🍚🦴", "composition": {"N": 18, "P": 46, "K": 0}, "how": "خلط مع التربة", "when": "قبل الزراعة"},
    "NPK_20_20_20": {"name": "سماد مركب NPK (20-20-20)", "icon": "🌱", "composition": {"N": 20, "P": 20, "K": 20}, "how": "ري أو رش ورقي", "when": "مراحل النمو العامة"},
}

# ============================================================
# الوظائف الأساسية (Core Functions)
# ============================================================

def detecter_exces_et_desequilibres(soil_data, engrais_apportes):
    alertes, avertissements, conseils = [], [], []
    niveau_risque = "Faible"

    for nut, quantite in engrais_apportes.items():
        if nut in SEUILS_EXCES and "max" in SEUILS_EXCES[nut] and quantite > SEUILS_EXCES[nut]["max"]:
            alertes.append(SEUILS_EXCES[nut]["message"])
            conseils.append(f"Réduire l'apport de {nut}.")
            niveau_risque = "Élevé"

    for nut, valeur in soil_data.items():
        if nut in SEUILS_EXCES:
            if "max" in SEUILS_EXCES[nut] and valeur > SEUILS_EXCES[nut]["max"]:
                alertes.append(SEUILS_EXCES[nut]["message"])
                conseils.append(f"Surveiller et réduire {nut} dans le sol.")
                niveau_risque = "Élevé"
            if "min" in SEUILS_EXCES[nut] and valeur < SEUILS_EXCES[nut]["min"]:
                avertissements.append(SEUILS_EXCES[nut]["message"])
                conseils.append(f"Augmenter {nut} dans le sol.")
                if niveau_risque == "Faible": niveau_risque = "Modéré"

    n_val = soil_data.get("N", 0) + engrais_apportes.get("N", 0)
    k_val = soil_data.get("K", 0) + engrais_apportes.get("K", 0)
    if k_val > 0 and n_val > 0:
        ratio = n_val / k_val
        limits = SEUILS_EXCES["ratio_NK"]
        if ratio < limits["min"] or ratio > limits["max"]:
            avertissements.append(limits["message"])
            if niveau_risque == "Faible": niveau_risque = "Modéré"

    ph = soil_data.get("ph", 7.0)
    if ph < SEUILS_EXCES["ph_acide"]["max"]:
        alertes.append(SEUILS_EXCES["ph_acide"]["message"])
        conseils.append("Chaulage recommandé pour augmenter le pH.")
        niveau_risque = "Élevé"
    elif ph > SEUILS_EXCES["ph_basique"]["min"]:
        alertes.append(SEUILS_EXCES["ph_basique"]["message"])
        conseils.append("Apport de soufre ou matière organique acide.")
        niveau_risque = "Élevé"

    if soil_data.get("mo_pct", 0) < SEUILS_EXCES["mo_faible"]["max"]:
        avertissements.append(SEUILS_EXCES["mo_faible"]["message"])
        if niveau_risque == "Faible": niveau_risque = "Modéré"

    return {"alertes": alertes, "avertissements": avertissements, "conseils": conseils, "risque": niveau_risque}

def calculer_stade(date_plantation_str, culture_data):
    try:
        date_plantation = datetime.strptime(date_plantation_str, '%Y-%m-%d').date()
    except ValueError:
        return None
    
    today = date.today()
    jours_ecoules = (today - date_plantation).days
    if jours_ecoules < 0: return None

    jours_cumules = 0
    stade_actuel = list(culture_data["stades"].keys())[0]
    for nom, info in culture_data["stades"].items():
        jours_cumules += info["duree"]
        if jours_ecoules <= jours_cumules:
            stade_actuel = nom
            break

    cycle_jours = culture_data["cycle_jours"]
    progression = min(100, round((jours_ecoules / cycle_jours) * 100, 1))
    days_remaining = max(0, cycle_jours - jours_ecoules)

    return {"stade": stade_actuel, "jours_ecoules": jours_ecoules, "progression": progression, "days_remaining": days_remaining}

def predire_stade_suivant(culture_data, current_stade_name):
    stades_list = list(culture_data["stades"].keys())
    try:
        idx = stades_list.index(current_stade_name)
        if idx + 1 < len(stades_list):
            next_name = stades_list[idx + 1]
            d = culture_data["stades"][next_name]
            return {"name": next_name, "days_estimes": d["duree"], "N": d.get("N",0), "P": d.get("P",0), "K": d.get("K",0)}
    except ValueError: pass
    return {}

def get_fertilizer_recommendations(manques):
    recs = []
    for nut in ["N", "P", "K", "Ca", "Mg", "S"]:
        deficit = manques.get(nut, {}).get("manque", 0)
        if deficit <= 0.1: continue
        
        for fkey, fdata in FERTILIZER_DATABASE.items():
            pct = fdata["composition"].get(nut, 0)
            if pct > 0:
                kg_ha = round((deficit / pct) * 100, 1)
                if kg_ha > 0.5:
                    # تجنب التكرار إذا كان السماد مضافاً مسبقاً
                    already = next((r for r in recs if r["name"] == fdata["name"]), None)
                    if already:
                        already["kgHa"] += kg_ha
                    else:
                        recs.append({
                            "name": fdata["name"], "icon": fdata["icon"], "kgHa": kg_ha,
                            "how": fdata["how"], "when": fdata["when"], "composition": fdata["composition"]
                        })
                    manques[nut]["manque"] = 0
                    break
    return recs

def calculer_engrais_intelligent(wilaya_name, crop_name, planting_date_str, weather_data):
    soil_type_fr = WILAYA_SOIL_MAPPING.get(wilaya_name, "Sols bruns calcaires")
    soil_data = SOL_NUTRIENTS_COMPLET.get(soil_type_fr, SOL_NUTRIENTS_COMPLET["Sols bruns calcaires"])
    crop_data = CROPS_DATABASE.get(crop_name)
    if not crop_data: return {"error": f"Crop '{crop_name}' non trouvé."}

    stage_info = calculer_stade(planting_date_str, crop_data)
    if not stage_info: return {"error": "Date de plantation invalide."}

    stade_data = crop_data["stades"].get(stage_info["stade"], {})
    if not stade_data: return {"error": "Stade non trouvé."}

    nutriments = ["N", "P", "K", "Ca", "Mg", "S"]
    resultats = {}
    total_kg_ha = 0.0

    for nut in nutriments:
        besoin = stade_data.get(nut, 0)
        disponible = soil_data.get(nut, 0)
        manque = max(0, besoin - disponible)
        effic = soil_data["efficacite"]
        requis = manque / effic if manque > 0 else 0

        resultats[nut] = {
            "need": besoin, "available": disponible, "deficit": round(manque, 1),
            "required": round(requis, 1), "ok": disponible >= besoin
        }
        total_kg_ha += requis

    # تعديل حسب الطقس
    if weather_data:
        temp = weather_data.get("temperature", 22)
        pluie = weather_data.get("precipitation", 0)
        if temp > 35: total_kg_ha *= 1.12
        elif temp > 30: total_kg_ha *= 1.06
        if pluie > 25: total_kg_ha *= 1.15
        elif pluie > 10: total_kg_ha *= 1.08

    analyse_exces = detecter_exces_et_desequilibres(soil_data, {n: resultats[n]["required"] for n in nutriments})
    next_stade = predire_stade_suivant(crop_data, stage_info["stade"])

    # توصيات الري
    irr_base = crop_data.get("irrigation", {}).get(stage_info["stade"], 4)
    if weather_data and weather_data.get("temperature", 20) > 30: irr_base *= 1.3

    # تنبيهات الطقس
    alerts, warnings, tips = [], [], []
    if weather_data:
        temp = weather_data.get("temperature", 20)
        pluie = weather_data.get("precipitation", 0)
        t_opt = crop_data.get("temperature_optimale", [15, 30])
        t_crit = crop_data.get("temperature_critique", [5, 40])

        if temp > t_crit[1]:
            alerts.append(f"🔴 CRITIQUE : {temp}°C > {t_crit[1]}°C - Risque إجهاد حراري!")
            tips.append({"title": "تخفيف الإجهاد الحراري", "description": "توفير الظل أو زيادة الري في أوقات الذروة."})
        elif temp > t_opt[1]:
            warnings.append(f"🟡 حار : {temp}°C > المثلى. زيادة الري 30%.")
        if temp < t_crit[0]:
            alerts.append(f"🔴 خطر الصقيع : {temp}°C - حماية المحصول ضرورية!")
        if pluie > 25:
            warnings.append(f"⚠️ أمطار غزيرة ({pluie} مم) - قسم دفعات السماد.")

    alerts.extend(analyse_exces["alertes"])
    warnings.extend(analyse_exces["avertissements"])
    for c in analyse_exces["conseils"]:
        tips.append({"title": "نصيحة تصحيحية", "description": c})

    return {
        "wilaya": wilaya_name,
        "area": 1.0,
        "crop": crop_name,
        "plantDate": planting_date_str,
        "date": datetime.now().strftime('%Y-%m-%d'),
        "totalKgHa": round(total_kg_ha, 1),
        "stageProgress": stage_info["progression"],
        "stageName": stage_info["stade"],
        "daysElapsed": stage_info["jours_ecoules"],
        "totalDays": crop_data["cycle_jours"],
        "daysRemaining": stage_info["days_remaining"],
        "nextStage": next_stade,
        "soilType": wilaya_name,
        "soilData": {"texture": "", "phMin": soil_data["ph"], "phMax": soil_data["ph"], "irrigation": "", "fertilisation": soil_data["description"]},
        "soilNutrients": {"efficacite": soil_data["efficacite"], "moPct": soil_data["mo_pct"], "cec": f"{soil_data['cec']} meq/100g", "available": {n: soil_data.get(n, 0) for n in nutriments}},
        "nutrients": resultats,
        "fertilizers": get_fertilizer_recommendations(resultats),
        "alerts": alerts,
        "warnings": warnings,
        "tips": tips,
        "irrigation": {"amount": round(irr_base, 1), "unit": "mm/jour"}
    }

# ============================================================
# نقطة الدخول (Entry Point)
# ============================================================
def main():
    # قراءة المدخلات (يدعم serious_python عبر ENV أو stdin للاختبار المحلي)
    input_str = os.environ.get("INPUT_DATA") or sys.stdin.read().strip()
    if not input_str:
        print(json.dumps({"error": "No input data provided"}), flush=True)
        return

    try:
        data = json.loads(input_str)
    except json.JSONDecodeError:
        print(json.dumps({"error": "Invalid JSON input"}), flush=True)
        return

    result = calculer_engrais_intelligent(
        wilaya_name=data.get("wilaya"),
        crop_name=data.get("crop"),
        planting_date_str=data.get("plantDate"),
        weather_data=data.get("weatherData", {})
    )
    result["area"] = data.get("area", 1.0)
    
    print(json.dumps(result, ensure_ascii=False), flush=True)

if __name__ == "__main__":
    main()