using System;
using System.Collections.Generic;
using System.Drawing;
using System.Net;
using System.Windows.Forms;
using WebSocketSharp;
using WebSocketSharp.Server;
using Newtonsoft.Json;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using PCServer_bluetooth;

namespace PCServer
{
    public partial class Program : Form
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Program());
        }

        private System.ComponentModel.IContainer components = null;
        private Button btnStartServer;
        private Label lblStatus;
        private ListBox lstCommands;
        private Button btnStopServer;
        private Button btnClearLog;
        private TextBox txtPort;
        private Label lblPort;
        private WebSocketServer wssv;
        private ServerAdvertiser advertiser = new ServerAdvertiser();
        private BluetoothControllerServer btServer;

        // NEW: Buttons for Bluetooth control.
        private Button btnStartBluetooth;
        private Button btnStopBluetooth;

        // NEW: Controls for displaying connected controllers.
        private ListBox lstControllers;
        private Button btnKickController;
        private TableLayoutPanel tableLayoutPanelControllers;

        // Layout panels.
        private TableLayoutPanel tableLayoutPanelMain;
        private TableLayoutPanel tableLayoutPanelPort;
        private TableLayoutPanel tableLayoutPanelServer;
        private TableLayoutPanel tableLayoutPanelBluetooth;

        // A static reference to the controllers list (for easy refresh).
        public static ListBox ControllerListBox;

        public Program()
        {
            InitializeComponent();
            // Initialize the Bluetooth server instance.
            btServer = new BluetoothControllerServer();
            btServer.OnCommandReceived += BtServer_OnCommandReceived;
        }

        private void btnStartServer_Click(object sender, EventArgs e)
        {
            try
            {
                int port = 8080;
                int.TryParse(txtPort.Text, out port);

                wssv = new WebSocketServer(IPAddress.Any, port);
                // Pass both the command list and the connected controllers list.
                wssv.AddWebSocketService<ControllerBehavior>("/", () => new ControllerBehavior(lstCommands, lstControllers));

                wssv.Start();
                lblStatus.Text = $"Server started on {GetLocalIPAddress()}:{port}";
                btnStartServer.Enabled = false;

                advertiser.StartAdvertising(port);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error starting server: {ex.Message}");
            }
        }

        private void btnClearLog_Click(object sender, EventArgs e)
        {
            lstCommands.Items.Clear();
        }

        private void btnStopServer_Click(object sender, EventArgs e)
        {
            if (wssv != null && wssv.IsListening)
            {
                wssv.Stop();
                lblStatus.Text = "Server stopped";
                btnStartServer.Enabled = true;

                advertiser.StopAdvertising();
            }
        }

        private void Program_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (wssv != null && wssv.IsListening)
                wssv.Stop();

            advertiser.StopAdvertising();
        }

        private string GetLocalIPAddress()
        {
            var host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                    return ip.ToString();
            }
            return "localhost";
        }

        private void BtServer_OnCommandReceived(string message)
        {
            if (lstCommands.InvokeRequired)
            {
                lstCommands.Invoke(new Action(() =>
                {
                    lstCommands.Items.Add("[BT] " + message);
                    lstCommands.SelectedIndex = lstCommands.Items.Count - 1;
                }));
            }
            else
            {
                lstCommands.Items.Add("[BT] " + message);
                lstCommands.SelectedIndex = lstCommands.Items.Count - 1;
            }
        }

        /// <summary>
        /// Refreshes the connected controllers ListBox based on active sessions.
        /// </summary>
        public static void RefreshControllerList()
        {
            if (ControllerListBox != null)
            {
                if (ControllerListBox.InvokeRequired)
                {
                    ControllerListBox.Invoke(new Action(() => RefreshControllerList()));
                }
                else
                {
                    ControllerListBox.Items.Clear();
                    // Iterate through active controllers and display "Name (ID)"
                    foreach (var entry in ControllerBehavior.ActiveControllers)
                    {
                        ControllerListBox.Items.Add($"{entry.Value.ControllerName} ({entry.Key})");
                    }
                }
            }
        }

        private void InitializeComponent()
        {
            // Set the form's properties for a modern look.
            this.Text = "Controller";
            this.ClientSize = new Size(400, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.Font = new Font("Segoe UI", 10F, FontStyle.Regular);

            // ------------------------------------------------------------------------
            // Initialize TableLayoutPanels
            // ------------------------------------------------------------------------
            tableLayoutPanelMain = new TableLayoutPanel();
            tableLayoutPanelPort = new TableLayoutPanel();
            tableLayoutPanelServer = new TableLayoutPanel();
            tableLayoutPanelBluetooth = new TableLayoutPanel();
            tableLayoutPanelControllers = new TableLayoutPanel();

            // Main panel: 6 rows.
            tableLayoutPanelMain.ColumnCount = 1;
            tableLayoutPanelMain.RowCount = 6;
            tableLayoutPanelMain.Dock = DockStyle.Fill;
            tableLayoutPanelMain.Padding = new Padding(10);
            tableLayoutPanelMain.RowStyles.Clear();
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F)); // Port settings.
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F)); // Server controls.
            //tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 60F)); // Connected controllers.
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 100F)); // Connected controllers.
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 30F)); // Status.
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Percent, 100F)); // Command list.
            tableLayoutPanelMain.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F)); // Bluetooth controls.
            tableLayoutPanelMain.BackColor = Color.Transparent;

            // Port panel: two columns.
            tableLayoutPanelPort.ColumnCount = 2;
            tableLayoutPanelPort.RowCount = 1;
            tableLayoutPanelPort.Dock = DockStyle.Fill;
            tableLayoutPanelPort.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            tableLayoutPanelPort.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            tableLayoutPanelPort.BackColor = Color.Transparent;

            // Server controls panel: three columns.
            tableLayoutPanelServer.ColumnCount = 3;
            tableLayoutPanelServer.RowCount = 1;
            tableLayoutPanelServer.Dock = DockStyle.Fill;
            tableLayoutPanelServer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33F));
            tableLayoutPanelServer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33F));
            tableLayoutPanelServer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33F));
            tableLayoutPanelServer.BackColor = Color.Transparent;

            // Controllers panel: two columns.
            tableLayoutPanelControllers.ColumnCount = 2;
            tableLayoutPanelControllers.RowCount = 1;
            tableLayoutPanelControllers.Dock = DockStyle.Fill;
            tableLayoutPanelControllers.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 80F));
            tableLayoutPanelControllers.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20F));
            tableLayoutPanelControllers.BackColor = Color.Transparent;

            // Bluetooth controls panel: two columns.
            tableLayoutPanelBluetooth.ColumnCount = 2;
            tableLayoutPanelBluetooth.RowCount = 1;
            tableLayoutPanelBluetooth.Dock = DockStyle.Fill;
            tableLayoutPanelBluetooth.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50F));
            tableLayoutPanelBluetooth.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50F));
            tableLayoutPanelBluetooth.BackColor = Color.Transparent;

            // ------------------------------------------------------------------------
            // Create and style controls
            // ------------------------------------------------------------------------
            // Port Label.
            lblPort = new Label();
            lblPort.Text = "Port:";
            lblPort.AutoSize = true;
            lblPort.ForeColor = Color.White;
            lblPort.TextAlign = ContentAlignment.MiddleLeft;
            lblPort.Dock = DockStyle.Fill;

            // Port TextBox.
            txtPort = new TextBox();
            txtPort.Text = "8080";
            txtPort.Dock = DockStyle.Fill;
            txtPort.BackColor = Color.FromArgb(60, 60, 60);
            txtPort.ForeColor = Color.White;
            txtPort.BorderStyle = BorderStyle.FixedSingle;

            // Start Server button.
            btnStartServer = new Button();
            btnStartServer.Text = "Start Server";
            btnStartServer.Dock = DockStyle.Fill;
            StyleButton(btnStartServer, Color.FromArgb(0, 123, 255));
            btnStartServer.Click += new EventHandler(btnStartServer_Click);

            // Stop Server button.
            btnStopServer = new Button();
            btnStopServer.Text = "Stop Server";
            btnStopServer.Dock = DockStyle.Fill;
            StyleButton(btnStopServer, Color.FromArgb(220, 53, 69));
            btnStopServer.Click += new EventHandler(btnStopServer_Click);

            // Clear Log button.
            btnClearLog = new Button();
            btnClearLog.Text = "Clear Log";
            btnClearLog.Dock = DockStyle.Fill;
            StyleButton(btnClearLog, Color.FromArgb(40, 167, 69));
            btnClearLog.Click += new EventHandler(btnClearLog_Click);

            // Status Label.
            lblStatus = new Label();
            lblStatus.Text = "Server not running";
            lblStatus.Dock = DockStyle.Fill;
            lblStatus.ForeColor = Color.White;
            lblStatus.TextAlign = ContentAlignment.MiddleLeft;

            // Command ListBox.
            lstCommands = new ListBox();
            lstCommands.Dock = DockStyle.Fill;
            lstCommands.BackColor = Color.FromArgb(60, 60, 60);
            lstCommands.ForeColor = Color.White;

            // ------------------------------------------------------------------------
            // Create and style controllers display controls.
            // ------------------------------------------------------------------------
            lstControllers = new ListBox();
            lstControllers.Dock = DockStyle.Fill;
            lstControllers.BackColor = Color.FromArgb(60, 60, 60);
            lstControllers.ForeColor = Color.White;
            // Assign static reference so ControllerBehavior can refresh the list.
            ControllerListBox = lstControllers;

            btnKickController = new Button();
            btnKickController.Text = "Kick";
            btnKickController.Dock = DockStyle.Fill;
            StyleButton(btnKickController, Color.FromArgb(220, 53, 69));
            btnKickController.Click += new EventHandler(btnKickController_Click);

            // Add controllers controls to the controllers panel.
            tableLayoutPanelControllers.Controls.Add(lstControllers, 0, 0);
            tableLayoutPanelControllers.Controls.Add(btnKickController, 1, 0);

            // Bluetooth controls.
            btnStartBluetooth = new Button();
            btnStartBluetooth.Text = "Start Bluetooth";
            btnStartBluetooth.Dock = DockStyle.Fill;
            StyleButton(btnStartBluetooth, Color.FromArgb(0, 123, 255));
            btnStartBluetooth.Click += new EventHandler(btnStartBluetooth_Click);

            btnStopBluetooth = new Button();
            btnStopBluetooth.Text = "Stop Bluetooth";
            btnStopBluetooth.Dock = DockStyle.Fill;
            StyleButton(btnStopBluetooth, Color.FromArgb(220, 53, 69));
            btnStopBluetooth.Click += new EventHandler(btnStopBluetooth_Click);

            // ------------------------------------------------------------------------
            // Assemble the layouts
            // ------------------------------------------------------------------------
            // Add controls to the Port panel.
            tableLayoutPanelPort.Controls.Add(lblPort, 0, 0);
            tableLayoutPanelPort.Controls.Add(txtPort, 1, 0);

            // Add controls to the Server controls panel.
            tableLayoutPanelServer.Controls.Add(btnStartServer, 0, 0);
            tableLayoutPanelServer.Controls.Add(btnStopServer, 1, 0);
            tableLayoutPanelServer.Controls.Add(btnClearLog, 2, 0);

            // Add panels and controls to the main layout panel.
            tableLayoutPanelMain.Controls.Add(tableLayoutPanelPort, 0, 0);         // Row 0: Port settings.
            tableLayoutPanelMain.Controls.Add(tableLayoutPanelServer, 0, 1);       // Row 1: Server controls.
            tableLayoutPanelMain.Controls.Add(tableLayoutPanelControllers, 0, 2);  // Row 2: Connected controllers.
            tableLayoutPanelMain.Controls.Add(lblStatus, 0, 3);                    // Row 3: Status label.
            tableLayoutPanelMain.Controls.Add(lstCommands, 0, 4);                  // Row 4: Command log.
            tableLayoutPanelMain.Controls.Add(tableLayoutPanelBluetooth, 0, 5);      // Row 5: Bluetooth controls.

            // Add controls to the Bluetooth controls panel.
            tableLayoutPanelBluetooth.Controls.Add(btnStartBluetooth, 0, 0);
            tableLayoutPanelBluetooth.Controls.Add(btnStopBluetooth, 1, 0);

            // Add the main layout to the form.
            this.Controls.Add(tableLayoutPanelMain);

            this.FormClosing += new FormClosingEventHandler(Program_FormClosing);
        }

        /// <summary>
        /// Applies a modern flat style with custom colors to a button.
        /// </summary>
        private void StyleButton(Button btn, Color backColor)
        {
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 0;
            btn.BackColor = backColor;
            btn.ForeColor = Color.White;
            btn.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            btn.Cursor = Cursors.Hand;
            btn.MouseEnter += (s, e) => btn.BackColor = ControlPaint.Light(backColor);
            btn.MouseLeave += (s, e) => btn.BackColor = backColor;
        }

        private void btnStartBluetooth_Click(object sender, EventArgs e)
        {
            try
            {
                btServer.Start();
                lstCommands.Items.Add("Bluetooth server started.");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error starting Bluetooth server: " + ex.Message);
            }
        }

        private void btnStopBluetooth_Click(object sender, EventArgs e)
        {
            try
            {
                btServer.Stop();
                lstCommands.Items.Add("Bluetooth server stopped.");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error stopping Bluetooth server: " + ex.Message);
            }
        }

        private void btnKickController_Click(object sender, EventArgs e)
        {
            if (lstControllers.SelectedItem != null)
            {
                string selected = lstControllers.SelectedItem.ToString();
                // Expecting format "ControllerName (ControllerId)"
                int start = selected.IndexOf('(');
                int end = selected.IndexOf(')');
                if (start >= 0 && end > start)
                {
                    string controllerId = selected.Substring(start + 1, end - start - 1);
                    if (ControllerBehavior.ActiveControllers.TryGetValue(controllerId, out var behavior))
                    {
                        // Close the WebSocket connection to kick the controller.
                        behavior.Context.WebSocket.Close();
                    }
                }
            }
        }
    }

    // Command class to deserialize incoming JSON commands.
    public class Command
    {
        [JsonProperty("action")]
        public string Action { get; set; }

        [JsonProperty("timestamp")]
        public long Timestamp { get; set; }
    }

    // Our WebSocket behavior that uses ViGEm exclusively.
    public class ControllerBehavior : WebSocketBehavior
    {
        // Maintain active controller sessions.
        public static Dictionary<string, ControllerBehavior> ActiveControllers = new Dictionary<string, ControllerBehavior>();

        private string _controllerName = "Unknown";
        private string _controllerId = string.Empty;
        private ListBox lstCommands;
        private VirtualController virtualController;
        private ListBox lstControllers;

        public string ControllerName { get { return _controllerName; } }

        public ControllerBehavior(ListBox commandsList, ListBox controllersList)
        {
            lstCommands = commandsList;
            lstControllers = controllersList;
            virtualController = new VirtualController();
        }

        protected override void OnOpen()
        {
            base.OnOpen();
            UpdateCommandList("Client connected, waiting for identification...");
        }

        protected override void OnMessage(MessageEventArgs e)
        {
            ControllerCommand command;
            try
            {
                command = JsonConvert.DeserializeObject<ControllerCommand>(e.Data);
            }
            catch (Exception ex)
            {
                UpdateCommandList("Error parsing command: " + ex.Message);
                return;
            }

            if (command.Action == "connect")
            {
                _controllerName = command.ControllerName;
                _controllerId = command.ControllerId;

                if (!ActiveControllers.ContainsKey(command.ControllerId))
                {
                    ActiveControllers.Add(command.ControllerId, this);
                    UpdateCommandList($"{command.ControllerName} connected.");
                }
                else
                {
                    ActiveControllers[command.ControllerId] = this;
                    UpdateCommandList($"{command.ControllerName} reconnected.");
                }
                Program.RefreshControllerList();
            }
            else
            {
                // For other commands, update sessions if needed.
            }

            HandleCommand(command);
        }

        protected override void OnClose(CloseEventArgs e)
        {
            base.OnClose(e);
            if (!string.IsNullOrWhiteSpace(_controllerName))
            {
                UpdateCommandList($"{_controllerName} disconnected.");
            }
            else
            {
                UpdateCommandList("Client disconnected.");
            }

            if (!string.IsNullOrWhiteSpace(_controllerId) && ActiveControllers.ContainsKey(_controllerId))
            {
                ActiveControllers.Remove(_controllerId);
                Program.RefreshControllerList();
            }
        }

        private void UpdateCommandList(string message)
        {
            Console.WriteLine(message);
            if (lstCommands.InvokeRequired)
            {
                lstCommands.Invoke(new Action(() =>
                {
                    lstCommands.Items.Add(message);
                    lstCommands.SelectedIndex = lstCommands.Items.Count - 1;
                }));
            }
            else
            {
                lstCommands.Items.Add(message);
                lstCommands.SelectedIndex = lstCommands.Items.Count - 1;
            }
        }

        private void HandleCommand(ControllerCommand command)
        {
            //UpdateCommandList($"Action: {command.Action}");

            // Process joystick movement command: "move_x_y" where x and y are floats (-1 to 1)
            if (command.Action.StartsWith("move_"))
            {
                var parts = command.Action.Split('_');
                if (parts.Length == 3)
                {
                    if (float.TryParse(parts[1], out float x) && float.TryParse(parts[2], out float y))
                    {
                        virtualController.SimulateLeftJoystickMovement(x, y);
                        //UpdateCommandList($"Joystick moved to x: {x}, y: {y}");
                    }
                    else
                    {
                        UpdateCommandList("Invalid joystick coordinates.");
                    }
                }
            }
            else if (command.Action.StartsWith("camera_"))
            {
                var parts = command.Action.Split('_');
                if (parts.Length == 3)
                {
                    if (float.TryParse(parts[1], out float x) && float.TryParse(parts[2], out float y))
                    {
                        virtualController.SimulateRightJoystickMovement(x, y);
                        //UpdateCommandList($"Joystick moved to x: {x}, y: {y}");
                    }
                    else
                    {
                        UpdateCommandList("Invalid joystick coordinates.");
                    }
                }

            }
            else
            {
                switch (command.Action)
                {
                    case "short_pass_pressed":
                        virtualController.PressButtonHold(Xbox360Button.A);
                        break;
                    case "short_pass_released":
                        virtualController.ReleaseButton(Xbox360Button.A);
                        break;
                    case "standard_shot_pressed":
                        virtualController.PressButtonHold(Xbox360Button.B);
                        break;
                    case "standard_shot_released":
                        virtualController.ReleaseButton(Xbox360Button.B);
                        break;
                    case "power_shot_pressed":
                        virtualController.PressButtonHold(Xbox360Button.B);
                        break;
                    case "power_shot_released":
                        virtualController.ReleaseButton(Xbox360Button.B);
                        break;
                    case "chip_shot_pressed":
                        virtualController.PressButtonHold(Xbox360Button.LeftShoulder);
                        virtualController.PressButtonHold(Xbox360Button.B);
                        break;

                    case "chip_shot_released":
                        virtualController.ReleaseButton(Xbox360Button.B);
                        virtualController.ReleaseButton(Xbox360Button.LeftShoulder);
                        break;

                    case "finesse_shot_pressed":
                        virtualController.PressButtonHold(Xbox360Button.RightShoulder);
                        virtualController.PressButtonHold(Xbox360Button.B);
                        break;

                    case "finesse_shot_released":
                        virtualController.ReleaseButton(Xbox360Button.B);
                        virtualController.ReleaseButton(Xbox360Button.RightShoulder);
                        break;
                    case "stunning_shot_pressed":
                        virtualController.PressButtonHold(Xbox360Button.LeftShoulder);
                        virtualController.PressButtonHold(Xbox360Button.RightShoulder);
                        virtualController.PressButtonHold(Xbox360Button.B);
                        break;

                    case "stunning_shot_released":
                        virtualController.ReleaseButton(Xbox360Button.B);
                        virtualController.ReleaseButton(Xbox360Button.LeftShoulder);
                        virtualController.ReleaseButton(Xbox360Button.RightShoulder);
                        break;

                    case "standard_through_ball_pressed":
                        virtualController.PressButtonHold(Xbox360Button.Y);
                        break;
                    case "standard_through_ball_released":
                        virtualController.ReleaseButton(Xbox360Button.Y);
                        break;
                    case "goalkeeper_rush_pressed":
                        virtualController.PressButtonHold(Xbox360Button.Y);
                        break;
                    case "goalkeeper_rush_released":
                        virtualController.ReleaseButton(Xbox360Button.Y);
                        break;
                    case "hard_slide_tackle_pressed":
                        virtualController.PressButtonHold(Xbox360Button.RightShoulder);
                        virtualController.PressButtonHold(Xbox360Button.X);
                        break;
                    case "hard_slide_tackle_released":
                        virtualController.ReleaseButton(Xbox360Button.RightShoulder);
                        virtualController.ReleaseButton(Xbox360Button.X);
                        break;
                    case "lobbed_through_ball_pressed":
                        virtualController.PressButtonHold(Xbox360Button.X);
                        break;
                    case "lobbed_through_ball_released":
                        virtualController.ReleaseButton(Xbox360Button.X);
                        break;
                    case "start_sprint_pressed":
                        virtualController.SetRightTrigger(255);
                        break;
                    case "start_sprint_released":
                        virtualController.SetRightTrigger(0);
                        break;
                    case "left_trigger_pressed":
                        virtualController.SetLeftTrigger(255);
                        break;
                    case "left_trigger_released":
                        virtualController.SetLeftTrigger(0);
                        break;
                    case "right_trigger_pressed":
                        virtualController.SetRightTrigger(255);
                        break;
                    case "right_trigger_released":
                        virtualController.SetRightTrigger(0);
                        break;
                    case "left_bumper_pressed":
                        virtualController.PressButtonHold(Xbox360Button.LeftShoulder);
                        break;
                    case "left_bumper_released":
                        virtualController.ReleaseButton(Xbox360Button.LeftShoulder);
                        break;
                    case "right_bumper_pressed":
                        virtualController.PressButtonHold(Xbox360Button.RightShoulder);
                        break;
                    case "right_bumper_released":
                        virtualController.ReleaseButton(Xbox360Button.RightShoulder);
                        break;
                    case "dpad_up":
                        virtualController.PressButton(Xbox360Button.Up);
                        break;
                    case "dpad_down":
                        virtualController.PressButton(Xbox360Button.Down);
                        break;
                    case "dpad_left":
                        virtualController.PressButton(Xbox360Button.Left);
                        break;
                    case "dpad_right":
                        virtualController.PressButton(Xbox360Button.Right);
                        break;
                    case "start_pressed":
                        virtualController.PressButtonHold(Xbox360Button.Start);
                        break;
                    case "start_released":
                        virtualController.ReleaseButton(Xbox360Button.Start);
                        break;
                    case "select_pressed":
                        virtualController.PressButtonHold(Xbox360Button.Back);
                        break;
                    case "select_released":
                        virtualController.ReleaseButton(Xbox360Button.Back);
                        break;
                    case "Switch_player_pressed":
                        virtualController.PressButton(Xbox360Button.LeftShoulder);
                        break;
                    case "Switch_player_released":
                        virtualController.ReleaseButton(Xbox360Button.LeftShoulder);
                        break;
                    // Add more cases for different actions

                    default:
                        if (command.Action != "connect")
                        {
                            UpdateCommandList($"Unknown action: {command.Action}");
                        }
                        break;
                }
            }
        }
    }

    public class ControllerCommand
    {
        [JsonProperty("action")]
        public string Action { get; set; }

        [JsonProperty("timestamp")]
        public long Timestamp { get; set; }

        [JsonProperty("controllerName")]
        public string ControllerName { get; set; }

        [JsonProperty("controllerId")]
        public string ControllerId { get; set; }
    }
}
