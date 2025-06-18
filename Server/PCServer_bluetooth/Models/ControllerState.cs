namespace FootballController.Models
{
    public class ControllerState
    {
        // Buttons
        public bool ButtonA { get; set; }
        public bool ButtonB { get; set; }
        public bool ButtonX { get; set; }
        public bool ButtonY { get; set; }
        
        // Triggers (0-255)
        public byte LeftTrigger { get; set; }
        public byte RightTrigger { get; set; }
        
        // Thumbsticks (-32768 to 32767)
        public short LeftStickX { get; set; }
        public short LeftStickY { get; set; }
        public short RightStickX { get; set; }
        public short RightStickY { get; set; }
        
        // D-pad
        public DPadDirection DPadDirection { get; set; }
    }

    public enum DPadDirection
    {
        None,
        Up,
        Down,
        Left,
        Right,
        UpLeft,
        UpRight,
        DownLeft,
        DownRight
    }
}