"""Small parser for the Android system fullscreen education overlay."""
def immersive_confirm_center(xml):
    import re
    import xml.etree.ElementTree as ET
    for node in ET.fromstring(xml).iter('node'):
        if node.get('package') != 'com.android.systemui' or node.get('text') != 'Got it':
            continue
        match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
        if match:
            left, top, right, bottom = map(int, match.groups())
            return ((left + right) // 2, (top + bottom) // 2)
    return None

def launcher_anr_close_center(xml):
    import re
    import xml.etree.ElementTree as ET
    nodes = list(ET.fromstring(xml).iter('node'))
    if not any(n.get('package') == 'android' and n.get('text') == "Pixel Launcher isn't responding" for n in nodes):
        return None
    for node in nodes:
        if node.get('package') == 'android' and node.get('text') == 'Close app':
            match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
            if match:
                left, top, right, bottom = map(int, match.groups())
                return ((left + right) // 2, (top + bottom) // 2)
    return None
