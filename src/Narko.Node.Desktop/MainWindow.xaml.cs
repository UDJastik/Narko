using System;
using System.Windows;

namespace Narko.Node.Desktop;

public partial class MainWindow : Window
{
    private readonly Services.AutoUpdateService _autoUpdateService = new();

    public MainWindow()
    {
        InitializeComponent();
        AppendLog("Scaffold initialized.");
    }

    private void SimulateConnect_Click(object sender, RoutedEventArgs e)
    {
        StatusText.Text = "Connected (simulation)";
        HeartbeatText.Text = $"Last heartbeat: {DateTime.Now:yyyy-MM-dd HH:mm:ss}";
        AppendLog("Simulated node connection established.");
    }

    private async void CheckUpdate_Click(object sender, RoutedEventArgs e)
    {
        var result = await _autoUpdateService.CheckForUpdateAsync();
        AppendLog($"Auto-update placeholder: {result.Message}");
    }

    private void Exit_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private void AppendLog(string message)
    {
        LogBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
        LogBox.ScrollToEnd();
    }
}
