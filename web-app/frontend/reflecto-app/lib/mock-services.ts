// Real Weather Service (using OpenWeatherMap)
export const getMockWeather = async () => {
  const apiKey = process.env.NEXT_PUBLIC_OPENWEATHER_API_KEY;
  const city = "Antananarivo"; // Default city
  
  try {
    if (!apiKey) {
      throw new Error("API Key missing");
    }

    console.log("Get Weather data...");
    const response = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${city}&units=metric&appid=${apiKey}`,
      { cache: "no-store" }
    );
    const data = await response.json();

    if (data.cod !== 200) throw new Error(data.message);

    const temp = Math.round(data.main.temp);
    const condition = data.weather[0].main;
    
    console.log(`Weather Data : OK (${temp}°C, ${condition})`);
    
    // Logic for outfit advice based on temperature
    let advice = "Perfect weather for a light blazer.";
    if (temp < 10) {
      advice = "It's cold outside. Better bringing a Coat.";
    } else if (temp > 25) {
      advice = "It's quite warm. Stay cool with light clothing.";
    }

    return {
      temp,
      condition,
      location: data.name,
      icon: data.weather[0].icon,
      advice
    };
  } catch (error) {
    console.warn("Weather API failed, using mock data", error);
    return {
      temp: 22,
      condition: "Sunny",
      location: "Antananarivo",
      icon: "01d",
      advice: "Perfect weather for a light blazer."
    };
  }
};

// Mock Calendar Service
export const getMockAgenda = async () => {
  return [
    { id: 1, time: "09:00", title: "Meeting with Design Team", category: "Work" },
    { id: 2, time: "13:00", title: "Lunch with Sarah", category: "Social" },
    { id: 3, time: "19:00", title: "Evening Gala", category: "Event" }
  ];
};

// Mock Outfit Analysis
export const analyzeOutfit = async (image: string) => {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 2000));
  return {
    morphology: "H-Shape",
    silhouette: "Balanced",
    skinTone: "Warm",
    confidence: 0.95
  };
};

// Mock LLM Response
export const getAIResponse = async (message: string) => {
  return "I suggest wearing your Gold-accented Navy suit for today's Gala. It matches the evening's luxury theme and fits perfectly with the weather.";
};
