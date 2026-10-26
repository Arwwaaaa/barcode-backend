from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv

load_dotenv()
import requests
import google.generativeai as genai
import json
import os

app = FastAPI(title="Rivo - AI Food Allergy & Barcode Scanner API")

app.add_middleware(
CORSMiddleware,
allow_origins=["*"],
allow_credentials=True,
allow_headers=["*"],
)

# إعداد مفتاح الذكاء الاصطناعي
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

class ProductRequest(BaseModel):
    barcode: str
    allergens: Optional[List[str]] = []

@app.get("/")
def home():
    return {"message": "Welcome to Rivo Backend with AI!"}

@app.post("/check-product")
def check_product_from_app(request: ProductRequest):
    url = f"https://world.openfoodfacts.org/api/v0/product/{request.barcode}.json"
    headers = {"User-Agent": "RivoApp - StudentProject - Version 1.0"}

    try:
        response = requests.get(url, headers=headers, timeout=10)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Connection error: {e}")

    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Failed to connect to Open Food Facts")

    data = response.json()
    
    # فحص ما إذا كان المنتج موجوداً في قاعدة البيانات العالمية أم لا
    is_product_found = (data.get("status") == 1)
    
    product = data.get("product", {}) if is_product_found else {}
    product_name = product.get("product_name_ar") or product.get("product_name") or f"منتج باركود: {request.barcode}"
    
    # استخراج الحقائق الغذائية كاملة (لكل 100g)
    nutriments = product.get("nutriments", {})
    
    calories_val = nutriments.get("energy-kcal_100g") or nutriments.get("energy-kcal")
    proteins_val = nutriments.get("proteins_100g") or nutriments.get("proteins")
    fats_val = nutriments.get("fat_100g") or nutriments.get("fat")
    carbs_val = nutriments.get("carbohydrates_100g") or nutriments.get("carbohydrates")

    raw_ingredients = product.get("ingredients_text_ar") or product.get("ingredients_text") or product.get("ingredients_text_en") or product.get("ingredients_text_de") or ""
    has_real_ingredients = len(raw_ingredients.strip()) > 3

    ingredients_ar = raw_ingredients
    
    product_calories = f"{calories_val} kcal" if calories_val is not None else None
    product_proteins = f"{proteins_val} g" if proteins_val is not None else None
    product_fats = f"{fats_val} g" if fats_val is not None else None
    product_carbs = f"{carbs_val} g" if carbs_val is not None else None

    # إذا كان المنتج موجوداً ومكوناته حقيقية، نقوم بترجمتها بالعربية
    if is_product_found and has_real_ingredients:
        prompt = f"""
You are a food translation expert. Translate this exact ingredients list into fluent Modern Standard Arabic (اللغة العربية الفصحى):
"{raw_ingredients}"

Return ONLY a JSON object with this exact structure, no extra text:
{{
  "ingredients_translated": "المكونات مترجمة بالكامل بالعربية هنا"
}}
"""
        try:
            model = genai.GenerativeModel('gemini-1.5-flash')
            ai_response = model.generate_content(prompt)
            clean_text = ai_response.text.strip().replace("```json", "").replace("```", "").strip()
            result_json = json.loads(clean_text)
            ingredients_ar = result_json.get("ingredients_translated", raw_ingredients)
        except Exception as e:
            print(f"Translation Error: {e}")
            ingredients_ar = raw_ingredients

    else:
        # خطة بديلة ذكية للمنتجات المحلية أو غير المسجلة
        estimation_prompt = f"""
You are an expert food nutritionist in the GCC / Saudi market. 
The food product with barcode "{request.barcode}" and name "{product_name}" is not registered in Open Food Facts.
1. Estimate realistic commercial ingredients in Arabic.
2. Estimate approximate nutritional values per 100g (Calories, Proteins, Fats, Carbs) typical for this product.

Return ONLY a JSON object with this exact structure:
{{
  "product_name_ar": "اسم المنتج بالعربية أو تصحيحه",
  "ingredients_translated": "المكونات التقديرية بالعربية مفصولة بفواصل",
  "calories": "السعرات التقديرية (مثال: 490 kcal)",
  "proteins": "البروتين التقديري (مثال: 5 g)",
  "fats": "الدهون التقديرية (مثال: 22 g)",
  "carbs": "الكربوهيدرات التقديرية (مثال: 65 g)"
}}
"""
        try:
            model = genai.GenerativeModel('gemini-1.5-flash')
            ai_response = model.generate_content(estimation_prompt)
            clean_text = ai_response.text.strip().replace("```json", "").replace("```", "").strip()
            result_json = json.loads(clean_text)
            product_name = result_json.get("product_name_ar", product_name)
            ingredients_ar = result_json.get("ingredients_translated", "مكونات تقديرية غير متوفرة بدقة")
            product_calories = result_json.get("calories", "غير متوفر")
            product_proteins = result_json.get("proteins", "غير متوفر")
            product_fats = result_json.get("fats", "غير متوفر")
            product_carbs = result_json.get("carbs", "غير متوفر")
        except Exception as e:
            print(f"Estimation AI Error: {e}")
            ingredients_ar = "مكونات قياسية للمنتج المحلي"
            product_calories = product_calories or "غير متوفر"
            product_proteins = product_proteins or "غير متوفر"
            product_fats = product_fats or "غير متوفر"
            product_carbs = product_carbs or "غير متوفر"

    # تنسيق الحقول الغذائية النهائية
    product_calories = product_calories if product_calories is not None else "غير متوفر"
    product_proteins = product_proteins if product_proteins is not None else "غير متوفر"
    product_fats = product_fats if product_fats is not None else "غير متوفر"
    product_carbs = product_carbs if product_carbs is not None else "غير متوفر"

    # فحص الحساسية الذكي والمحلي المضمون (يدعم مطابقة اللغات مثل الألماني/الإنجليزي مع العربي)
    user_allergens_list = [a.strip().lower() for a in request.allergens if a.strip()]
    has_allergy_risk = False
    found_allergens = []

    allergy_synonyms = {
        "بندق": ["hazelnut", "haselnüsse", "haselnuesse", "nuts", "filbert"],
        "حليب": ["milk", "milch", "lactose", "laktose", "butter", "whey", "casein", "magermilchpulver"],
        "صويا": ["soya", "soy", "lecithine (soja)", "lecithin"],
        "جلوتين": ["gluten", "wheat", "barley", "flour", "weizen"]
    }

    combined_text = f"{raw_ingredients} {ingredients_ar} {product_name}".lower()

    for user_allergen in user_allergens_list:
        clean_allergen = user_allergen.lower()
        keywords_to_check = [clean_allergen]
        for key, synonyms in allergy_synonyms.items():
            if key in clean_allergen or clean_allergen in key:
                keywords_to_check.extend(synonyms)
                
        for kw in keywords_to_check:
            if kw in combined_text:
                has_allergy_risk = True
                if user_allergen not in found_allergens:
                    found_allergens.append(user_allergen)
                break

    # صياغة رسالة الحالة النهائية
    if not is_product_found and ingredients_ar == "مكونات تقديرية غير متوفرة بدقة":
    message = "تنبيه: المنتج غير مسجل عالمياً، وتم تقدير بياناته بواسطة الذكاء الاصطناعي، يرجى التحقق من الغلاف."
    elif has_allergy_risk:
        message = f"تحذير خطير! هذا المنتج يحتوي على مواد تحسس منها: {', '.join(found_allergens)}"
    else:
        message = "آمن! لا توجد مواد تحسس منها في هذا المنتج."
        
    return {
 "barcode": request.barcode,
 "product_name": product_name,
"ingredients": ingredients_ar,
"calories": product_calories,
 "proteins": product_proteins,
"fats": product_fats,
 "carbs": product_carbs,
 "has_allergy_risk": has_allergy_risk,
 "found_allergens": found_allergens,
 "message": message
}