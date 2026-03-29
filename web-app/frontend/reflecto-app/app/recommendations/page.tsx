import { getMockWeather } from "@/lib/mock-services";
import { RecommendationsClient } from "./RecommendationsClient";

export default async function RecommendationsPage() {
  const weather = await getMockWeather();
  
  // Format current date: "Monday, March 29"
  const now = new Date();
  const dateStr = new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  }).format(now);

  return (
    <RecommendationsClient 
      weather={{ temp: weather.temp, condition: weather.condition }} 
      date={dateStr} 
    />
  );
}
