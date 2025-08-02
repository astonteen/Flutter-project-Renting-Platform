# Google Places API Setup Guide

## Overview
This application uses Google Places API for address autocomplete functionality. You need to set up a valid Google Places API key to use this feature.

## Steps to Set Up Google Places API

### 1. Create a Google Cloud Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable billing for your project (required for Google Places API)

### 2. Enable Google Places API
1. In the Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Places API" and enable it
3. Also enable "Maps JavaScript API" if you plan to use maps

### 3. Create API Key
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key

### 4. Restrict API Key (Recommended)
1. Click on your API key to edit it
2. Under "API restrictions", select "Restrict key"
3. Choose the APIs you want to allow:
   - Places API
   - Maps JavaScript API (if needed)
4. Under "Application restrictions", you can restrict by:
   - HTTP referrers (for web)
   - Android apps (for Android)
   - iOS apps (for iOS)

### 5. Configure the API Key in Your App

#### Environment Configuration
1. Open `.env.development` file in the project root
2. Replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` with your actual API key:
   ```
   GOOGLE_PLACES_API_KEY=your_actual_api_key_here
   ```

#### Platform-Specific Configuration

**For Android:**
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` with your actual API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="your_actual_api_key_here" />
   ```

**For Web:**
1. Open `web/index.html`
2. Uncomment and update the Google Maps script:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=your_actual_api_key_here"></script>
   ```

## Features Enabled

With the Google Places API configured, you'll have access to:

- **Address Autocomplete**: Type-ahead suggestions when entering addresses
- **International Support**: Address parsing for multiple countries
- **Current Location**: Get address from GPS coordinates
- **Address Validation**: Verify address completeness

## Troubleshooting

### "API key is invalid" Error
- Verify your API key is correct
- Ensure Places API is enabled in Google Cloud Console
- Check that your API key restrictions allow your app
- Make sure billing is enabled for your Google Cloud project

### No Autocomplete Suggestions
- Verify your API key has Places API enabled
- Check network connectivity
- Ensure you're not hitting API quotas/limits

### Country Restrictions
- The app now supports worldwide address search
- If you want to restrict to specific countries, you can modify the `countries` parameter in `add_edit_address_screen.dart`

## Cost Considerations

- Google Places API has usage-based pricing
- Autocomplete requests cost per session
- Monitor your usage in Google Cloud Console
- Set up billing alerts to avoid unexpected charges

## Security Best Practices

- Never commit API keys to version control
- Use environment variables for API keys
- Restrict API keys to specific APIs and applications
- Regularly rotate API keys
- Monitor API usage for unusual activity