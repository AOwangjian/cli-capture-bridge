using System.Collections.Specialized;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows.Forms;

namespace ScreenshotListenerAssistant;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new TrayAppContext());
    }
}

internal sealed class TrayAppContext : ApplicationContext
{
    private const string MarkerFormat = "ScreenshotListener.ByCodex";
    private const string AppName = "截图监听助手";

    private readonly NotifyIcon _notifyIcon;
    private readonly System.Windows.Forms.Timer _timer;
    private readonly ToolStripMenuItem _statusItem;
    private readonly ToolStripMenuItem _toggleItem;

    private bool _enabled = true;
    private bool _ignoreNextClipboardChange;
    private uint _lastSeq;
    private int _savedCount;
    private string _lastSavedPath = string.Empty;

    private readonly string _configDir;
    private readonly string _configPath;
    private AppConfig _config;

    public TrayAppContext()
    {
        _configDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ScreenshotListenerAssistant");
        _configPath = Path.Combine(_configDir, "config.json");
        _config = LoadConfig();

        EnsureSaveDirectory();

        _notifyIcon = new NotifyIcon
        {
            Icon = BuildTrayIcon(),
            Visible = true,
            Text = $"{AppName}: 运行中"
        };

        var menu = new ContextMenuStrip();
        _statusItem = new ToolStripMenuItem("状态: 运行中") { Enabled = false };
        _toggleItem = new ToolStripMenuItem("暂停监听", null, (_, _) => ToggleEnabled());
        var setFolderItem = new ToolStripMenuItem("设置保存目录", null, (_, _) => SetSaveDirectory());
        var openFolderItem = new ToolStripMenuItem("打开保存目录", null, (_, _) => OpenSaveDirectory());
        var copyLastPathItem = new ToolStripMenuItem("复制最后路径", null, (_, _) => CopyLastPath());
        var startupItem = new ToolStripMenuItem("开机启动", null, (_, _) => ToggleStartup())
        {
            Checked = IsStartupEnabled(),
            CheckOnClick = false
        };
        var exitItem = new ToolStripMenuItem("退出", null, (_, _) => ExitApp());

        menu.Items.AddRange([
            _statusItem,
            _toggleItem,
            new ToolStripSeparator(),
            setFolderItem,
            openFolderItem,
            copyLastPathItem,
            new ToolStripSeparator(),
            startupItem,
            new ToolStripSeparator(),
            exitItem
        ]);

        _notifyIcon.ContextMenuStrip = menu;
        _notifyIcon.DoubleClick += (_, _) => OpenSaveDirectory();

        _timer = new System.Windows.Forms.Timer { Interval = 250 };
        _timer.Tick += (_, _) => OnTick();
        _timer.Start();
    }

    private void OnTick()
    {
        if (!_enabled)
        {
            return;
        }

        try
        {
            var seq = NativeMethods.GetClipboardSequenceNumber();
            if (seq == _lastSeq)
            {
                return;
            }

            _lastSeq = seq;
            if (_ignoreNextClipboardChange)
            {
                _ignoreNextClipboardChange = false;
                return;
            }

            if (Clipboard.ContainsData(MarkerFormat) || !Clipboard.ContainsImage())
            {
                return;
            }

            using var image = Clipboard.GetImage();
            if (image is null)
            {
                return;
            }

            using var bitmap = new Bitmap(image);
            var fileName = DateTime.Now.ToString("yyyyMMdd_HHmmss_fff") + ".png";
            var fullPath = Path.Combine(_config.SaveDirectory, fileName);
            bitmap.Save(fullPath, System.Drawing.Imaging.ImageFormat.Png);

            var data = new DataObject();
            data.SetData(MarkerFormat, true);
            data.SetData(DataFormats.UnicodeText, fullPath);
            data.SetData(DataFormats.Text, fullPath);
            var files = new StringCollection { fullPath };
            data.SetFileDropList(files);
            data.SetImage(bitmap);
            _ignoreNextClipboardChange = true;
            Clipboard.SetDataObject(data, true);

            _savedCount++;
            _lastSavedPath = fullPath;
            _statusItem.Text = $"状态: 运行中 (已保存 {_savedCount} 张)";
            _notifyIcon.BalloonTipTitle = AppName;
            _notifyIcon.BalloonTipText = Path.GetFileName(fullPath);
            _notifyIcon.ShowBalloonTip(1200);
        }
        catch
        {
            // Clipboard might be locked by another process.
        }
    }

    private void ToggleEnabled()
    {
        _enabled = !_enabled;
        if (_enabled)
        {
            _statusItem.Text = "状态: 运行中";
            _toggleItem.Text = "暂停监听";
            _notifyIcon.Text = $"{AppName}: 运行中";
        }
        else
        {
            _statusItem.Text = "状态: 已暂停";
            _toggleItem.Text = "继续监听";
            _notifyIcon.Text = $"{AppName}: 已暂停";
        }
    }

    private void SetSaveDirectory()
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "选择截图保存目录",
            UseDescriptionForTitle = true,
            SelectedPath = _config.SaveDirectory,
            ShowNewFolderButton = true
        };

        if (dialog.ShowDialog() != DialogResult.OK)
        {
            return;
        }

        _config.SaveDirectory = dialog.SelectedPath;
        EnsureSaveDirectory();
        SaveConfig();
    }

    private void EnsureSaveDirectory()
    {
        if (string.IsNullOrWhiteSpace(_config.SaveDirectory))
        {
            _config.SaveDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "SnipasteShots");
        }

        Directory.CreateDirectory(_config.SaveDirectory);
    }

    private void OpenSaveDirectory()
    {
        EnsureSaveDirectory();
        System.Diagnostics.Process.Start("explorer.exe", _config.SaveDirectory);
    }

    private void CopyLastPath()
    {
        Clipboard.SetText(string.IsNullOrWhiteSpace(_lastSavedPath) ? "尚无保存记录" : _lastSavedPath);
    }

    private bool IsStartupEnabled()
    {
        var startupLnk = GetStartupShortcutPath();
        return File.Exists(startupLnk);
    }

    private void ToggleStartup()
    {
        var startupLnk = GetStartupShortcutPath();
        if (File.Exists(startupLnk))
        {
            File.Delete(startupLnk);
            return;
        }

        var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!);
        dynamic shortcut = shell!.GetType().InvokeMember("CreateShortcut", System.Reflection.BindingFlags.InvokeMethod, null, shell, [startupLnk]);
        shortcut.TargetPath = Application.ExecutablePath;
        shortcut.WorkingDirectory = AppContext.BaseDirectory;
        shortcut.IconLocation = Application.ExecutablePath;
        shortcut.Description = AppName;
        shortcut.Save();
    }

    private static string GetStartupShortcutPath()
    {
        var startupDir = Environment.GetFolderPath(Environment.SpecialFolder.Startup);
        return Path.Combine(startupDir, "截图监听助手.lnk");
    }

    private static Icon BuildTrayIcon()
    {
        var bmp = new Bitmap(64, 64);
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);
            using var bgBrush = new SolidBrush(Color.FromArgb(34, 128, 255));
            g.FillEllipse(bgBrush, 4, 4, 56, 56);
            using var pen = new Pen(Color.White, 5)
            {
                StartCap = System.Drawing.Drawing2D.LineCap.Round,
                EndCap = System.Drawing.Drawing2D.LineCap.Round
            };
            g.DrawLine(pen, 22, 24, 44, 40);
            g.DrawLine(pen, 44, 24, 22, 40);
            using var ringPen = new Pen(Color.White, 4);
            g.DrawEllipse(ringPen, 12, 14, 12, 12);
            g.DrawEllipse(ringPen, 40, 14, 12, 12);
        }

        var hIcon = bmp.GetHicon();
        try
        {
            return (Icon)Icon.FromHandle(hIcon).Clone();
        }
        finally
        {
            NativeMethods.DestroyIcon(hIcon);
            bmp.Dispose();
        }
    }

    private AppConfig LoadConfig()
    {
        try
        {
            if (!File.Exists(_configPath))
            {
                return AppConfig.Default();
            }

            var json = File.ReadAllText(_configPath);
            return JsonSerializer.Deserialize<AppConfig>(json) ?? AppConfig.Default();
        }
        catch
        {
            return AppConfig.Default();
        }
    }

    private void SaveConfig()
    {
        Directory.CreateDirectory(_configDir);
        var json = JsonSerializer.Serialize(_config, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(_configPath, json);
    }

    private void ExitApp()
    {
        _timer.Stop();
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        ExitThread();
    }
}

internal sealed class AppConfig
{
    public string SaveDirectory { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "SnipasteShots");

    public static AppConfig Default() => new();
}

internal static class NativeMethods
{
    [DllImport("user32.dll")]
    public static extern uint GetClipboardSequenceNumber();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr hIcon);
}
