# VisualJCMD

GUI [jcmd](https://docs.oracle.com/javase/jp/10/tools/jcmd.htm) tool for Windows.

# How to compile

You can build this source on Delphi 10.2.
(I use Community Edition)

# How to use

1. Deploy `VisualJCmd.exe` and `VisualJCmdStub.dll` to same directory.
2. Run `VisualJCmd.exe`
3. Select Java process to attach
4. Check PerfCounter or choose command which you want to run
5. If you want to run JCmd, you need to double-click on the command, and push `Invoke` button after option configuration.

# Known issues

* Can not detect process status change
    * Cannot list new process which starts after VisualJCMD
    * We may use [FindFirstChangeNotification](https://docs.microsoft.com/en-us/windows/desktop/api/FileAPI/nf-fileapi-findfirstchangenotificationa) for it.
* Cannot attach VisualJCMD to JDK 11 EA

# License

GPLv2
