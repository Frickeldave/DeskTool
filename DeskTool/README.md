# Enable Chromium engine

To enable DeskTool to use the chromium engine, you have to use this [guide](https://pode.readthedocs.io/en/latest/Tutorials/Misc/DesktopApp/#using-chromium-instead-of-internet-explorer). The documentation is a bit incomplete, so here is another try to describe that.

- Download CEFSharp redist from [https://www.nuget.org/packages/cef.redist.x64](https://www.nuget.org/packages/cef.redist.x64) and extract with 7zip
  - Copy the content of CEF (except pdb files and the locals directory) to lib\CefSharp
- Download CEFSharp WPF from [https://www.nuget.org/packages/cefsharp.wpf](https://www.nuget.org/packages/cefsharp.wpf) and extract with 7zip
  - Copy lib\net462\CefSharp.Wpf.dll to lib\CefSharp
- Download CEFSharp WPF from [https://www.nuget.org/packages/cefsharp.common](https://www.nuget.org/packages/cefsharp.common) and extract with 7zip
  - Copy the content of lib\CefSharp (except pdb files) to lib\CefSharp