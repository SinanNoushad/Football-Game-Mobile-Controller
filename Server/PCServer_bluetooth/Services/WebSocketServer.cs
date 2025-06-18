using WebSocketSharp.Server;
using Microsoft.Extensions.Options;
using FootballController.Configuration;

namespace FootballController.Services
{
    public class WebSocketServer : IWebSocketServer
    {
        private readonly WebSocketSharp.Server.WebSocketServer _server;
        private readonly ILogger<WebSocketServer> _logger;

        public WebSocketServer(IOptions<ServerConfig> config, ILogger<WebSocketServer> logger)
        {
            _logger = logger;
            _server = new WebSocketSharp.Server.WebSocketServer(config.Value.WebSocketPort);
            _server.AddWebSocketService<ControllerWebSocketBehavior>("/controller");
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _server.Start();
            _logger.LogInformation("WebSocket server started on port {Port}", _server.Port);
            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _server.Stop();
            return Task.CompletedTask;
        }

        public Task BroadcastAsync(string message)
        {
            _server.WebSocketServices["/controller"].Sessions.Broadcast(message);
            return Task.CompletedTask;
        }
    }
}