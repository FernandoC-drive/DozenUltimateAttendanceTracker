function normalizeText(value) {
  return (value || "").replace(/\u00a0/g, " ").replace(/\s+/g, " ").trim();
}

function absoluteUrl(rawUrl, baseUrl) {
  try {
    return new URL(rawUrl, baseUrl).toString();
  } catch (_error) {
    return rawUrl;
  }
}

function labeledValue(text, label, terminators = []) {
  const escapedTerminators = terminators.map((value) => `${value}:`.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  const boundary = escapedTerminators.length > 0 ? `(?=${escapedTerminators.join("|")}|$)` : "$";
  const pattern = new RegExp(`${label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}:\\s*(.*?)\\s*${boundary}`, "i");
  const match = text.match(pattern);
  return match ? normalizeText(match[1]) : null;
}

function parseTime(value) {
  const normalized = normalizeText(value);
  if (!normalized) {
    return null;
  }

  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    return normalized;
  }

  const year = parsed.getFullYear();
  const month = String(parsed.getMonth() + 1).padStart(2, "0");
  const day = String(parsed.getDate()).padStart(2, "0");
  const hours = String(parsed.getHours()).padStart(2, "0");
  const minutes = String(parsed.getMinutes()).padStart(2, "0");
  return `${year}-${month}-${day} ${hours}:${minutes}`;
}

function parseDatetimeRange(value) {
  if (!value) {
    return [null, null];
  }

  const parts = normalizeText(value).split(/\s+to\s+/i);
  const startsAt = parseTime(parts[0]);
  if (parts.length < 2) {
    return [startsAt, null];
  }

  const endsAt = parseTime(parts[1]);
  if (endsAt || !startsAt) {
    return [startsAt, endsAt];
  }

  const startDate = startsAt.slice(0, 10);
  return [startsAt, parseTime(`${startDate} ${parts[1]}`)];
}

function parseCreatedBy(value) {
  if (!value) {
    return [null, null];
  }

  const emailMatch = value.match(/\(([^)]+)\)/);
  const email = emailMatch ? normalizeText(emailMatch[1]) : null;
  const name = normalizeText(value.replace(/\s*\([^)]+\)\s*/, ""));
  return [name || null, email || null];
}

function extractExternalId(url) {
  try {
    const parsed = new URL(url);
    return parsed.searchParams.get("id") || parsed.searchParams.get("eventId") || parsed.pathname.split("/").pop();
  } catch (_error) {
    return null;
  }
}

function participantsTable(doc) {
  return Array.from(doc.querySelectorAll("table")).find((table) => {
    const headers = Array.from(table.querySelectorAll("thead th")).map((header) => normalizeText(header.textContent).toLowerCase());
    return headers.includes("first name") && headers.includes("last name");
  });
}

function parseParticipants(table) {
  const headers = Array.from(table.querySelectorAll("thead th")).map((header) => normalizeText(header.textContent).toLowerCase());
  const firstNameIndex = headers.indexOf("first name");
  const lastNameIndex = headers.indexOf("last name");
  const uinIndex = headers.indexOf("uin");

  return Array.from(table.querySelectorAll("tbody tr"))
    .map((row, position) => {
      const cells = Array.from(row.querySelectorAll("td")).map((cell) => normalizeText(cell.textContent));
      if (cells.length === 0) {
        return null;
      }

      const firstName = cells[firstNameIndex >= 0 ? firstNameIndex : 0] || null;
      const lastName = cells[lastNameIndex >= 0 ? lastNameIndex : 1] || null;
      const uin = cells[uinIndex >= 0 ? uinIndex : 2] || null;
      if (!firstName && !lastName && !uin) {
        return null;
      }

      return {
        first_name: firstName,
        last_name: lastName,
        uin,
        position
      };
    })
    .filter(Boolean);
}

function parseEventPage(html, sourceUrl) {
  const doc = new DOMParser().parseFromString(html, "text/html");
  const table = participantsTable(doc);
  if (!table) {
    return null;
  }

  const pageText = normalizeText(doc.body?.innerText || doc.documentElement?.textContent || "");
  const [startsAt, endsAt] = parseDatetimeRange(labeledValue(pageText, "Event Date/Time", ["Created By", "Created At", "Participants"]));
  const createdByValue = labeledValue(pageText, "Created By", ["Created At", "Participants"]);
  const [createdByName, createdByEmail] = parseCreatedBy(createdByValue);

  return {
    title: labeledValue(pageText, "Event Name", ["Event Type", "Event Venue", "Event Date/Time"]) || normalizeText(doc.querySelector("h1, h2, h3")?.textContent),
    event_type: labeledValue(pageText, "Event Type", ["Event Venue", "Event Date/Time", "Created By"]),
    venue: labeledValue(pageText, "Event Venue", ["Event Date/Time", "Created By", "Created At"]),
    starts_at: startsAt,
    ends_at: endsAt,
    source_url: sourceUrl,
    external_id: extractExternalId(sourceUrl),
    created_by_name: createdByName,
    created_by_email: createdByEmail,
    source_created_at: labeledValue(pageText, "Created At", ["Participants"]),
    participants: parseParticipants(table)
  };
}

function extractEventUrls(doc, baseUrl) {
  return Array.from(doc.querySelectorAll("a"))
    .filter((link) => normalizeText(link.textContent).toLowerCase() === "view")
    .map((link) => absoluteUrl(link.getAttribute("href"), baseUrl))
    .filter(Boolean);
}

async function fetchHtml(url) {
  let response;

  try {
    response = await fetch(url, {
      credentials: "include"
    });
  } catch (error) {
    throw new Error(
      `Could not fetch Sport Clubs page ${url}. Make sure you are still signed in to TAMU Sport Clubs in this Chrome window and try again.`
    );
  }

  if (!response.ok) {
    throw new Error(`Failed to fetch ${url} (HTTP ${response.status})`);
  }

  return response.text();
}

function reportProgress(message) {
  chrome.runtime.sendMessage({
    type: "RECSPORTS_PROGRESS",
    message
  });
}

async function scrapeCurrentPage() {
  const currentDoc = document;
  const eventUrls = extractEventUrls(currentDoc, window.location.href);
  if (eventUrls.length === 0) {
    throw new Error("No View links were found on the current page. Open the authenticated Home Events page first.");
  }

  reportProgress(`Found ${eventUrls.length} event link(s). Starting scrape...`);
  const events = [];
  for (const [index, eventUrl] of eventUrls.entries()) {
    reportProgress(`Scraping event ${index + 1} of ${eventUrls.length}...`);
    const html = await fetchHtml(eventUrl);
    const parsed = parseEventPage(html, eventUrl);
    if (parsed) {
      events.push(parsed);
    }
  }

  if (events.length === 0) {
    throw new Error("No participant tables were found across the discovered event pages.");
  }

  reportProgress(`Uploading ${events.length} scraped event(s) to the attendance app...`);
  return { events };
}

async function uploadSnapshot(appUrl, token, snapshot) {
  const uploadUrl = `${appUrl}/admin/recsports/browser_sync`;
  let response;

  try {
    response = await fetch(uploadUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        token,
        snapshot
      })
    });
  } catch (_error) {
    throw new Error(
      `Could not reach ${uploadUrl}. Confirm the attendance app URL is correct, the Heroku app is awake, and the extension has permission to access that site.`
    );
  }

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body.error || `Upload failed (HTTP ${response.status})`);
  }

  return body;
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type !== "RECSPORTS_SYNC") {
    return false;
  }

  (async () => {
    const snapshot = await scrapeCurrentPage();
    const response = await uploadSnapshot(message.appUrl, message.token, snapshot);
    sendResponse({
      ok: true,
      message: `Imported ${response.imported_events} event(s) successfully.`
    });
  })().catch((error) => {
    sendResponse({
      ok: false,
      message: error.message
    });
  });

  return true;
});
