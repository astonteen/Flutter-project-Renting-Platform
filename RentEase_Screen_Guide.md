# RentEase App - Screen Functionality Guide

## Authentication & Onboarding Screens

**SplashScreen** serves as the app's loading screen that appears when users first open RentEase. It displays the app logo and handles initialization tasks before automatically redirecting users to the onboarding process after a brief delay.

**OnboardingScreen** introduces new users to the app's key features through a series of educational slides. Users can swipe through multiple pages that explain how RentEase works, or skip directly to the login screen if they're already familiar with the platform.

**LoginScreen** allows existing users to sign into their accounts using their email and password. The screen includes form validation, loading states during authentication, and links to both the registration screen for new users and password recovery options.

**RegisterScreen** enables new users to create their RentEase accounts by providing their email address and creating a secure password. The screen validates user input, handles account creation through Supabase, and redirects successful registrations to the role selection process.

**RoleSelectionScreen** appears after registration and lets users choose their primary role within the platform: Renter (looking for items), Owner (sharing items), or Delivery Partner (providing logistics). This selection customizes their entire app experience to show relevant features prominently.

**ProfileSetupScreen** completes the registration process by collecting additional user information like name, phone number, and profile photo. The screen adapts based on the user's selected role and ensures all necessary information is gathered before granting full app access.

## Main Navigation & Home

**MainScreen** functions as the app's navigation shell, providing the bottom navigation bar that allows users to switch between the five main sections: Home, Rentals, List Item, Messages, and Profile. It maintains navigation state and handles the routing between different app sections.

**HomeScreen** serves as the main marketplace discovery hub where users can search for rental items, browse categories, view featured listings, and explore nearby available items. The screen includes search functionality, category filters, and displays item cards with pricing and basic information.

## Messaging & Communication

**MessagesScreen** displays all user conversations in a centralized inbox interface. Users can filter between "All" conversations and "Groups" only, search through their message history, and access a floating action button to start new conversations with other platform users.

**UserSelectionScreen** appears when users want to start a new conversation and shows a searchable list of all app users except the current user. The screen includes a "Create a group" option at the top and allows users to search for specific people before starting individual conversations.

**ChatScreen** provides the actual messaging interface where users can send and receive messages in real-time. The screen supports text messages, image sharing, and includes options for voice and video calls, creating a comprehensive communication experience between platform participants.

## Delivery & Logistics

**DeliveryScreen** acts as an intelligent router that determines whether to show delivery tracking for regular users or the driver dashboard for users with delivery partner profiles. It automatically detects the user's role and presents the appropriate interface.

**EnhancedDriverDashboard** is exclusively for delivery partners and provides comprehensive tools for managing their delivery business. Drivers can toggle their availability, view incoming job requests, track earnings and performance metrics, and manage active deliveries all from this central hub.

**DeliveryTrackingScreen** allows users to track their deliveries in real-time, showing the driver's location, estimated arrival time, and delivery status updates. Users can also communicate directly with their assigned delivery partner through this interface.

## Rentals & Item Management

**RentalsScreen** displays all of the user's rental activities organized into tabs for Active, Past, and All rentals. Users can view booking details, track rental periods, manage returns, extend rental periods, and access their complete rental history.

**CreateListingScreen** guides users through the process of listing their items for rent. The screen includes photo upload functionality, category selection, pricing tools, availability calendar management, and detailed description fields to create comprehensive item listings.

**MyListingsScreen** allows item owners to manage all their rental listings from a single interface. Users can edit existing listings, toggle availability, view performance analytics, respond to booking requests, and track revenue from their shared items.

**ItemDetailsScreen** shows comprehensive information about specific rental items including photo galleries, detailed descriptions, owner information, pricing details, availability calendars, and user reviews. The screen includes booking functionality and sharing options.

**BookingScreen** handles the rental transaction process by allowing users to select rental dates, calculate total costs including any delivery fees, choose pickup or delivery options, and complete secure payment processing to confirm their booking.

## Payment & Financial

**PaymentScreen** manages all financial transactions within the app, allowing users to add payment methods, process rental payments, view transaction history, and handle refunds or disputes. The screen integrates with secure payment processors to ensure safe financial transactions.

## Profile & Settings

**ProfileScreen** serves as the user's account management center where they can view and edit their profile information, access app settings, manage notification preferences, view their ratings and reviews, and access help and support resources.

**NotificationSettingsScreen** provides granular control over all app notifications, allowing users to customize preferences for booking confirmations, message alerts, delivery updates, promotional communications, and other app-generated notifications.

## Development & Testing

**DebugScreen** is available only in development builds and provides developers with tools to test app functionality, monitor performance, view logs, test API connections, and access debugging information during the development process.

## Screen Flow Summary

The typical user journey flows from the splash screen through onboarding and authentication, then into the main app where the home screen serves as the primary discovery point. Users can navigate between rentals management, messaging, item listing, and profile sections through the persistent bottom navigation. Specialized screens like delivery tracking and payment processing appear contextually when needed, while the role-based customization ensures users see the most relevant features for their chosen platform participation level. 