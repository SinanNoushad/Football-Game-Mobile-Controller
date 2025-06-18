namespace FootballController.Services
{
    public interface IVirtualController
    {
        Task InitializeAsync();
        Task UpdateControllerState(ControllerState state);
        Task SetVibration(double leftMotor, double rightMotor);
    }
}