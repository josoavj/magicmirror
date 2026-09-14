import { createClient } from "@/lib/supabase/client";

export interface CalendarEvent {
  id: string;
  user_id: string;
  title: string;
  type: string;
  start_time: string;
  end_time: string | null;
}

export type NewCalendarEvent = Omit<CalendarEvent, "id" | "user_id">;

const EVENT_TYPES = ["Work", "Social", "Event", "Personal", "Sport"] as const;
export { EVENT_TYPES };

export async function getUserEvents(userId: string, date?: Date): Promise<CalendarEvent[]> {
  const supabase = createClient();

  const targetDate = date || new Date();
  const dayStart = new Date(targetDate);
  dayStart.setHours(0, 0, 0, 0);
  const dayEnd = new Date(targetDate);
  dayEnd.setHours(23, 59, 59, 999);

  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("user_id", userId)
    .gte("start_time", dayStart.toISOString())
    .lte("start_time", dayEnd.toISOString())
    .order("start_time", { ascending: true });

  if (error) {
    console.error("Error fetching events:", error);
    return [];
  }

  return data || [];
}

export async function createEvent(
  userId: string,
  event: NewCalendarEvent
): Promise<CalendarEvent | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from("events")
    .insert([{ ...event, user_id: userId }])
    .select()
    .single();

  if (error) {
    console.error("Error creating event:", error);
    return null;
  }

  return data;
}

export async function deleteEvent(eventId: string): Promise<boolean> {
  const supabase = createClient();

  const { error } = await supabase.from("events").delete().eq("id", eventId);

  if (error) {
    console.error("Error deleting event:", error);
    return false;
  }

  return true;
}

export async function updateEvent(
  eventId: string,
  updates: Partial<NewCalendarEvent>
): Promise<CalendarEvent | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from("events")
    .update(updates)
    .eq("id", eventId)
    .select()
    .single();

  if (error) {
    console.error("Error updating event:", error);
    return null;
  }

  return data;
}

export function formatEventTime(isoString: string): string {
  return new Date(isoString).toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}
