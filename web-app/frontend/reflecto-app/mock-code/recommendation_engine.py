# recommendation_engine.py

import pickle
import numpy as np

# Chargement du modèle pré-entraîné
with open("models/outfit_model.pkl", "rb") as file:
    model = pickle.load(file)

# Encodage simple des entrées (exemple)
def encode_input(gender, body_type, weather, event_type):
    gender_map = {"male": 0, "female": 1}
    body_map = {"ectomorph": 0, "mesomorph": 1, "endomorph": 2}
    weather_map = {"cold": 0, "mild": 1, "hot": 2}
    event_map = {"casual": 0, "work": 1, "formal": 2}

    return np.array([[
        gender_map.get(gender, 0),
        body_map.get(body_type, 1),
        weather_map.get(weather, 1),
        event_map.get(event_type, 0)
    ]])

# Fonction principale de recommandation
def recommend_outfit(user_profile):
    features = encode_input(
        user_profile["gender"],
        user_profile["body_type"],
        user_profile["weather"],
        user_profile["event"]
    )

    prediction = model.predict(features)
    
    outfit_labels = {
        0: "Tenue décontractée (t-shirt + jean)",
        1: "Tenue professionnelle (chemise + pantalon)",
        2: "Tenue élégante (costume ou robe formelle)"
    }

    return outfit_labels.get(prediction[0], "Tenue standard")

# Exemple d'utilisation
if __name__ == "__main__":
    user = {
        "gender": "female",
        "body_type": "mesomorph",
        "weather": "mild",
        "event": "work"
    }

    suggestion = recommend_outfit(user)
    print("Suggestion :", suggestion)