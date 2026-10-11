import requests

def buscar_productos_ml(busqueda, limite=5):
    # Endpoint de búsqueda para Mercado Libre Colombia (MCO)
    url = "https://api.mercadolibre.com/sites/MCO/search"
    
    # Parámetros de la consulta
    parametros = {
        "q": busqueda,
        "limit": limite
    }
    
    # Realizar la petición GET
    respuesta = requests.get(url, params=parametros)
    
    # Convertir la respuesta a JSON
    if respuesta.status_code == 200:
        datos = respuesta.json()
        resultados = datos.get("results", [])
        
        for item in resultados:
            titulo = item.get("title")
            precio = item.get("price")
            enlace = item.get("permalink")
            print(f"Producto: {titulo}\nPrecio: ${precio} COP\nLink: {enlace}\n{'-'*40}")
    else:
        print(f"Error en la consulta: {respuesta.status_code}")

# Ejecutar la búsqueda
buscar_productos_ml("accesorios de acero para moto")
