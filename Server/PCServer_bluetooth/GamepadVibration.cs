using SharpDX.XInput;

public class GamepadVibration
{
    private Controller controller;

    public GamepadVibration()
    {
        controller = new Controller(UserIndex.One); // You can change the user index if needed
    }

    public void SetVibration(float leftMotor, float rightMotor)
    {
        if (controller.IsConnected)
        {
            Vibration vibration = new Vibration
            {
                LeftMotorSpeed = (ushort)(leftMotor * 65535),   // Scale from 0 to 65535
                RightMotorSpeed = (ushort)(rightMotor * 65535)  // Scale from 0 to 65535
            };

            controller.SetVibration(vibration);
        }
    }

    public void StopVibration()
    {
        if (controller.IsConnected)
        {
            controller.SetVibration(new Vibration()); // Set to 0 to stop vibration
        }
    }
}
