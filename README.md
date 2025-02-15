# Mobile Game Controller

A cross-platform mobile controller that converts your smartphone into a versatile game controller for PC gaming. Built with Flutter and C#, it supports both WiFi and Bluetooth connectivity while providing a fully customizable touch interface.


## Features

### Connectivity
- **Dual Connection Modes**
  - WiFi with auto-discovery(Completed)
  - Bluetooth support(developing)
- **Easy Server Discovery**
  - Automatic server detection
  - Manual IP configuration
  - Multiple controller support

### Controls
- **Fully Customizable Layout**
  - Drag-and-drop button positioning
  - Layout persistence
  - Edit mode for easy customization

- **Complete Controller Mapping**
  - Dual analog sticks
  - D-pad
  - Action buttons (A, B, X, Y)
  - Shoulder buttons (LB, RB)
  - Triggers (LT, RT)
  - Start/Select buttons

### Special Features
- **Advanced Gaming Controls**
  - Support for complex button combinations
  - Pressure-sensitive triggers
  - Precise analog stick control
  - Special move combinations for sports games

- **Professional UI**
  - Modern interface
  - Real-time connection status
  - Command logging
  - Session management

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Visual Studio 2022 or later
- .NET 6.0 or later
- ViGEm Bus Driver installed on Windows

### Installation

1. **Server Setup (Windows)**
   ```bash
   # Clone the repository
   git clone [repository-url]
   
   # Navigate to server directory
   cd PCServer
   
   # Build the solution
   dotnet build
   ```

2. **Mobile App Setup**
   ```bash
   # Navigate to mobile app directory
   cd mobile_controller
   
   # Get dependencies
   flutter pub get
   
   # Run the app in debug mode
   flutter run
   ```

### Configuration

1. **Server Configuration**
   - Launch the PC Server application
   - Select your preferred port (default: 8080)
   - Start the server
   - Enable Bluetooth if needed

2. **Mobile App Configuration**
   - Launch the mobile app
   - Choose connection mode (WiFi/Bluetooth)
   - For WiFi:
     - Use auto-detect or enter server IP manually
   - For Bluetooth:
     - Enable Bluetooth and pair with PC

## Usage

1. **Connect to Server**
   - Long press the connection button
   - Select your connection mode
   - Choose your server/device

2. **Customize Layout**
   - Tap the edit button in connection dialog
   - Drag buttons to desired positions
   - Save layout

3. **Gaming**
   - Use analog sticks for movement/camera
   - Use action buttons for game-specific actions
   - Utilize special combinations for advanced moves

## Development

### Project Structure
```
├── PCServer/              # C# Server Application
│   ├── Program.cs        # Main server logic
│   └── VirtualController # Controller emulation
├── mobile_controller/    # Flutter Mobile App
│   ├── lib/
│   │   ├── screens/     # UI screens
│   │   ├── widgets/     # Controller components
│   │   └── providers/   # State management
│   └── pubspec.yaml     # Dependencies
```

### Building

1. **Server**
   ```bash
   dotnet publish -c Release
   ```

2. **Mobile App**
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ViGEm](https://github.com/ViGEm) for the virtual controller driver
- Flutter team for the amazing cross-platform framework
- WebSocketSharp for .NET WebSocket implementation

## Support

For support, please open an issue in the GitHub repository or contact [your-email].
