#!/usr/bin/env python3
"""portal-shot.py — take a desktop screenshot through the XDG portal.

Wayland blocks direct screen capture; the portal is the supported path and is
the only capture method available without root. The result URI is printed.
Usage: portal-shot.py [--interactive]
"""
import sys
import time

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

interactive = "--interactive" in sys.argv

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

portal = Gio.DBusProxy.new_sync(
    bus,
    Gio.DBusProxyFlags.NONE,
    None,
    "org.freedesktop.portal.Desktop",
    "/org/freedesktop/portal/desktop",
    "org.freedesktop.portal.Screenshot",
    None,
)

result = {"uri": None, "code": None}


def on_signal(connection, sender_name, object_path, interface_name, signal_name, parameters):
    if signal_name != "Response":
        return
    code, values = parameters.unpack()
    result["code"] = code
    if code == 0:
        result["uri"] = values.get("uri")


sub_id = bus.signal_subscribe(
    sender="org.freedesktop.portal.Desktop",
    interface_name="org.freedesktop.portal.Request",
    member="Response",
    object_path=None,
    arg0=None,
    flags=Gio.DBusSignalFlags.NONE,
    callback=on_signal,
)

options = {"interactive": GLib.Variant("b", interactive)}

try:
    portal.call_sync(
        "Screenshot",
        GLib.Variant("(sa{sv})", ("", options)),
        Gio.DBusCallFlags.NONE,
        60000,
        None,
    )
except GLib.Error as exc:
    print("portal call failed:", exc)
    bus.signal_unsubscribe(sub_id)
    sys.exit(2)

loop = GLib.MainLoop()
GLib.timeout_add_seconds(20, loop.quit)
loop.run()
bus.signal_unsubscribe(sub_id)

if result["uri"]:
    print("URI:", result["uri"])
    sys.exit(0)
print("no screenshot; response code:", result["code"])
sys.exit(1)
