namespace FootballController.Services
{
    public class ControllerManager : IControllerManager
    {
        private readonly IBluetoothService _bluetoothService;
        private readonly IWebSocketServer _webSocketServer;
        private readonly IVirtualController _virtualController;
        private readonly ILogger<ControllerManager> _logger;

        public ControllerManager(
            IBluetoothService bluetoothService,
            IWebSocketServer webSocketServer,
            IVirtualController virtualController,
            ILogger<ControllerManager> logger)
        {
            _bluetoothService = bluetoothService;
            _webSocketServer = webSocketServer;
            _virtualController = virtualController;
            _logger = logger;

            // Subscribe to Bluetooth input events
            _bluetoothService.InputReceived += OnControllerInputReceived;
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            try
            {
                await _virtualController.InitializeAsync();
                await _webSocketServer.StartAsync(cancellationToken);
                await _bluetoothService.StartAsync(cancellationToken);
                
                _logger.LogInformation("Controller manager started successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start controller manager");
                throw;
            }
        }

        public async Task StopAsync(CancellationToken cancellationToken)
        {
            try
            {
                await _bluetoothService.StopAsync(cancellationToken);
                await _webSocketServer.StopAsync(cancellationToken);
                
                _logger.LogInformation("Controller manager stopped successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error stopping controller manager");
                throw;
            }
        }

        private async void OnControllerInputReceived(object? sender, ControllerInputEventArgs e)
        {
            try
            {
                // Update virtual controller state
                await _virtualController.UpdateControllerState(e.State);

                // Broadcast state to WebSocket clients
                await _webSocketServer.BroadcastAsync(
                    JsonSerializer.Serialize(e.State)
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing controller input");
            }
        }
    }
}