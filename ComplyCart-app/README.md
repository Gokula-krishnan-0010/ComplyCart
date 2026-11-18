# ComplyCart Mobile Application

A mobile application designed to simplify and automate Legal Metrology compliance auditing. Built for compliance officers, auditors, and e-commerce platform administrators, the app facilitates checking and monitoring product packaging requirements.

---

## Key Features

- **Dashboard**: A comprehensive interface featuring animated metrics, compliance trends, and seller performance overviews.
- **Smart Marketplace Directory**: A real-time searchable grid of audited platform sellers, including details on risk profiles and audit vintage.
- **URL Compliance Analyzer**: Allows auditing e-commerce product listings via URL extraction to identify missing required details.
- **Label Scanner**: Native camera integration designed to capture and process physical product labels.
- **Deep Insights**: Detailed seller and product view screens tracking specific compliance status and historical results.
- **Unified Authentication**: User registration, login, and security workflows.

---

## Technical Stack

- **Frontend SDK**: Flutter (Material 3 Design System)
- **State Management**: Provider
- **Networking**: Dio HTTP client
- **Fonts**: Poppins (Google Fonts)
- **Hardware Integration**: Camera package for native scanning support

---

## Project Structure

```text
lib/
├── models/      # Structured data schemas (Seller, Product, ComplianceResult)
├── screens/     # Application screens (Marketplace, Scanner, Profile)
├── widgets/     # Shared, reusable UI components (AnimatedHeader, SellerCard)
├── providers/   # Global and local state management stores
├── services/    # Network clients, API wrappers, and Mock systems
├── theme/       # Centralized design tokens (color schemes, typography, spacing)
└── utils/       # Common helper methods and constants
```

---

## Getting Started

### Prerequisites

- Flutter SDK (version `^3.12.0` or higher)
- Android Studio, VS Code, or Xcode
- An active emulator or physical mobile device (recommended for Camera-based label scanning)

### Setup & Launch

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the Application**:
   - For mobile devices (recommended):
     ```bash
     flutter run
     ```
   - For web target:
     ```bash
     flutter run -d chrome
     ```

---

## Development Roadmap

- **Integration**: Link directly to the FastAPI backend service.
- **PDF Export**: Implement compliance report generation and exporting.
- **Dark Theme**: Add support for a dark mode layout.
- **Auditing Notifications**: Set up real-time notification alerts for compliance updates.
