# RentEase Mobile Application UI Design Prompt

## Application Overview
Create a comprehensive mobile application UI for "RentEase" - a peer-to-peer item rental platform with integrated delivery services. The app allows users to rent items from others and also offer delivery services for rented items.

## Core Features & User Roles
- **Renters**: Browse, search, and rent items
- **Lenders**: List items for rent and manage rentals
- **Delivery Partners**: Provide pickup and delivery services
- **Hybrid Users**: Can switch between all three roles

## Screen Flow Architecture

### 1. ONBOARDING & AUTHENTICATION FLOW
**Splash Screen** → **Onboarding Slides** → **Login/Register** → **Role Selection** → **Profile Setup** → **Main Dashboard**

#### Screen Details:
- **Splash Screen**: RentEase logo with loading animation
- **Onboarding (3-4 slides)**: Feature highlights with "Skip" and "Next" buttons
- **Authentication**: 
  - Login with email/phone and password
  - Register with full form validation
  - Social login options (Google, Facebook)
  - Forgot password flow
- **Role Selection**: Choose primary role (can be changed later)
- **Profile Setup**: Photo upload, basic info, location verification

### 2. MAIN NAVIGATION STRUCTURE
Bottom Tab Navigation with 5 tabs:
- **Home** (Browse/Search)
- **My Rentals** (Active rentals)
- **Deliver** (Delivery opportunities)
- **Messages** (Chat system)
- **Profile** (Settings & account)

### 3. HOME SCREEN FLOW
**Home** → **Category View** → **Item Details** → **Booking Flow** → **Payment** → **Confirmation**

#### Home Screen Components:
- Search bar with location filter
- Category grid (Electronics, Tools, Sports, etc.)
- "Near You" section with map integration
- Featured/promoted items carousel
- Recently viewed items
- Quick action buttons (List Item, Become Delivery Partner)

#### Item Details Flow:
- High-quality image gallery with zoom
- Item description, specifications, and condition
- Pricing (per hour/day/week)
- Owner profile preview
- Availability calendar
- Reviews and ratings
- "Rent Now" and "Message Owner" buttons
- Delivery options toggle

### 4. BOOKING & PAYMENT FLOW
**Item Details** → **Rental Duration** → **Delivery Options** → **Payment Method** → **Booking Confirmation**

#### Booking Components:
- Date/time picker for rental period
- Delivery address input with map
- Delivery partner selection (if available)
- Cost breakdown (rental + delivery + fees)
- Security deposit information
- Terms and conditions checkbox

### 5. MY RENTALS FLOW
**My Rentals Tab** → **Active/Past Rentals** → **Rental Details** → **Action Options**

#### Rental Management:
- Active rentals with countdown timers
- Rental history with search/filter
- Individual rental cards showing:
  - Item photo and name
  - Rental dates and status
  - Total cost and payment status
  - Delivery tracking (if applicable)
  - Quick actions (Extend, Return, Contact Owner)

### 6. DELIVERY PARTNER FLOW
**Deliver Tab** → **Available Jobs** → **Job Details** → **Accept Job** → **Navigation** → **Completion**

#### Delivery Features:
- Map view of available delivery jobs
- Job filters (distance, payment, type)
- Job cards with pickup and dropoff locations
- Estimated earnings and completion time
- In-app navigation integration
- Photo confirmation for pickup/delivery
- Digital signature capture
- Earnings tracker

### 7. LISTING ITEMS FLOW
**Profile** → **List New Item** → **Item Information** → **Photos** → **Pricing** → **Availability** → **Publish**

#### Listing Components:
- Category selection with guided flow
- Multiple photo upload with editing tools
- Detailed description with character counter
- Condition assessment
- Pricing calculator with suggestions
- Calendar availability setting
- Location and pickup preferences
- Delivery options configuration

### 8. MESSAGING SYSTEM FLOW
**Messages Tab** → **Conversation List** → **Individual Chat** → **Quick Actions**

#### Chat Features:
- Real-time messaging with typing indicators
- Photo and document sharing
- Quick reply templates
- Location sharing
- Rental-specific quick actions
- Voice message support
- Auto-translation for different languages

### 9. PROFILE & SETTINGS FLOW
**Profile Tab** → **Various Settings Screens** → **Sub-menus**

#### Profile Sections:
- Personal information management
- Payment methods and wallet
- Delivery partner application/dashboard
- Rental history and analytics
- Reviews and ratings received
- Notification preferences
- Support and help center
- Legal documents and policies

## Design Specifications

### Visual Design Requirements:
- **Color Scheme**: Primary white, secondary green (#404145), accent (#1DBF73))
- **Typography**: Clean, modern sans-serif font (Roboto/SF Pro)
- **Icons**: Consistent icon set with outline and filled variations
- **Cards**: Rounded corners (8px), subtle shadows, white backgrounds
- **Buttons**: Rounded (24px), with proper loading states and disabled states

### UX Patterns:
- **Loading States**: Skeleton screens for all data-heavy pages
- **Empty States**: Friendly illustrations with actionable messages
- **Error Handling**: Clear error messages with retry options
- **Accessibility**: High contrast, large touch targets, screen reader support
- **Responsive**: Adapt to different screen sizes and orientations

### Interactive Elements:
- **Pull-to-refresh** on listing screens
- **Infinite scroll** for search results
- **Swipe gestures** for quick actions
- **Haptic feedback** for important interactions
- **Animated transitions** between screens
- **Progressive disclosure** for complex forms

### Platform-Specific Features:
- **iOS**: Native navigation patterns, SF Symbols, Face ID/Touch ID
- **Android**: Material Design components, fingerprint authentication
- **Cross-platform**: Consistent core functionality with platform adaptations

## Key User Journeys to Highlight:

### Journey 1: First-time Renter
Onboarding → Browse items → View details → Book item → Arrange delivery → Complete rental

### Journey 2: Item Owner
Sign up → List first item → Receive booking request → Manage rental → Get paid

### Journey 3: Delivery Partner
Apply for delivery → Get approved → Browse jobs → Complete delivery → Earn money

### Journey 4: Power User
Switch between renting, lending, and delivering within single session

## Technical Considerations:
- **Real-time Updates**: Live delivery tracking, instant messaging
- **Offline Support**: Basic browsing and cached data access
- **Push Notifications**: Booking confirmations, delivery updates, messages
- **Location Services**: GPS tracking, geofencing for delivery zones
- **Payment Integration**: Multiple payment gateways, digital wallet support
- **Photo Management**: Image compression, cloud storage integration

## Success Metrics Integration:
Design UI elements to track:
- User engagement and session duration
- Conversion rates from browse to booking
- Delivery partner acceptance rates
- User retention and return usage
- Revenue per transaction

Generate a modern, intuitive mobile application UI that prioritizes user experience while maintaining the complex functionality of a three-sided marketplace (renters, lenders, delivery partners). Ensure smooth navigation flows and clear visual hierarchy throughout all screens.