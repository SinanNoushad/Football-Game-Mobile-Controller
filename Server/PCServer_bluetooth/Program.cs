using System;
using System.Windows.Forms;
using System.Threading.Tasks;
using PCServer_bluetooth.Services;
using PCServer_bluetooth.Configuration;
using PCServer_bluetooth.Models;

namespace PCServer_bluetooth
{
    public partial class Program : Form
    {
        private readonly IBluetoothService _bluetoothService;
        private readonly IWebSocketServer _webSocketServer;
        private readonly IVirtualController _virtualController;
        private readonly IControllerManager _controllerManager;
        private readonly ServerConfig _config;

        public Program()
        {
            InitializeComponent();

            // Initialize configuration
            _config = new ServerConfig
            {
                WebSocketPort = 8080,
                BluetoothServiceName = "Football Controller",
                VirtualControllerIndex = 1
            };

            try
            {
                // Initialize services
                _bluetoothService = new BluetoothService();
                _webSocketServer = new WebSocketServer(_config);
                _virtualController = new VirtualController(_config);
                _controllerManager = new ControllerManager(
                    _bluetoothService,
                    _webSocketServer,
                    _virtualController);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error initializing services: {ex.Message}", "Initialization Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                throw;
            }
        }

        protected override async void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            await StartServicesAsync();
        }

        private async Task StartServicesAsync()
        {
            try
            {
                await _virtualController.InitializeAsync();
                await _webSocketServer.StartAsync(default);
                await _bluetoothService.StartAsync(default);
                
                // Update UI to show connected status
                // You can add status labels or indicators here
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error starting services: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        protected override async void OnFormClosing(FormClosingEventArgs e)
        {
            base.OnFormClosing(e);
            
            try
            {
                if (_controllerManager != null)
                {
                    await _controllerManager.StopAsync(default);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error stopping services: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Program());
        }

        // Add your existing UI event handlers here
        // Example:
        private void OnStatusUpdate(object sender, string message)
        {
            // Update your status label or other UI elements
            // Make sure to use Invoke if updating from a different thread
            if (InvokeRequired)
            {
                Invoke(new Action<object, string>(OnStatusUpdate), sender, message);
                return;
            }

            // Update your UI here
            // statusLabel.Text = message;
        }
    }
}