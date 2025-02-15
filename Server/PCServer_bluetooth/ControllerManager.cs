using System;
using System.Collections.Generic;

namespace PCServer_bluetooth
{
    public class ControllerSession
    {
        public string ControllerId { get; set; }
        public string ControllerName { get; set; }
        public DateTime LastSeen { get; set; }

    }

    public static class ControllerManager
    {
        // A simple in-memory dictionary to track sessions.
        private static Dictionary<string, ControllerSession> sessions = new Dictionary<string, ControllerSession>();


        public static bool Exists(string controllerId)
        {
            return sessions.ContainsKey(controllerId);
        }


        public static void AddSession(ControllerSession session)
        {
            sessions[session.ControllerId] = session;
        }

        public static void UpdateSession(string controllerId, string controllerName)
        {
            if (sessions.ContainsKey(controllerId))
            {
                sessions[controllerId].ControllerName = controllerName;
                sessions[controllerId].LastSeen = DateTime.Now;
            }
        }


        public static void CleanupSessions(TimeSpan timeout)
        {
            var now = DateTime.Now;
            var keysToRemove = new List<string>();
            foreach (var kvp in sessions)
            {
                if (now - kvp.Value.LastSeen > timeout)
                {
                    keysToRemove.Add(kvp.Key);
                }
            }
            foreach (var key in keysToRemove)
            {
                sessions.Remove(key);
            }
        }
    }
}
