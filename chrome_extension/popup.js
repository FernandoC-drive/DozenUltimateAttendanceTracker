const appUrlInput = document.getElementById("appUrl");
const tokenInput = document.getElementById("token");
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

saveButton.addEventListener("click", saveSettings);
syncButton.addEventListener("click", syncCurrentTab);
loadSettings();
