# App for iPhone

An installable web app served by GitHub Pages.

## First-time publishing

Open repository Settings > Pages. Set Source to Deploy from a branch, select main and /(root), then Save. Once the deployment is ready, open https://helpmeid.github.io/app/ in Safari. Use Share > Add to Home Screen, enable Open as Web App if offered, and tap Add.

## Updates

Edit index.html on main and increase the app-version meta tag for each release. GitHub Pages automatically republishes the branch. The app checks the deployed index on launch, when it returns to the foreground, when connectivity returns, and every minute while visible. If a different version is published it reloads automatically. Offline launch uses the most recently cached successful app page if available.

The home screen is a starter; add your app features to index.html. If adding external assets, use versioned filenames and adjust offline caching as needed. No native IPA or App Store account is needed.
