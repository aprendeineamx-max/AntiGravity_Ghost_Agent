$ErrorActionPreference = "Continue"

# Define Paths
$WPFPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF"
try {
    Add-Type -Path "$WPFPath\UIAutomationClient.dll"
    Add-Type -Path "$WPFPath\UIAutomationTypes.dll"
    Write-Host "UIAutomation DLLs loaded."
} catch {
    Write-Host "Failed to load UIAutomation DLLs: $_"
}

$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation;
using System.Windows;
using System.IO;
using System.Windows.Forms; 

namespace OmniControl {
    public class Backend {
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        [DllImport("gdi32.dll")] static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
        
        public static double GetScaleFactor() {
            IntPtr desktop = GetWindowDC(IntPtr.Zero);
            int logicalHeight = GetDeviceCaps(desktop, 117); // VERTRES
            int physicalHeight = GetDeviceCaps(desktop, 10); // DESKTOPVERTRES
            ReleaseDC(IntPtr.Zero, desktop);
            return (double)physicalHeight / (double)logicalHeight;
        }

        public static string GetActiveWindowTitle() {
            const int nChars = 256;
            StringBuilder Buff = new StringBuilder(nChars);
            IntPtr handle = GetForegroundWindow();
            if (GetWindowText(handle, Buff, nChars) > 0) return Buff.ToString();
            return "";
        }
        
        public static RECT GetActiveWindowRectStruct() {
            IntPtr handle = GetForegroundWindow();
            RECT r;
            GetWindowRect(handle, out r);
            return r;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime;
        }

        // --- ZONE DATA ---
        public static int ZoneX = 0, ZoneY = 0, ZoneW = 9999, ZoneH = 9999;
        
        public static void UpdateZone(int x, int y, int w, int h) {
            ZoneX = x; ZoneY = y; ZoneW = w; ZoneH = h;
        }

        public static bool IsUserIdle(int thresholdMs) {
            var lastInput = new LASTINPUTINFO();
            lastInput.cbSize = (uint)Marshal.SizeOf(lastInput);
            if (!GetLastInputInfo(ref lastInput)) return false; // Fail safe
            
            uint idleTime = (uint)Environment.TickCount - lastInput.dwTime;
            return idleTime > thresholdMs;
        }

        public static void Log(string msg) {
            try {
                System.IO.File.AppendAllText(@"C:\AntiGravityExt\OmniControl_Debug.txt", 
                    DateTime.Now.ToString("HH:mm:ss.fff") + " " + msg + Environment.NewLine);
            } catch {}
        }

        [DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        [DllImport("user32.dll")] static extern IntPtr GetWindowDC(IntPtr hWnd);
        [DllImport("gdi32.dll")] static extern uint GetPixel(IntPtr hdc, int nXPos, int nYPos);
        [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
        [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hWnd);
        
        // ** ADDED MISSING SW CONSTANTS FOR COMPILER TEST **
        private const int SW_RESTORE = 9;
        private const int SW_MINIMIZE = 6;

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

        public static System.Drawing.Point? FindSmartBlueButton(IntPtr hWnd) {
            RECT rect;
            GetWindowRect(hWnd, out rect);
            int w = rect.Right - rect.Left;
            int h = rect.Bottom - rect.Top;
            if (w <= 0 || h <= 0) return null;

            IntPtr hdc = GetWindowDC(hWnd);
            try {
                int safeZoneX = (int)(w * 0.65); 
                int step = 5; 
                for (int y = 100; y < h - 20; y += step) {
                    for (int x = safeZoneX; x < w - 20; x += step) {
                        uint pixel = GetPixel(hdc, x, y);
                        // Convert ABGR to RGB
                        int r = (int)(pixel & 0xFF);
                        int g = (int)((pixel >> 8) & 0xFF);
                        int b = (int)((pixel >> 16) & 0xFF);

                        if (r < 90 && g > 80 && g < 180 && b > 130) {
                            
                            int btnWidth = 0;
                            while (btnWidth < 300) { 
                                uint p2 = GetPixel(hdc, x + btnWidth, y);
                                int b2 = (int)((p2 >> 16) & 0xFF);
                                if (b2 < 130) break; // Use same relaxed threshold
                                btnWidth += 5;
                            }

                            int btnHeight = 0;
                            while (btnHeight < 80) {
                                uint p3 = GetPixel(hdc, x, y + btnHeight);
                                int b3 = (int)((p3 >> 16) & 0xFF);
                                if (b3 < 130) break;
                                btnHeight += 5;
                            }

                            if (btnWidth >= 60 && btnHeight >= 15) {
                                Log("SMART TARGET LOCATED: " + (rect.Left + x) + "," + (rect.Top + y) + " (Size: " + btnWidth + "x" + btnHeight + ")");
                                return new System.Drawing.Point(rect.Left + x + (btnWidth/2), rect.Top + y + (btnHeight/2));
                            }
                        }
                    }
                }
            } finally {
                ReleaseDC(hWnd, hdc);
            }
            return null;
        }

        public static string ScanAndDestroy(string titlePart) {
             return "Compiled OK";
        }
        
        [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
        public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
        private const int MOUSEEVENTF_LEFTDOWN = 0x02;
        private const int MOUSEEVENTF_LEFTUP = 0x04;
        private const int MOUSEEVENTF_ABSOLUTE = 0x8000;

        public static void ClickAt(int x, int y) {
             System.Windows.Forms.Cursor.Position = new System.Drawing.Point(x, y);
             mouse_event(MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP, (uint)x, (uint)y, 0, 0);
        }
    }
}
"@

try {
    # Using specific Referencies matching production
    Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies UIAutomationClient, UIAutomationTypes, WindowsBase, PresentationCore, PresentationFramework, System.Windows.Forms, System.Drawing
    Write-Host "COMPILATION SUCCESS" -ForegroundColor Green
} catch {
    Write-Host "COMPILATION FAILED:" -ForegroundColor Red
    $_.Exception.LoaderExceptions | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
    if (!$_.Exception.LoaderExceptions) { Write-Host $_.Exception.Message -ForegroundColor Red }
}
