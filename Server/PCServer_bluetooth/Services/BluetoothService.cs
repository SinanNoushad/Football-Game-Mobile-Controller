using InTheHand.Net.Bluetooth;
using InTheHand.Net.Sockets;

namespace FootballController.Services
{
    public class BluetoothService : IBluetoothService
    {
        private readonly BluetoothListener _listener;
        private readonly CancellationTokenSource _cts;
        private readonly ILogger<BluetoothService> _logger;

        public event EventHandler<ControllerInputEventArgs>? InputReceived;

        public BluetoothService(ILogger<BluetoothService> logger)
        {
            _logger = logger;
            _cts = new CancellationTokenSource();
            _listener = new BluetoothListener(BluetoothService.SerialPort);
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            try
            {
                _listener.Start();
                _logger.LogInformation("Bluetooth service started");

                while (!cancellationToken.IsCancellationRequested)
                {
                    var client = await Task.Run(() => _listener.AcceptBluetoothClientAsync(), cancellationToken);
                    _ = HandleClientAsync(client, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Bluetooth service");
                throw;
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _listener.Stop();
            _cts.Cancel();
            return Task.CompletedTask;
        }

        private async Task HandleClientAsync(BluetoothClient client, CancellationToken cancellationToken)
        {
            try
            {
                using var stream = client.GetStream();
                using var reader = new StreamReader(stream);

                while (!cancellationToken.IsCancellationRequested)
                {
                    var data = await reader.ReadLineAsync();
                    if (data == null) break;

                    var input = JsonSerializer.Deserialize<ControllerInput>(data);
                    InputReceived?.Invoke(this, new ControllerInputEventArgs(input));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling Bluetooth client");
            }
            finally
            {
                client.Dispose();
            }
        }
    }
}