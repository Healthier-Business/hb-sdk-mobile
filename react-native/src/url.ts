/**
 * The origin of the page, or an error when the page is not safe to open: it has to be https, except `http` on localhost, 127.0.0.1 or [::1]
 * (the sandbox accepts those on any port). The same rule as the registered origins in Hub.
 */
export function pageOrigin(pageUrl: string): string {
  let url: URL;
  try {
    url = new URL(pageUrl);
  } catch {
    throw new Error(`HbEmbed: "${pageUrl}" is not a web address.`);
  }
  const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
  if (url.protocol !== 'https:' && !(url.protocol === 'http:' && local)) {
    throw new Error('HbEmbed: the page must be https (http is allowed only on localhost).');
  }
  return url.origin;
}

/** Whether `candidate` is on the same origin as the page. */
export function sameOrigin(candidate: string, origin: string): boolean {
  try {
    return new URL(candidate).origin === origin;
  } catch {
    return false;
  }
}
