namespace FootballController.Services
{
    public interface IBluetoothService
    {
        Task StartAsync(CancellationToken cancellationToken);
        Task StopAsync(CancellationToken cancellationToken);
        event EventHandler<ControllerInputEventArgs> InputReceived;
    }
}