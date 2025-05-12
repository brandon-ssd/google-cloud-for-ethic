from flask import Flask
import requests
import os

app = Flask(__name__)
API_KEY = os.getenv("API_KEY", "###API KEY DELETED###")
CITY = "New York"

@app.route('/')
def get_weather():
    url = f"http://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    weather_data = response.json()
    return f"Weather in {CITY}: {weather_data['weather'][0]['description']}, Temp: {weather_data['main']['temp']}°C"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
