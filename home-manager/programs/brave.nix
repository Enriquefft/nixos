{
  pkgs,
  config,
  lib,
  ...
}:

{
  # Native messaging hosts for browser extensions (e.g., Bitwarden)
  programs.brave.nativeMessagingHosts = with pkgs; [
    keepassxc
  ];

  # Configure search engines via activation script
  home.activation.configureBraveSearchEngines = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    BRAVE_PROFILE="$HOME/.config/BraveSoftware/Brave-Browser/Default"
    PREFS_FILE="$BRAVE_PROFILE/Preferences"

    # Only configure if Brave has been run at least once
    if [ ! -f "$PREFS_FILE" ]; then
      $DRY_RUN_CMD echo "ℹ️  Note: Brave profile not yet created. Run 'brave' once, then search engines will be configured."
      exit 0
    fi

    # Backup original
    $DRY_RUN_CMD cp "$PREFS_FILE" "$PREFS_FILE.backup.$(date +%s)"

    # Configure search engines using a Python script for safe JSON manipulation
    $DRY_RUN_CMD ${pkgs.python3}/bin/python3 << 'PYTHON_EOF'
    import json
    import os

    prefs_file = os.path.expanduser("~/.config/BraveSoftware/Brave-Browser/Default/Preferences")

    # Search engines to add (name, keyword, url)
    search_engines = [
        ("Google", "g", "https://www.google.com/search?q={searchTerms}"),
        ("Brave Search", "b", "https://search.brave.com/search?q={searchTerms}"),
        ("GitHub", "gh", "https://github.com/search?q={searchTerms}"),
        ("Stack Overflow", "so", "https://stackoverflow.com/search?q={searchTerms}"),
        ("NPM", "npm", "https://www.npmjs.com/search?q={searchTerms}"),
        ("Google Scholar", "scholar", "https://scholar.google.com/scholar?q={searchTerms}"),
        ("Product Hunt", "ph", "https://www.producthunt.com/search?q={searchTerms}"),
        ("Indie Hackers", "ih", "https://www.indiehackers.com/search?q={searchTerms}"),
        ("Hacker News", "hn", "https://hn.algolia.com/?query={searchTerms}"),
        ("Nix Packages", "np", "https://search.nixos.org/packages?query={searchTerms}"),
        ("ArXiv", "arxiv", "https://arxiv.org/search/?query={searchTerms}"),
        ("ChatGPT Search", "ai", "https://chatgpt.com/?search={searchTerms}"),
        ("YouTube", "yt", "https://www.youtube.com/results?search_query={searchTerms}"),
        ("Twitter", "tw", "https://twitter.com/search?q={searchTerms}"),
        ("Dev.to", "dev", "https://dev.to/search?q={searchTerms}"),
        ("MDN Web Docs", "doc", "https://developer.mozilla.org/en-US/search?q={searchTerms}"),
        ("DuckDuckGo", "d", "https://duckduckgo.com/?q={searchTerms}"),
        ("Reddit", "r", "https://www.reddit.com/search?q={searchTerms}"),
    ]

    try:
        with open(prefs_file, 'r') as f:
            prefs = json.load(f)
    except Exception as e:
        print(f"Error reading Preferences: {e}")
        exit(1)

    # Initialize search_providers structure if needed
    if "search_providers" not in prefs:
        prefs["search_providers"] = {}
    if "search_engines" not in prefs["search_providers"]:
        prefs["search_providers"]["search_engines"] = []

    # Get existing keywords to avoid duplicates
    existing_keywords = {se.get("keyword", "") for se in prefs["search_providers"]["search_engines"]}

    # Add new search engines
    for name, keyword, url in search_engines:
        if keyword not in existing_keywords:
            engine = {
                "name": name,
                "keyword": keyword,
                "favicon_url": "",
                "search_url": url,
                "suggest_url": "",
                "encoding": "UTF-8",
                "date_created": "",
                "date_modified": "",
                "syncable": True,
                "type": "SEARCH_ENGINE",
            }
            prefs["search_providers"]["search_engines"].append(engine)
            print(f"✅ Added search engine: {name} ({keyword})")
        else:
            print(f"ℹ️  Search engine already exists: {keyword}")

    # Write back
    try:
        with open(prefs_file, 'w') as f:
            json.dump(prefs, f, indent=2)
        print("✅ Brave search engines configured successfully!")
    except Exception as e:
        print(f"Error writing Preferences: {e}")
        exit(1)
    PYTHON_EOF
  '';
}
