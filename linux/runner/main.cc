#include "my_application.h"

int main(int argc, char** argv) {
  // Disable GPU rendering before GTK or the Flutter engine initializes.
  // X11 avoids Wayland pointer-routing issues in Linux containers/VMs.
  g_setenv("GDK_BACKEND", "x11", TRUE);
  // This is the Linux embedder's renderer selector. The engine switch alone
  // does not replace the GTK OpenGL compositor.
  g_setenv("FLUTTER_LINUX_RENDERER", "software", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCHES", "3", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_1", "enable-software-rendering=true", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_2", "enable-impeller=false", TRUE);
  g_setenv("FLUTTER_ENGINE_SWITCH_3", "enable-flutter-gpu=false", TRUE);
  g_setenv("LIBGL_ALWAYS_SOFTWARE", "1", TRUE);
  g_setenv("GALLIUM_DRIVER", "llvmpipe", TRUE);
  g_print("Thought Circle platform check: GTK backend=x11; native "
          "renderer=software; GPU disabled; Mesa driver=llvmpipe.\n");

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
