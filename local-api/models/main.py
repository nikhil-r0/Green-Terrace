import json
from mrkt_price import get_market_prices
from plant_optimization import recomend_crops

if __name__ == "__main__":
    lat=int(input("Enter the latitude"))
    longitude=int(input("Enter the longitude"))
    data = recomend_crops(100, lat, longitude, 0.2, 0.8, 2000, ['Vegetables', 'Fruits','Medicinal'])
    print(json.dumps(data, indent=2))
    labels = [plant["label"] for plant in data["recommended_crops"]]
    print(labels)
    market_prices=get_market_prices(['Papaya','Fig','Guava','Passion Fruit'])
    print(market_prices)
