# 🥛 Milk Tracking - Dairy Delivery Management System

A comprehensive Flutter application for managing milk delivery services, customer tracking, billing, and payment management with advanced features like rate changes, quantity overrides, and detailed invoice generation.

## ✨ Features

### 👥 Customer Management
- **Add & Manage Customers** - Create customer profiles with default milk quantities and rates
- **Customer Details** - View complete customer information and delivery history
- **Pause/Resume Deliveries** - Temporarily pause milk deliveries for customers and resume when needed
- **Customer Statistics** - All-time liters delivered and total bills tracking

### 📦 Delivery Tracking
- **Daily Delivery Recording** - Track milk deliveries on a daily basis
- **Quantity Overrides** - Set custom milk quantities for specific days without affecting history
- **Rate Management** - Manage per-liter rates with automatic rate change history
- **Quantity Changes** - Update default quantities with automatic history tracking (preserves past data)
- **Delivery Confirmation** - Mark deliveries as confirmed with status tracking

### 💰 Billing & Payments
- **Automatic Invoice Generation** - Generate detailed PDF invoices for customers
- **Smart PDF Invoices** - Professional invoices with customer info, dates, quantities, rates, and totals
- **Payment Tracking** - Record and track customer payments by month
- **Balance Calculation** - Automatic calculation of unpaid balances and payment status
- **Monthly Billing** - View monthly bills, payments, balances, and previous outstanding amounts
- **All-Time Statistics** - Track total liters delivered and total bills since customer joined

### 📊 Dashboard & Reports
- **Dashboard Overview** - Real-time overview of daily deliveries and statistics
- **Monthly Reports** - Detailed monthly reports with billing summaries per customer
- **Payment History** - Complete payment history for all customers
- **Customer List** - Quick access to all customers with payment status indicators (Paid/Unpaid/Partial)

### 💾 Data Management
- **Backup & Restore** - Create timestamped backups of all data
- **Local Storage** - All data stored locally on device (JSON format)
- **Data Persistence** - Automatic save of all changes

## 🏗️ Architecture

### Data Models
```
Customer
├── id, name, phone, address
├── defaultQuantity, rate
├── joinDate, isActive
└── pausePeriods: List<PausePeriod>

DeliveryOverride
├── customerId, date
├── deliveredQuantity, rate (locked at time)

RateChange
├── customerId, effectiveDate
└── rate

QuantityChange
├── customerId, effectiveDate
└── quantity

Payment
├── customerId, date
├── amount, notes
└── paymentMonth, paymentYear

PausePeriod
├── startDate, endDate

DeliveryConfirmation
├── customerId, date
└── isDelivered
```

### Core Resolution Engine

The app uses intelligent priority resolution systems:

**Quantity Determination (5 Steps):**
1. Join Date Guard → Returns 0L if customer hasn't joined yet
2. Pause Period Guard → Returns 0L if customer is paused
3. Manual Override → Returns custom quantity if daily override exists
4. Quantity Changes → Returns quantity from effective date (preserves history)
5. Default Fallback → Returns customer's default quantity

**Rate Determination (3 Steps):**
1. Manual Override → Uses rate locked at delivery time
2. Rate Changes → Uses rate effective on that date
3. Default Fallback → Uses customer's current rate

This ensures complete historical accuracy regardless of future changes!

## 📱 Supported Platforms

- ✅ **Android** - Full support
- ✅ **iOS** - Full support
- ✅ **macOS** - Full support
- ✅ **Windows** - Full support
- ✅ **Linux** - Full support
- ⚠️ **Web** - Partial support (local storage not available)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK (comes with Flutter)
- Android Studio / Xcode (for mobile development)
- Minimum iOS 11.0, Android API 21+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/milk_tracking.git
   cd milk_tracking
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### First Time Setup

1. Open the app
2. Add your milk delivery business details (optional in settings)
3. Start adding customers
4. Begin recording daily deliveries
5. Generate invoices and track payments

## 📦 Dependencies

Key packages used:

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.0.0              # State management
  intl: ^0.18.0                 # Formatting & localization
  pdf: ^3.0.0                   # PDF generation
  printing: ^5.0.0              # Print & share PDFs
  share_plus: ^7.0.0            # Cross-platform sharing
  file_picker: ^5.0.0           # File selection
  url_launcher: ^6.0.0          # Open URLs/phone
  path_provider: ^2.0.0         # File system access
```

## 📖 Usage Guide

### Adding a New Customer

1. Navigate to **Customer List** screen
2. Tap the **+ Add Customer** button
3. Enter customer details:
   - **Name** - Customer full name
   - **Phone** - Contact number
   - **Address** - Delivery address
   - **Default Quantity** - Liters per day (e.g., 3.0)
   - **Rate** - Rs. per liter (e.g., 50)
4. Tap **Save**

### Recording Daily Deliveries

**On Dashboard:**
1. View today's date and expected deliveries
2. Enter actual milk quantity delivered for each customer
3. Tap checkmark to confirm delivery
4. Changes auto-save

**Manual Override:**
1. If customer received different quantity than default
2. Tap customer name and change quantity
3. System creates daily override (doesn't affect defaults)

### Changing Rates or Quantities

**Rate Change (Example: Increasing from Rs. 50 to Rs. 60):**
1. Go to Customer Detail → Edit Customer
2. Change Rate field to new rate
3. App creates automatic RateChange record
4. Previous invoices still show old rate
5. Future invoices show new rate

**Quantity Change (Example: From 3L to 4L daily):**
1. Go to Customer Detail → Edit Customer
2. Change Default Quantity field to new quantity
3. App creates automatic QuantityChange record
4. Previous deliveries still show old quantity
5. Future deliveries show new quantity

### Recording Payments

1. Go to **Customer Detail** screen
2. Scroll to **Payments** section
3. Tap **+ Add Payment**
4. Fill payment details:
   - **Amount** - Payment amount in rupees
   - **Date** - Payment date
   - **Billing Month** - Month the payment covers (if different)
   - **Notes** - Optional memo
5. Tap **Save**

### Generating Invoices

1. Go to **Monthly Report** screen
2. Select **Customer** from dropdown
3. Select **Month and Year**
4. Tap **Generate Invoice**
5. **PDF Preview** shows:
   - Customer details
   - Daily delivery table (date, quantity, rate, subtotal)
   - Monthly totals
   - Payments received
   - Balance due
6. Share options:
   - 📧 Email
   - 💬 WhatsApp
   - 💾 Save to device
   - 🖨️ Print

### Managing Pause Periods

**Pause Delivery:**
1. Go to Customer Detail
2. Tap **Pause Delivery** button
3. Select pause start date
4. Days marked as "Paused" in dashboard

**Resume Delivery:**
1. Go to Customer Detail
2. Tap **Resume Delivery** button
3. Select resume date
4. Deliveries resume from specified date

### Backup & Restore

**Create Backup:**
1. Go to **Settings/Backup** screen
2. Tap **Create Backup**
3. File saves as: `milk_tracker_backup_2024-05-29T15-30-45.json`
4. Can be shared via email or cloud storage

**Restore Backup:**
1. Go to **Settings/Backup** screen
2. Tap **Restore Backup**
3. Select backup file
4. Confirm restoration
5. App restarts with restored data

## 📊 Real-World Examples

### Example 1: Quantity Change
```
Scenario: Customer has been getting 3.0L daily for 10 days
Now wants 4.0L from day 11 onwards

Action: Update default quantity from 3.0L → 4.0L

Result:
- Days 1-10: Show 3.0L (from history)
- Days 11+: Show 4.0L (new quantity change)
- Monthly bill correctly reflects both quantities
- Historical accuracy maintained
```

### Example 2: Rate Adjustment
```
Scenario: Rate was Rs. 50/L for first month
Now increasing to Rs. 60/L

Action: Update rate from 50 → 60

Result:
- Previous month invoice: Rs. 50/L
- Current month invoice: Rs. 60/L
- All calculations remain accurate
- Customer can see rate change clearly
```

### Example 3: Missed Delivery
```
Scenario: Customer didn't receive milk on specific day

Action: Override quantity to 0L for that day

Result:
- Invoice shows "0.0 L" for that day
- No charge for that day
- Previous defaults unaffected
```

### Example 4: Pause & Resume
```
Scenario: Customer away from 15-20 May

Action:
1. Pause from 15 May
2. Resume on 21 May

Result:
- 15-20 May: Show as "Paused"
- Bill doesn't include paused days
- Automatic calculation of pause period
```

## 🎨 User Interface

### Screens

1. **Dashboard** - Daily overview, quick entry
2. **Customer List** - All customers with status
3. **Customer Detail** - Full customer info, history, payments
4. **Monthly Report** - Billing summaries, invoice generation
5. **Backup/Restore** - Data management

## 🔧 Configuration

### Database Location
- **Android:** `/data/data/com.example.milk_tracking/documents/milk_tracker_db.json`
- **iOS:** `Documents/milk_tracker_db.json`
- **Desktop:** `Documents/milk_tracker_db.json`

### Backup Storage
- **Mobile:** `Documents/MilkTracker/` folder
- **Desktop:** `Documents/MilkTracker/` folder

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Data not saving | Ensure app has storage permissions; check device storage space |
| Backup not found | Use device file manager to navigate to app's document directory |
| Quantities not updating | Verify customer has joined before delivery date; check pause periods |
| PDF not generating | Ensure app has file permissions; try updating app |
| Payment not recorded | Verify customer exists; check payment date is valid |

## 📋 File Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── customer.dart                  # Customer model
│   ├── delivery_override.dart         # Daily override model
│   ├── payment.dart                   # Payment model
│   ├── quantity_change.dart          # Quantity history model
│   ├── rate_change.dart              # Rate history model
│   ├── pause_period.dart             # Pause period model
│   └── delivery_confirmation.dart    # Confirmation model
├── providers/
│   └── milk_provider.dart            # State management (ChangeNotifier)
├── services/
│   └── database_service.dart         # Local storage & backup
├── screens/
│   ├── dashboard_screen.dart         # Main dashboard
│   ├── customer_list_screen.dart     # Customer management
│   ├── customer_detail_screen.dart   # Customer details
│   ├── monthly_report_screen.dart    # Reports & invoicing
│   └── backup_restore_screen.dart    # Data management
├── utils/
│   ├── pdf_generator.dart            # Invoice PDF generation
│   └── whatsapp_helper.dart          # WhatsApp integration
└── theme/
    └── app_theme.dart                # UI theme & styling
```

## 🔒 Data Security

- All data stored locally on device
- No cloud sync or remote servers
- Backups are JSON files (can be encrypted)
- User responsible for data backups
- No internet required for app functionality

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📞 Support & Contact

- 📧 Email: ahmedullah6897@gmail.com


## 🙏 Acknowledgments

- Flutter and Dart communities
- Package contributors
- All testers and users

---

**Version:** 1.0.0  
**Last Updated:** May 29, 2026  
**Status:** ✅ Production Ready

Made with ❤️ for dairy businesses
