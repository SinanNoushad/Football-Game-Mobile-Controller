namespace FootballController.Services
{
    public interface IWebSocketServer
    {
        Task StartAsync(CancellationToken cancellationToken);
        Task StopAsync(CancellationToken cancellationToken);
        Task BroadcastAsync(string message);
    }
}