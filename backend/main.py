from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import requests

app = FastAPI(title="Rivo - Food Allergy & Barcode Scanner API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ProductRequest(BaseModel):
    barcode: str
    allergens: Optional[List[str]] = []

@app.get("/")
def home():
    return {"message": "Welcome to Rivo Backend!"}

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
    
    # التحقق من وجود المنتج
    product = data.get("product")
    is_product_found = product is not None and isinstance(product, dict) and len(product) > 0
    
    product_dict = product if is_product_found else {}
    product_name = product_dict.get("product_name_ar") or product_dict.get("product_name") or f"منتج باركود: {request.barcode}"
    
    # استخراج الحقائق الغذائية (لكل 100g)
    nutriments = product_dict.get("nutriments", {})
    
    calories_val = nutriments.get("energy-kcal_100g") or nutriments.get("energy-kcal")
    proteins_val = nutriments.get("proteins_100g") or nutriments.get("proteins")
    fats_val = nutriments.get("fat_100g") or nutriments.get("fat")
    carbs_val = nutriments.get("carbohydrates_100g") or nutriments.get("carbohydrates")

    raw_ingredients = product_dict.get("ingredients_text_ar") or product_dict.get("ingredients_text") or product_dict.get("ingredients_text_en") or ""
    ingredients_ar = raw_ingredients if raw_ingredients else "المكونات غير متوفرة"
    
    # تنسيق القيم الغذائية وتجنب الأرقام الطويلة
    product_calories = f"{round(float(calories_val))}" if calories_val is not None else "غير متوفر"
    product_proteins = f"{round(float(proteins_val), 1)} g" if proteins_val is not None else "غير متوفر"
    product_fats = f"{round(float(fats_val), 1)} g" if fats_val is not None else "غير متوفر"
    product_carbs = f"{round(float(carbs_val), 1)} g" if carbs_val is not None else "غير متوفر"

    if not is_product_found:
        product_name = f"منتج غير مسجل: {request.barcode}"
        ingredients_ar = "غير موثّق في قاعدة البيانات – راجع الملصق الغذائي"

    # فحص الحساسية الذكي والمحلي
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
    if not is_product_found:
        message = "غير موثّق بعد – راجع الملصق"
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