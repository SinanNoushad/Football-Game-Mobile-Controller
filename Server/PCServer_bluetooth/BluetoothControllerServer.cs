using System;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using InTheHand.Net;
using InTheHand.Net.Bluetooth;
using InTheHand.Net.Sockets;
using Newtonsoft.Json;
using PCServer_bluetooth;

namespace PCServer
{
    public class BluetoothControllerServer
    {
        private readonly Guid ServiceUuid = new Guid("00001101-0000-1000-8000-00805F9B34FB");
        private BluetoothListener btListener;
        private Thread listeningThread;
        private bool running;

        public event Action<string> OnCommandReceived;

        public void Start()
        {
            try
            {
                btListener = new BluetoothListener(ServiceUuid)
                {
                    ServiceName = "PCBluetoothController"
                };
                btListener.Start();
                running = true;
                listeningThread = new Thread(ListenForClients)
                {
                    IsBackground = true
                };
                listeningThread.Start();
            }
            catch (Exception ex)
            {
                throw new Exception("Error starting Bluetooth server: " + ex.Message, ex);
            }
        }

        private void ListenForClients()
        {
            while (running)
            {
                try
                {
                    BluetoothClient client = btListener.AcceptBluetoothClient();
                    ThreadPool.QueueUserWorkItem(HandleClient, client);
                }
                catch (SocketException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    OnCommandReceived?.Invoke("Error accepting Bluetooth client: " + ex.Message);
                }
            }
        }

        private void HandleClient(object clientObj)
        {
            BluetoothClient client = (BluetoothClient)clientObj;
            try
            {
                using (NetworkStream stream = client.GetStream())
                {
                    byte[] buffer = new byte[1024];
                    int bytesRead;
                    while (running && (bytesRead = stream.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        string json = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                        OnCommandReceived?.Invoke(json);
                        ProcessCommand(json);
                    }
                }
            }
            catch (Exception ex)
            {
                OnCommandReceived?.Invoke("Error handling Bluetooth client: " + ex.Message);
            }
            finally
            {
                client.Close();
            }
        }

        private void ProcessCommand(string json)
        {
            try
            {
                ControllerCommand command = JsonConvert.DeserializeObject<ControllerCommand>(json);
                if (command.Action == "connect")
                {
                    if (ControllerManager.Exists(command.ControllerId))
                    {
                        ControllerManager.UpdateSession(command.ControllerId, command.ControllerName);
                        OnCommandReceived?.Invoke($"[BT] Returning controller [{command.ControllerName}] connected.");
                    }
                    else
                    {
                        ControllerManager.AddSession(new ControllerSession
                        {
                            ControllerId = command.ControllerId,
                            ControllerName = command.ControllerName,
                            LastSeen = DateTime.Now
                        });
                        OnCommandReceived?.Invoke($"[BT] New controller [{command.ControllerName}] connected.");
                    }
                }
                else
                {
                    if (!string.IsNullOrWhiteSpace(command.ControllerId))
                    {
                        ControllerManager.UpdateSession(command.ControllerId, command.ControllerName);
                    }
                    OnCommandReceived?.Invoke($"[BT][{command.ControllerName}] Command Received: {command.Action}");
                }
            }
            catch (Exception ex)
            {
                OnCommandReceived?.Invoke("Error processing Bluetooth command: " + ex.Message);
            }
        }

        public void Stop()
        {
            try
            {
                running = false;
                btListener?.Stop();
                if (listeningThread != null && listeningThread.IsAlive)
                {
                    listeningThread.Join();
                }
            }
            catch (Exception ex)
            {
                OnCommandReceived?.Invoke("Error stopping Bluetooth server: " + ex.Message);
            }
        }
    }
}
