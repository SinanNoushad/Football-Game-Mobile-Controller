namespace FootballController.Configuration
{
    public class ServerConfig
    {
        public int WebSocketPort { get; set; } = 8080;
        public string BluetoothServiceName { get; set; } = "Football Controller";
        public int VirtualControllerIndex { get; set; } = 1;
    }
}