/** One event the page passes to the app. `data` is what the frame sent, as plain JSON. */
export type HbEvent = {
  name: HbEventName;
  data: Record<string, unknown>;
};

/** The events the page of the examples sends. A page may send others; they arrive with their own name. */
export type HbEventName =
  | 'ready'
  | 'progress'
  | 'completed'
  | 'passed'
  | 'failed'
  | 'submitted'
  | 'terms-accepted'
  | 'error'
  | (string & {});

/** The events that finish a session. Read the result from your server before you grant anything. */
export const FINAL_EVENTS: readonly string[] = ['completed', 'passed', 'failed', 'submitted'];

/**
 * Reads the text the page sent. Returns null for anything that is not `{"name": "...", "data": {...}}`, so a stray message is ignored
 * and never reaches your app.
 */
export function parseHbEvent(text: unknown): HbEvent | null {
  if (typeof text !== 'string' || text.length > 20000) {
    return null;
  }
  try {
    const value: unknown = JSON.parse(text);
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      return null;
    }
    const { name, data } = value as { name?: unknown; data?: unknown };
    if (typeof name !== 'string' || name.length === 0 || name.length > 64) {
      return null;
    }
    const plain = typeof data === 'object' && data !== null && !Array.isArray(data) ? (data as Record<string, unknown>) : {};
    return { name, data: plain };
  } catch {
    return null;
  }
}
