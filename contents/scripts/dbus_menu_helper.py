#!/usr/bin/env python3
import sys
import dbus
import json

STANDARD_PREF_ICONS = {
    "configure",
    "preferences-system",
    "preferences-other",
    "settings-configure",
    "preferences-desktop",
}

PRUNABLE_MENUS = {
    "view", "window", "windows", "go", "bookmarks", "history", "navigation"
}

def normalize_label(label):
    if not label:
        return ""
    cleaned = (
        str(label)
        .replace("&", "")
        .replace("_", "")
        .replace("~", "")
        .replace("\u2026", "")
        .replace(".", "")
    )
    return " ".join(cleaned.split()).lower()

def score_candidate(properties, clean_label, parent_label, depth, app_name):
    # Check if toggleable action
    toggle_type = str(properties.get("toggle-type", "")).strip().lower()
    if toggle_type in ("checkmark", "radio"):
        return -100

    icon_name = str(properties.get("icon-name", "")).strip().lower()
    norm_app = app_name.strip().lower() if app_name else ""

    is_exact_keyword = clean_label in ("preferences", "settings", "options", "configure")
    is_app_configure = bool(norm_app and (clean_label == f"configure {norm_app}" or clean_label.startswith(f"configure {norm_app} ")))
    is_app_prefs = bool(norm_app and clean_label in (f"{norm_app} preferences", f"{norm_app} settings", f"{norm_app} options"))
    starts_configure = clean_label.startswith("configure ")
    ends_prefs = clean_label.endswith(" preferences") or clean_label.endswith(" settings") or clean_label.endswith(" options")
    has_pref_icon = icon_name in STANDARD_PREF_ICONS

    if not (is_exact_keyword or is_app_configure or is_app_prefs or starts_configure or ends_prefs or has_pref_icon):
        return -100

    score = 0
    words = clean_label.split()

    if is_app_configure or is_app_prefs:
        score += 100
    elif is_exact_keyword:
        score += 90
    elif starts_configure:
        score += 40
        if len(words) == 2:
            score += 20
        elif len(words) > 3:
            score -= 40
    elif ends_prefs:
        score += 30
        if len(words) > 3:
            score -= 40

    if has_pref_icon:
        score += 30

    # Parent context
    if parent_label in ("settings", "preferences"):
        score += 30
    elif parent_label in ("tools", "edit", "file"):
        score += 20
    elif parent_label in ("view", "window", "help"):
        score -= 50

    # Depth context
    if depth == 2:
        score += 20
    elif depth > 2:
        score -= 40

    return score

def score_about(properties, clean_label, parent_label, depth, app_name):
    norm_app = app_name.strip().lower() if app_name else ""

    if norm_app and (clean_label == f"about {norm_app}" or clean_label.startswith(f"about {norm_app} ")):
        score = 100
    elif clean_label == "about":
        score = 90
    elif clean_label in ("about kde", "about qt"):
        score = 10
    elif clean_label.startswith("about "):
        score = 60
    else:
        return -100

    if parent_label == "help":
        score += 20
    if depth == 2:
        score += 10
    elif depth > 2:
        score -= 20

    return score

def find_menu_items(item_tuple, app_name="", parent_label="", depth=0):
    item_id, properties, children = item_tuple
    raw_label = str(properties.get("label", ""))
    clean_label = normalize_label(raw_label)
    
    # Prune irrelevant top-level branches
    if depth == 1 and clean_label in PRUNABLE_MENUS:
        return None, None

    is_leaf = len(children) == 0 and str(properties.get("children-display", "")) != "submenu"

    best_about = None
    best_prefs = None

    if is_leaf:
        p_score = score_candidate(properties, clean_label, parent_label, depth, app_name)
        if p_score >= 60:
            icon_name = str(properties.get("icon-name", "")).strip().lower()
            best_prefs = (p_score, item_id, clean_label, icon_name)

        a_score = score_about(properties, clean_label, parent_label, depth, app_name)
        if a_score >= 50:
            best_about = (a_score, item_id, clean_label)

    current_parent_label = clean_label if not is_leaf and depth > 0 else parent_label

    for child in children:
        child_about, child_prefs = find_menu_items(child, app_name, current_parent_label, depth + 1)
        if child_about and (best_about is None or child_about[0] > best_about[0]):
            best_about = child_about
        if child_prefs and (best_prefs is None or child_prefs[0] > best_prefs[0]):
            best_prefs = child_prefs

    return best_about, best_prefs

def main():
    if len(sys.argv) < 4:
        sys.exit(1)
        
    action = sys.argv[1] # "check" or "trigger"
    service = sys.argv[2]
    path = sys.argv[3]
    
    app_name = ""
    if action == "check" and len(sys.argv) > 4:
        app_name = sys.argv[4]
        
    try:
        bus = dbus.SessionBus()
        obj = bus.get_object(service, path)
        interface = dbus.Interface(obj, 'com.canonical.dbusmenu')
        
        if action == "trigger":
            if len(sys.argv) < 5:
                sys.exit(1)
            target = sys.argv[4] # "about", "prefs", or integer ID
            target_id = None
            
            if target.isdigit():
                target_id = int(target)
            elif len(sys.argv) > 5 and sys.argv[5].isdigit():
                target_id = int(sys.argv[5])
            else:
                if len(sys.argv) > 5 and not sys.argv[5].isdigit():
                    app_name = sys.argv[5]
                elif len(sys.argv) > 6:
                    app_name = sys.argv[6]
                revision, layout = interface.GetLayout(0, -1, ["label", "icon-name", "toggle-type", "children-display"])
                best_about, best_prefs = find_menu_items(layout, app_name)
                target_id = best_about[1] if (target == "about" and best_about) else (best_prefs[1] if best_prefs else None)
            
            if target_id is not None:
                try:
                    interface.Event(target_id, "clicked", dbus.String("", variant_level=1), 0)
                except Exception:
                    # Fallback for legacy apps
                    interface.Event(target_id, "clicked", "", 0)
                print("SUCCESS")
                sys.exit(0)
            else:
                print("NOT_FOUND")
                sys.exit(1)
                
        elif action == "check":
            revision, layout = interface.GetLayout(0, -1, ["label", "icon-name", "toggle-type", "children-display"])
            best_about, best_prefs = find_menu_items(layout, app_name)
            
            has_about = best_about is not None
            about_id = best_about[1] if best_about else None
            
            has_prefs = best_prefs is not None
            prefs_id = best_prefs[1] if best_prefs else None
            prefs_label = "Preferences"
            
            if best_prefs:
                clean_lbl = best_prefs[2]
                icon = best_prefs[3]
                if "setting" in clean_lbl or "setting" in icon:
                    prefs_label = "Settings"
                elif "configure" in clean_lbl or "configure" in icon:
                    prefs_label = "Configure"
                elif "option" in clean_lbl:
                    prefs_label = "Options"
                else:
                    prefs_label = "Preferences"
                    
            print(json.dumps({
                "has_about": has_about,
                "about_id": about_id,
                "has_prefs": has_prefs,
                "prefs_id": prefs_id,
                "prefs_label": prefs_label
            }))
            sys.exit(0)
            
    except Exception as e:
        sys.stderr.write(f"dbus_menu_helper error: {e}\n")
        if action == "check":
            print(json.dumps({"has_about": False, "about_id": None, "has_prefs": False, "prefs_id": None, "prefs_label": "Preferences"}))
        else:
            print("ERROR")
        sys.exit(2)

if __name__ == "__main__":
    main()

