# Scheduled Rides Feature for Driver App

## Overview
This module adds the ability for drivers to schedule rides in advance, allowing them to plan their trips and potentially pick up additional riders along the way.

## Features

### 1. Create Scheduled Ride
- **Service Selection**: Choose from available services (car types)
- **Vehicle Selection**: Select from driver's registered vehicles
- **Location Selection**: Pick pickup and destination locations
- **Date & Time**: Schedule the ride for a future date and time
- **Passenger Count**: Specify number of passengers
- **Notes**: Add additional notes or requirements
- **Fare Calculation**: Automatic fare estimation based on distance and service

### 2. View Scheduled Rides
- **List View**: See all scheduled rides with status indicators
- **Filter Options**: Filter by status (All, Pending, Active, Completed, Cancelled)
- **Status Colors**: Visual status indicators
- **Pull to Refresh**: Refresh the list to get latest data

### 3. Manage Scheduled Rides
- **Edit**: Modify existing scheduled rides
- **Cancel**: Cancel pending rides with reason
- **Complete**: Mark active rides as completed
- **Delete**: Remove scheduled rides

### 4. Smart Matching
- **Nearby Riders**: System can suggest nearby riders who might be interested in joining the scheduled ride
- **Route Optimization**: Efficient route planning for multiple pickups

## Technical Implementation

### Files Created/Modified

#### Models
- `lib/data/model/scheduled_ride/scheduled_ride_model.dart` - Data models for scheduled rides

#### Repository
- `lib/data/repo/scheduled_ride/scheduled_ride_repo.dart` - API calls for scheduled rides

#### Controller
- `lib/data/controller/scheduled_ride_controller.dart` - Business logic for scheduled rides

#### UI Screens
- `lib/presentation/screens/scheduled_rides_screen.dart` - Main scheduled rides list screen
- `lib/presentation/screens/scheduled_rides/create_scheduled_ride_screen.dart` - Create/edit scheduled ride screen

#### Routes
- `lib/core/route/route.dart` - Added routes for scheduled rides screens

#### Navigation
- `lib/presentation/screens/profile_and_settings/profile_and_settings_screen.dart` - Added menu option for scheduled rides

### API Endpoints Required

The following API endpoints need to be implemented on the backend:

1. **GET /scheduled-rides** - Get driver's scheduled rides
2. **GET /scheduled-rides/{id}** - Get specific scheduled ride
3. **POST /scheduled-rides** - Create new scheduled ride
4. **PUT /scheduled-rides/{id}** - Update scheduled ride
5. **DELETE /scheduled-rides/{id}** - Delete scheduled ride
6. **POST /scheduled-rides/{id}/cancel** - Cancel scheduled ride
7. **GET /driver/vehicles** - Get driver's vehicles
8. **GET /driver/services** - Get available services
9. **POST /scheduled-rides/calculate-fare** - Calculate estimated fare
10. **GET /scheduled-rides/{id}/nearby-riders** - Get nearby riders

### Database Schema

The scheduled rides table should include:
- `id` - Primary key
- `driver_id` - Foreign key to drivers table
- `service_id` - Foreign key to services table
- `vehicle_id` - Foreign key to vehicles table
- `pickup_location` - Pickup address
- `pickup_latitude` - Pickup latitude
- `pickup_longitude` - Pickup longitude
- `destination` - Destination address
- `destination_latitude` - Destination latitude
- `destination_longitude` - Destination longitude
- `scheduled_date_time` - Scheduled date and time
- `number_of_passengers` - Number of passengers
- `note` - Additional notes
- `status` - Status (pending, active, completed, cancelled)
- `estimated_fare` - Estimated fare amount
- `distance` - Distance in km
- `duration` - Duration in minutes
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

## Usage

### For Drivers
1. Navigate to Profile & Settings → Scheduled Rides
2. Tap the + button to create a new scheduled ride
3. Fill in the required information:
   - Select service type
   - Choose vehicle
   - Set pickup and destination locations
   - Pick date and time
   - Enter passenger count
   - Add notes (optional)
4. Review estimated fare and submit
5. Manage existing rides from the list view

### For Riders (Future Enhancement)
- Riders can view available scheduled rides near their route
- Request to join a scheduled ride
- Driver can accept/reject additional riders
- Split fare calculation for multiple riders

## Benefits

1. **Better Planning**: Drivers can plan their trips in advance
2. **Increased Efficiency**: Potential for multiple pickups along the route
3. **Flexibility**: Easy to modify or cancel scheduled rides
4. **Revenue Optimization**: Maximize vehicle utilization
5. **User Experience**: Better service for both drivers and riders

## Future Enhancements

1. **Real-time Notifications**: Notify drivers when riders request to join
2. **Route Optimization**: AI-powered route planning for multiple pickups
3. **Dynamic Pricing**: Adjust fares based on demand and availability
4. **Integration with Calendar**: Sync with driver's calendar
5. **Analytics Dashboard**: Track performance and earnings from scheduled rides

## Testing

To test the feature:
1. Ensure backend API endpoints are implemented
2. Test all CRUD operations for scheduled rides
3. Verify fare calculation accuracy
4. Test location picker integration
5. Validate form validation and error handling
6. Test offline functionality and data sync

## Notes

- The location picker functionality is currently showing a "Coming Soon" message
- Some features like editing and detailed view are marked as "Coming Soon"
- The feature is designed to be easily extensible for future enhancements
- All UI components follow the existing app's design patterns and color scheme 