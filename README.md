# App for iPhone

An installable web app served by GitHub Pages.

## First-time publishing

Open repository Settings > Pages. Set Source to Deploy from a branch, select main and /(root), then Save. Once the deployment is ready, open https://helpmeid.github.io/app/ in Safari. Use Share > Add to Home Screen, enable Open as Web App if offered, and tap Add.

## Updates

Every app change must increment the app-version meta tag in index.html (patch version by default). Current release: 1.0.1. GitHub Pages automatically republishes main. The app checks the deployed index on launch, when it returns to the foreground, when connectivity returns, and every 15 seconds while visible. When a newer version is available, it asks Update now or Later. Update now restarts the page with the latest published version; Later postpones the reminder for two minutes. iOS web apps cannot programmatically close and reopen themselves. Offline launch uses the most recently cached successful app page if available.

The home screen is a starter; add your app features to index.html. If adding external assets, use versioned filenames and adjust offline caching as needed. No native IPA or App Store account is needed.
