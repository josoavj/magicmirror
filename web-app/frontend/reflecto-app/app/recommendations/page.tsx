import { getMockWeather } from "@/lib/mock-services";
import { RecommendationsClient } from "./RecommendationsClient";

interface PageProps {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function RecommendationsPage(props: PageProps) {
  const searchParams = await props.searchParams;
  const eventContext = typeof searchParams.eventContext === 'string' ? searchParams.eventContext : undefined;

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
      eventContext={eventContext}
    />
  );
}
