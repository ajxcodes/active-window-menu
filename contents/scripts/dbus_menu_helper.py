#!/usr/bin/env python3
import sys
import dbus
import json

def find_keywords(item_tuple, found_about, found_prefs, about_id, prefs_id, prefs_label):
    item_id, properties, children = item_tuple
    
    label = str(properties.get("label", "")).lower()
    icon_name = str(properties.get("icon-name", "")).lower()
    
    # Strip accelerators and dots
    clean_label = label.replace("&", "").replace("_", "").replace(".", "").strip()
    
    is_leaf = len(children) == 0 and str(properties.get("children-display", "")) != "submenu"
    
    if is_leaf:
        # Check for About
        if not found_about and (clean_label.startswith("about ") or clean_label == "about"):
            found_about = True
            about_id = item_id
            
        # Check for Preferences / Settings
        if not found_prefs:
            exclusions = ["printer", "page", "shortcut", "toolbar", "notification", "event", "plugin", "extension"]
            if not any(excl in clean_label for excl in exclusions):
                if ("preferences" in clean_label or 
                    "settings" in clean_label or 
                    "options" in clean_label or 
                    clean_label.startswith("configure ") or
                    clean_label == "configure" or
                    "preferences" in icon_name or 
                    "configure" in icon_name):
                    
                    found_prefs = True
                    prefs_id = item_id
                    
                    if "setting" in clean_label or "setting" in icon_name:
                        prefs_label = "Settings"
                    elif "configure" in clean_label or "configure" in icon_name:
                        prefs_label = "Configure"
                    elif "options" in clean_label:
                        prefs_label = "Options"
                    else:
                        prefs_label = "Preferences"

    for child in children:
        # If we found both, we can stop traversing early
        if found_about and found_prefs:
            break
        found_about, found_prefs, about_id, prefs_id, prefs_label = find_keywords(child, found_about, found_prefs, about_id, prefs_id, prefs_label)
            
    return found_about, found_prefs, about_id, prefs_id, prefs_label

def main():
    if len(sys.argv) < 4:
        sys.exit(1)
        
    action = sys.argv[1] # "check" or "trigger"
    service = sys.argv[2]
    path = sys.argv[3]
    
    try:
        bus = dbus.SessionBus()
        obj = bus.get_object(service, path)
        interface = dbus.Interface(obj, 'com.canonical.dbusmenu')
        
        # Get full layout: parentId=0, recursionDepth=-1, propertyNames=["label", "icon-name"]
        revision, layout = interface.GetLayout(0, -1, ["label", "icon-name"])
        
        has_about, has_prefs, about_id, prefs_id, prefs_label = find_keywords(layout, False, False, None, None, "Preferences")
        
        if action == "check":
            print(json.dumps({
                "has_about": has_about,
                "has_prefs": has_prefs,
                "prefs_label": prefs_label
            }))
            sys.exit(0)
            
        elif action == "trigger":
            if len(sys.argv) < 5:
                sys.exit(1)
            target = sys.argv[4] # "about" or "prefs"
            target_id = about_id if target == "about" else prefs_id
            
            if target_id is not None:
                try:
                    interface.Event(target_id, "clicked", dbus.String("", variant_level=1), 0)
                except Exception as e:
                    # Fallback for legacy apps
                    interface.Event(target_id, "clicked", "", 0)
                print("SUCCESS")
                sys.exit(0)
            else:
                print("NOT_FOUND")
                sys.exit(1)
                
    except Exception as e:
        if action == "check":
            print(json.dumps({"has_about": False, "has_prefs": False, "prefs_label": "Preferences"}))
        else:
            print("ERROR")
        sys.exit(2)

if __name__ == "__main__":
    main()
