using Android.App;
using Android.Content.PM;
using Android.OS;
using cs.ndll;
using Org.Libsdl.App;

namespace ::APP_PACKAGE::
{
    [Activity(Label = "::APP_TITLE::", Name="::APP_PACKAGE::.MainActivity",
        ConfigurationChanges = ConfigChanges.KeyboardHidden | ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.ScreenLayout,
        MainLauncher = true, Icon = "@drawable/icon")]
    public class MainActivity : Org.Haxe.Lime.GameActivity
    {
        class MainRunnable : Java.Lang.Object, Java.Lang.IRunnable
        {
            public void Run()
            {
                NDLLFunction.LibraryDir = MainActivity.MSingleton.ApplicationInfo.NativeLibraryDir;
                NDLLFunction.LibraryPrefix = "lib";
                NDLLFunction.LibrarySuffix = ".so";
                
                Java.Lang.String[] arguments = {};
                SDLActivity.NativeInit(arguments);
                ApplicationMain.main();
            }
        }

        public override Java.Lang.IRunnable CreateRunnable()
        {
            return new MainRunnable();
        }
    }
}

