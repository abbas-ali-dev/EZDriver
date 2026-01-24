# Person Marker Icon Guide

## Required Asset
The app needs a person marker icon at: `assets/icon/ic_marker_person.png`

## Specifications
- **Size**: 100x100 pixels (or larger, will be scaled)
- **Format**: PNG with transparency
- **Design**: Simple person/user silhouette icon
- **Color**: Blue or primary color (can be any color as it will be visible on the map)
- **Style**: Should match the car marker style

## Current Status
The code has been updated to:
1. Try to load the person marker from `assets/icon/ic_marker_person.png`
2. If the asset doesn't exist, it will automatically create a programmatic person marker as a fallback
3. The fallback creates a blue pin-shaped marker with a person icon inside

## How to Add the Icon
1. Create or obtain a person marker icon (100x100 PNG)
2. Save it as `assets/icon/ic_marker_person.png`
3. The app will automatically use it on the next build

## Alternative
If you don't have a person marker icon, the app will work fine with the programmatically generated fallback marker. The fallback creates a nice pin-shaped marker with a person silhouette inside.

## Testing
After adding the icon, test it by:
1. Running the app
2. Navigating to a scheduled ride
3. Opening the passenger map screen
4. Verifying that both the car (driver) and person (passenger) markers appear correctly
