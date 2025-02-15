using Makaretu.Dns;
using System;

namespace PCServer_bluetooth
{
    public class ServerAdvertiser : IDisposable
    {
        private MulticastService mdns;
        private ServiceDiscovery serviceDiscovery;
        private ServiceProfile service;

        public ServerAdvertiser()
        {
            mdns = new MulticastService();
            serviceDiscovery = new ServiceDiscovery(mdns);
            mdns.Start();
        }

        public void StartAdvertising(int port)
        {
            try
            {
                service = new ServiceProfile(
                    Environment.MachineName,    // Service name
                    "_pcserver._tcp",           // Service type
                    (ushort)port                // WebSocket port
                );
                service.AddProperty("version", "1.0");
                service.AddProperty("type", "gamecontroller");
                serviceDiscovery.Advertise(service);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error starting mDNS advertising: {ex.Message}");
            }
        }

        public void StopAdvertising()
        {
            try
            {
                if (service != null)
                {
                    serviceDiscovery.Unadvertise(service);
                    service = null;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error stopping mDNS advertising: {ex.Message}");
            }
        }

        public void Dispose()
        {
            StopAdvertising();
            mdns?.Dispose();
            serviceDiscovery?.Dispose();
        }
    }
}