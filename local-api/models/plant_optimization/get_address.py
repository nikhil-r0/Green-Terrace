from geopy.geocoders import Nominatim

def fetch_state(latitude,longitude):
    geolocator = Nominatim(user_agent="green_terrace")
    location = geolocator.reverse(str(latitude) + "," + str(longitude))
    address = location.raw['address']
    return address.get("state", 'Karnataka').capitalize()

if __name__ == '__main__':
    state = fetch_state(28.6139,77.2090)
    print(state)
