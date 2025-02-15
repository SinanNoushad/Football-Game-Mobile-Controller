using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public class VirtualController
{
    private ViGEmClient client;
    private IXbox360Controller controller;
    private System.Collections.Generic.HashSet<Xbox360Button> pressedButtons = new System.Collections.Generic.HashSet<Xbox360Button>();

    public VirtualController()
    {
        client = new ViGEmClient();
        controller = client.CreateXbox360Controller();
        controller.Connect();
    }


    public void PressButton(Xbox360Button button, int pressDuration = 50)
    {
        if (!pressedButtons.Contains(button))
        {
            controller.SetButtonState(button, true);
            pressedButtons.Add(button);
            Thread.Sleep(pressDuration);
            ReleaseButton(button);
        }
    }


    public void PressButtonHold(Xbox360Button button)
    {
        if (!pressedButtons.Contains(button))
        {
            controller.SetButtonState(button, true);
            pressedButtons.Add(button);
        }
    }

    public void ReleaseButton(Xbox360Button button)
    {
        if (pressedButtons.Contains(button))
        {
            controller.SetButtonState(button, false);
            pressedButtons.Remove(button);
        }
    }


    public void SimulateLeftJoystickMovement(float x, float y)
    {
        short mappedX = (short)(x * 32767);
        short mappedY = (short)(y * -32767); // Invert Y for correct mapping.
        controller.SetAxisValue(Xbox360Axis.LeftThumbX, mappedX);
        controller.SetAxisValue(Xbox360Axis.LeftThumbY, mappedY);
    }
    public void SimulateRightJoystickMovement(float x, float y)
    {
        short mappedX = (short)(x * 32767);
        short mappedY = (short)(y * -32767); // Invert Y for correct mapping.
        controller.SetAxisValue(Xbox360Axis.RightThumbX, mappedX);
        controller.SetAxisValue(Xbox360Axis.RightThumbY, mappedY);
    }


    public void SetLeftTrigger(byte value)
    {
        controller.SetSliderValue(Xbox360Slider.LeftTrigger, value);
    }


    public void SetRightTrigger(byte value)
    {
        controller.SetSliderValue(Xbox360Slider.RightTrigger, value);
    }

    public void Shutdown()
    {
        controller.Disconnect();
    }
}
