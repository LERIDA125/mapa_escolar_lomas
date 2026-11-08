import hashlib
import json
import re
import time

import requests

PARTIDO_QUERY = "Lomas de Zamora, Buenos Aires, Argentina"


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
        "BO. EL FARO": "Barrio El Faro",
        "V. CENTENARIO": "Villa Centenario",
        "ING. BUDGE": "Ingeniero Budge",
        "V. URBANA": "Villa Urbana",
        "STA. MARTA": "Santa Marta",
        "V. LAMADRID": "Villa Lamadrid",
        "V. INDEP": "Villa Independencia",
        "V. FIORITO": "Villa Fiorito",
        "BANFIELD O": "Banfield",
        "BANFIELD E": "Banfield",
        "BANFIELD OESTE": "Banfield",
        "BANFIELD ESTE": "Banfield",
        "TEMPERLEY O": "Temperley",
        "TEMPERLEY E": "Temperley",
        "TEMPERLEY OESTE": "Temperley",
        "TEMPERLEY ESTE": "Temperley",
        "LAVALLOL": "Llavallol",
        "S. JOSE": "Barrio San José",
        "SAN JOSE": "Barrio San José",
        "CTEL IX": "Lomas de Zamora", # Nominatim no mapea Cuartel IX, hacemos fallback al partido
        "CTEL. IX": "Lomas de Zamora",
        "BO EL FARO": "Barrio El Faro",
        "BO. LA LOMA": "La Loma",
        "BO. 2 DE ABRIL": "Barrio 2 de Abril",
        "JUAN M. DE ROS": "Barrio Juan Manuel de Rosas",
        "JUAN M. DE ROSA": "Barrio Juan Manuel de Rosas",
        "V URBANA": "Villa Urbana",
        "SIN ESPECIFICAR": "Lomas de Zamora"
    }
    for key, val in mapping.items():
        if key in loc:
            return val
    return locality.title()


def get_deterministic_offset(seed_string):
    """Devuelve un offset reproducible de hasta +-0.005 grados.

    Se usa para separar los pines del fallback por localidad y evitar que
    todas las escuelas de un mismo barrio queden apiladas en un punto.
    """
    digest = hashlib.md5(str(seed_string).encode("utf-8")).hexdigest()
    lat_ratio = int(digest[:8], 16) / 0xFFFFFFFF
    lon_ratio = int(digest[8:16], 16) / 0xFFFFFFFF
    lat_offset = (lat_ratio * 0.01) - 0.005
    lon_offset = (lon_ratio * 0.01) - 0.005
    return lat_offset, lon_offset


def search_nominatim(query):
    url = "https://nominatim.openstreetmap.org/search"
    params = {'q': query, 'format': 'json', 'limit': 1}
    headers = {'User-Agent': 'MapaEscolarLomas/1.2 (fernando.rucci@test.com)'}

    try:
        response = requests.get(url, params=params, headers=headers, timeout=30)
        if response.status_code == 200:
            data = response.json()
            if data:
                return float(data[0]['lat']), float(data[0]['lon'])
    except Exception:
        pass

    return None, None


def build_exact_query(clean_address, clean_loc):
    if clean_loc.lower() == "lomas de zamora":
        return f"{clean_address}, Lomas de Zamora, Buenos Aires, Argentina"
    return f"{clean_address}, {clean_loc}, Lomas de Zamora, Buenos Aires, Argentina"


def build_locality_query(clean_loc):
    if clean_loc.lower() == "lomas de zamora":
        return "Lomas de Zamora, Buenos Aires, Argentina"
    return f"{clean_loc}, Lomas de Zamora, Buenos Aires, Argentina"


def geocode_address(address, locality, school_name):
    clean_address = clean_address_string(address)
    clean_loc = normalize_locality(locality)

    # Intento 1: dirección exacta (calle + altura)
    lat, lon = search_nominatim(build_exact_query(clean_address, clean_loc))
    if lat is not None:
        return lat, lon, "EXACTO"

    # Intento 2: centroide de la localidad + offset determinístico
    lat, lon = search_nominatim(build_locality_query(clean_loc))
    if lat is not None:
        lat_offset, lon_offset = get_deterministic_offset(school_name)
        return lat + lat_offset, lon + lon_offset, "FALLBACK BARRIO"

    # Intento 3: centroide del partido + offset (garantiza cobertura total)
    lat, lon = search_nominatim(PARTIDO_QUERY)
    if lat is not None:
        lat_offset, lon_offset = get_deterministic_offset(school_name)
        return lat + lat_offset, lon + lon_offset, "FALLBACK PARTIDO"

    return None, None, "FALLO TOTAL"


def update_seed():
    filename = 'assets/escuelas_seed.json'
    with open(filename, 'r', encoding='utf-8') as f:
        schools = json.load(f)

    total = len(schools)
    print(f"Iniciando geocodificación de {total} escuelas...")
    ya_geocodificadas = 0
    exactos = 0
    fallbacks = 0
    fallbacks_partido = 0
    fallidos = 0

    for idx, school in enumerate(schools):
        # Si ya tiene coordenadas distintas a las default, saltamos (corrida reanudable)
        if school['latitude'] != -34.7628 or school['longitude'] != -58.4022:
            ya_geocodificadas += 1
            continue

        print(f"[{idx+1}/{total}] Buscando: {school['address']}, {school['locality']['name']}...")
        lat, lon, modo = geocode_address(
            school['address'], school['locality']['name'], school['name']
        )

        if modo == "EXACTO":
            school['latitude'] = lat
            school['longitude'] = lon
            exactos += 1
            print(f"    -> EXACTO: {lat}, {lon}")
        elif modo == "FALLBACK BARRIO":
            school['latitude'] = lat
            school['longitude'] = lon
            fallbacks += 1
            print(f"    -> FALLBACK BARRIO: {lat}, {lon}")
        elif modo == "FALLBACK PARTIDO":
            school['latitude'] = lat
            school['longitude'] = lon
            fallbacks_partido += 1
            print(f"    -> FALLBACK PARTIDO: {lat}, {lon}")
        else:
            fallidos += 1
            print("    -> FALLO TOTAL")

        # Nominatim exige máximo 1 petición por segundo según su política de uso gratuito
        time.sleep(1.5)

    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(schools, f, ensure_ascii=False, indent=2)

    print("\n--- FIN ---")
    print(f"Total: {total} | Ya geocodificadas: {ya_geocodificadas}")
    print(f"Exactos: {exactos} | Fallback barrio: {fallbacks} | Fallback partido: {fallbacks_partido} | Fallos totales: {fallidos}")
    print(f"Exitosos: {exactos + fallbacks + fallbacks_partido} | Fallidos: {fallidos}")


if __name__ == "__main__":
    update_seed()
