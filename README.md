# RentEase - Peer-to-Peer Rental Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎓 University Project Overview

RentEase is a comprehensive peer-to-peer rental platform with integrated delivery services, developed as a university project to demonstrate modern mobile app development practices using Flutter and Supabase.

### 🏆 Key Features Demonstrated

- **Clean Architecture**: Implemented with BLoC pattern for state management
- **Real-time Features**: Live messaging and delivery tracking
- **Secure Authentication**: User registration, login, and profile management
- **Database Integration**: Supabase with proper relationships and RLS policies
- **Modern UI/UX**: Material 3 design with responsive layouts
- **Mock Payment System**: Realistic payment flow for demonstration
- **Delivery Management**: Complete delivery workflow with driver dashboard

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/rent_ease.git
   cd rent_ease
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   # Create a .env file in the root directory
   cp .env.example .env
   # Add your Supabase credentials (demo credentials provided)
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🎯 Demo Guide

### 1. Authentication Flow
- **Registration**: Create new account with email/password
- **Login**: Secure authentication with error handling
- **Profile Setup**: Role selection (Renter/Owner/Driver)

### 2. Core Features
- **Browse Items**: Explore available rental items
- **Create Listings**: Add items for rent with photos
- **Booking System**: Complete rental booking flow
- **Payment Processing**: Mock payment with realistic UI
- **Messaging**: Real-time chat between users
- **Delivery Tracking**: Track delivery status

### 3. Advanced Features
- **Driver Dashboard**: Manage delivery jobs
- **Profile Management**: User statistics and settings
- **Real-time Updates**: Live notifications and updates

## 🏗️ Architecture

### Clean Architecture Implementation

```
lib/
├── core/                 # Core functionality
│   ├── config/          # Environment configuration
│   ├── constants/       # App constants
│   ├── di/             # Dependency injection
│   ├── router/         # Navigation routing
│   ├── services/       # Core services
│   ├── theme/          # App theming
│   └── utils/          # Utility functions
├── features/           # Feature modules
│   ├── auth/           # Authentication
│   ├── home/           # Home screen
│   ├── listing/        # Item listings
│   ├── messages/       # Chat messaging
│   ├── payment/        # Payment processing
│   ├── delivery/       # Delivery management
│   └── profile/        # User profiles
└── shared/             # Shared widgets
    ├── widgets/        # Reusable components
    └── models/         # Shared data models
```

### State Management (BLoC Pattern)

Each feature implements the BLoC pattern:
- **Events**: User actions and system events
- **States**: UI states and data representations
- **BLoC**: Business logic and state transitions

## 🛠️ Technical Stack

### Frontend
- **Flutter 3.x**: Cross-platform mobile framework
- **Dart**: Programming language
- **BLoC**: State management pattern
- **GoRouter**: Navigation and routing
- **Material 3**: Modern UI design system

### Backend
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Database
- **Row Level Security**: Data protection
- **Real-time subscriptions**: Live updates
- **Storage**: File and image management

### Key Packages
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  go_router: ^12.1.1
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.4
  equatable: ^2.0.5
```

## 📱 Screenshots

### Authentication Flow
- [x] Splash Screen with loading animation
- [x] Onboarding screens with smooth transitions
- [x] Registration with form validation
- [x] Login with enhanced error handling

### Main Features
- [x] Home screen with featured items
- [x] Item listing with detailed views
- [x] Booking flow with date selection
- [x] Payment processing with mock system
- [x] Messaging with real-time updates
- [x] Profile management with statistics

## 🎨 UI/UX Enhancements

### Enhanced Loading States
- Skeleton screens for better perceived performance
- Contextual loading messages
- Animated progress indicators

### Error Handling
- Specific error types with appropriate icons
- User-friendly error messages
- Retry mechanisms and support contact

### Form Validation
- Real-time validation feedback
- Enhanced error messages
- Input formatting (card numbers, dates)

## 🔧 Development Features

### Code Quality
- **Clean Architecture**: Separation of concerns
- **SOLID Principles**: Maintainable code structure
- **Error Handling**: Comprehensive error management
- **Type Safety**: Null safety and strong typing

### Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for complete flows
- Mock implementations for external services

## 📊 Database Schema

### Core Tables
- `users`: User authentication and profiles
- `items`: Rental items and listings
- `bookings`: Rental bookings and history
- `messages`: Chat messages and conversations
- `delivery_jobs`: Delivery tracking and management
- `categories`: Item categories and classification

### Security
- Row Level Security (RLS) policies
- User-based data access control
- Secure file storage with proper permissions

## 🚀 Deployment

### Development
```bash
flutter run --debug
```

### Production Build
```bash
flutter build apk --release
flutter build ios --release
```

### Testing
```bash
flutter test
flutter test --coverage
```

## 🎓 Academic Highlights

### Learning Objectives Achieved
1. **Mobile App Development**: Complete Flutter application
2. **State Management**: BLoC pattern implementation
3. **Backend Integration**: Supabase services
4. **UI/UX Design**: Material 3 design system
5. **Real-time Features**: Live messaging and updates
6. **Database Design**: Relational database with proper schema
7. **Security**: Authentication and authorization
8. **Testing**: Unit and widget testing strategies

### Technical Challenges Solved
- Real-time messaging implementation
- Complex state management across features
- Image upload and storage
- Payment flow simulation
- Delivery tracking system
- Responsive UI design

## 📝 Documentation

### API Documentation
- [Supabase API Reference](docs/api.md)
- [Database Schema](docs/database.md)
- [Authentication Flow](docs/auth.md)

### Development Guides
- [Setup Guide](docs/setup.md)
- [Contributing Guidelines](docs/contributing.md)
- [Testing Guide](docs/testing.md)

## 🤝 Contributing

This is a university project, but contributions and suggestions are welcome:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Material Design team for the design system
- University instructors for guidance and support

## 📞 Contact

For questions about this university project:
- **Email**: your.email@university.edu
- **GitHub**: [Your GitHub Profile](https://github.com/yourusername)
- **LinkedIn**: [Your LinkedIn Profile](https://linkedin.com/in/yourprofile)

---

**Note**: This is a university project created for educational purposes. The payment system is implemented as a mock system for demonstration only.

## 🎯 Demo Script

### For Presentation (5-10 minutes)

1. **Introduction** (1 min)
   - Project overview and technology stack
   - Key features and architecture

2. **Authentication Demo** (1 min)
   - User registration with validation
   - Login flow with error handling

3. **Core Features** (3-4 mins)
   - Browse and search items
   - Create a listing with photos
   - Complete booking flow
   - Payment processing demo

4. **Advanced Features** (2-3 mins)
   - Real-time messaging
   - Delivery tracking
   - Driver dashboard
   - Profile management

5. **Technical Highlights** (1-2 mins)
   - Architecture overview
   - State management
   - Database integration
   - Real-time features

### Test Accounts (for Demo)
- **Regular User**: demo@rentease.com / password123
- **Driver**: driver@rentease.com / password123
- **Admin**: admin@rentease.com / password123

### Sample Credit Cards (Mock System)
- **Visa**: 4111 1111 1111 1111
- **Mastercard**: 5555 5555 5555 4444
- **American Express**: 3782 822463 10005
- **Expiry**: Any future date (MM/YY)
- **CVV**: Any 3-4 digits
#   R e n t E a s e  
 