// Tablet Firefox profile.
// Touch density, large targets, software rendering, Android-visible downloads.

user_pref("browser.uidensity", 2);
user_pref("browser.tabs.inTitlebar", 0);
user_pref("browser.tabs.tabMinWidth", 160);
user_pref("browser.tabs.tabMaxWidth", 320);
user_pref("browser.toolbars.bookmarks.visibility", "always");
user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);
user_pref("browser.newtabpage.activity-stream.topSitesRows", 2);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.startup.homepage", "about:newtab");
user_pref("browser.startup.page", 1);
user_pref("browser.download.dir", "/data/data/com.termux/files/home/storage/downloads");
user_pref("browser.download.folderList", 2);
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.alwaysOpenPanel", false);
user_pref("widget.non-native-theme.scrollbar.size.override", 28);
user_pref("ui.textScaleFactor", 110);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Software rendering on llvmpipe / Termux:X11.
user_pref("gfx.webrender.software", true);
user_pref("layers.acceleration.disabled", true);
user_pref("media.hardware-video-decoding.enabled", false);
user_pref("toolkit.cosmeticAnimations.enabled", false);
user_pref("browser.tabs.animate", false);
user_pref("browser.fullscreen.animate", false);

// Keep memory under control on a tablet.
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("dom.ipc.processCount", 2);
user_pref("browser.cache.memory.capacity", 65536);
user_pref("network.http.max-connections", 32);
