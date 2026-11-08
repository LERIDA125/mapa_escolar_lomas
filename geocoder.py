import json
import time
import requests
import re

def clean_address_string(address):
    # Elimina intersecciones para buscar solo la calle principal, ignorando mayúsculas/minúsculas
    clean = re.split(r'(?i)\s+y\s+', address)[0]
    clean = re.split(r'(?i)\s+e/', clean)[0]
    return clean.strip()

def normalize_locality(locality):
    loc = locality.upper()
    mapping = {
        "LOMAS DE Z": "Lomas de Zamora",
        "V. ALBERTINA": "Villa Albertina",
        "CTEL IX": "Cuartel IX",
        "BO. EL FARO": "Barrio El Faro",
        "V. CENTENARIO": "Villa Centenario",
        "ING. BUDGE": "Ingeniero Budge"
    }
    for key, val in mapping.items():
        if key in loc:
            return val
    return locality.title()

def geocode_address(address, locality):
    clean_address = clean_address_string(address)
    clean_loc = normalize_locality(locality)
    
    if clean_loc.lower() == "lomas de zamora":
        query = f"{clean_address}, Lomas de Zamora, Buenos Aires, Argentina"
    else:
        query = f"{clean_address}, {clean_loc}, Lomas de Zamora, Buenos Aires, Argentina"
        
    url = "https://nominatim.openstreetmap.org/search"
    params = {'q': query, 'format': 'json', 'limit': 1}
    headers = {'User-Agent': 'MapaEscolarLomas/1.1 (fernando.rucci@test.com)'}
    
    try:
        response = requests.get(url, params=params, headers=headers)
        if response.status_code == 200:
            data = response.json()
            if data:
                return float(data[0]['lat']), float(data[0]['lon'])
    except Exception as e:
        pass
        
    return None, None

def update_seed():
    filename = 'assets/escuelas_seed.json'
    with open(filename, 'r', encoding='utf-8') as f:
        schools = json.load(f)

    total = len(schools)
    print(f"Iniciando geocodificación de {total} escuelas...")
    exitosos = 0
    fallidos = 0

    for idx, school in enumerate(schools):
        if school['latitude'] != -34.7628 or school['longitude'] != -58.4022:
            exitosos += 1
            continue
            
        print(f"[{idx+1}/{total}] Buscando: {school['address']}, {school['locality']['name']}...")
        lat, lon = geocode_address(school['address'], school['locality']['name'])
        
        if lat and lon:
            school['latitude'] = lat
            school['longitude'] = lon
            exitosos += 1
            print(f"    -> OK: {lat}, {lon}")
        else:
            fallidos += 1
            print("    -> FALLO")

        time.sleep(1.5)

    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(schools, f, ensure_ascii=False, indent=2)

    print(f"\n--- FIN --- \nExitosos: {exitosos} | Fallidos: {fallidos}")

if __name__ == "__main__":
    update_seed()
