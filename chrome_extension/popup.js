const appUrlInput = document.getElementById("appUrl");
const tokenInput = document.getElementById("token");
const detectButton = document.getElementById("detectButton");
const saveButton = document.getElementById("saveButton");
const syncButton = document.getElementById("syncButton");
const statusEl = document.getElementById("status");

async function loadSettings() {
  const stored = await chrome.storage.local.get(["appUrl", "token"]);
  appUrlInput.value = stored.appUrl || "http://localhost:3000";
  tokenInput.value = stored.token || "";
}

async function saveSettings() {
  const appUrl = appUrlInput.value.trim().replace(/\/+$/, "");
  const token = tokenInput.value.trim();

  await chrome.storage.local.set({ appUrl, token });
  statusEl.textContent = "Settings saved.";
}

async function detectFromAttendanceTab() {
  statusEl.textContent = "Looking for an open RecSports Sync page...";
  const tabs = await chrome.tabs.query({});
  const appTab = tabs.find((tab) => {
    if (!tab.url) {
      return false;
    }

    try {
      const url = new URL(tab.url);
      return /\/admin\/recsports$/.test(url.pathname);
    } catch (_error) {
      return false;
    }
  });

  if (!appTab || !appTab.id || !appTab.url) {
    statusEl.textContent = "Open the attendance app's RecSports Sync page in a tab first.";
    return;
  }

  const [{ result }] = await chrome.scripting.executeScript({
    target: { tabId: appTab.id },
    func: () => {
      const pageText = document.body?.innerText || "";
      const tokenMatch = pageText.match(/Browser Sync Token:\s*([a-f0-9]{24,})/i);
      const url = window.location.origin;
      return {
        appUrl: url,
        token: tokenMatch ? tokenMatch[1] : ""
      };
    }
  });

  appUrlInput.value = result?.appUrl || appUrlInput.value;
  tokenInput.value = result?.token || tokenInput.value;
  await saveSettings();
  statusEl.textContent = result?.token
    ? "Detected app URL and browser sync token from the open RecSports Sync page."
    : "Detected app URL, but could not find the token text on that page.";
}

async function syncCurrentTab() {
  const appUrl = appUrlInput.value.trim().replace(/\/+$/, "");
  const token = tokenInput.value.trim();

  if (!appUrl || !token) {
    statusEl.textContent = "Enter both the app URL and sync token first.";
    return;
  }

  await chrome.storage.local.set({ appUrl, token });
  statusEl.textContent = "Starting sync...";

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab || !tab.id) {
    statusEl.textContent = "No active tab found.";
    return;
  }

  try {
    const response = await chrome.tabs.sendMessage(tab.id, {
      type: "RECSPORTS_SYNC",
      appUrl,
      token
    });

    statusEl.textContent = response?.message || "Sync completed.";
  } catch (error) {
    statusEl.textContent = `Sync failed: ${error.message}`;
  }
}

chrome.runtime.onMessage.addListener((message) => {
  if (message?.type === "RECSPORTS_PROGRESS") {
    statusEl.textContent = message.message;
  }
});

detectButton.addEventListener("click", detectFromAttendanceTab);
saveButton.addEventListener("click", saveSettings);
syncButton.addEventListener("click", syncCurrentTab);
loadSettings();
