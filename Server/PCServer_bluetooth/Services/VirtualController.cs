using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using Microsoft.Extensions.Options;
using FootballController.Configuration;

namespace FootballController.Services
{
    public class VirtualController : IVirtualController, IDisposable
    {
        private readonly ILogger<VirtualController> _logger;
        private readonly ViGEmClient _client;
        private IXbox360Controller _controller;
        private bool _isInitialized;

        public VirtualController(IOptions<ServerConfig> config, ILogger<VirtualController> logger)
        {
            _logger = logger;
            _client = new ViGEmClient();
            _controller = _client.CreateXbox360Controller();
        }

        public async Task InitializeAsync()
        {
            if (_isInitialized) return;

            try
            {
                _controller.Connect();
                _isInitialized = true;
                _logger.LogInformation("Virtual controller initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize virtual controller");
                throw;
            }
        }

        public Task UpdateControllerState(ControllerState state)
        {
            if (!_isInitialized)
            {
                throw new InvalidOperationException("Controller not initialized");
            }

            try
            {
                // Update buttons
                _controller.SetButtonState(Xbox360Button.A, state.ButtonA);
                _controller.SetButtonState(Xbox360Button.B, state.ButtonB);
                _controller.SetButtonState(Xbox360Button.X, state.ButtonX);
                _controller.SetButtonState(Xbox360Button.Y, state.ButtonY);

                // Update triggers
                _controller.SetSliderValue(Xbox360Slider.LeftTrigger, state.LeftTrigger);
                _controller.SetSliderValue(Xbox360Slider.RightTrigger, state.RightTrigger);

                // Update thumbsticks
                _controller.SetAxisValue(Xbox360Axis.LeftThumbX, state.LeftStickX);
                _controller.SetAxisValue(Xbox360Axis.LeftThumbY, state.LeftStickY);
                _controller.SetAxisValue(Xbox360Axis.RightThumbX, state.RightStickX);
                _controller.SetAxisValue(Xbox360Axis.RightThumbY, state.RightStickY);

                // Update D-pad
                _controller.SetDPadDirection(state.DPadDirection);

                return Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update controller state");
                throw;
            }
        }

        public Task SetVibration(double leftMotor, double rightMotor)
        {
            if (!_isInitialized)
            {
                throw new InvalidOperationException("Controller not initialized");
            }

            try
            {
                _controller.SetVibration(
                    (byte)(leftMotor * 255), 
                    (byte)(rightMotor * 255)
                );
                return Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to set vibration");
                throw;
            }
        }

        public void Dispose()
        {
            try
            {
                if (_isInitialized)
                {
                    _controller.Disconnect();
                }
                _client?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error disposing virtual controller");
            }
        }
    }
}