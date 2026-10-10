import unittest
from tools.android_ui import immersive_confirm_center

class AndroidUiTests(unittest.TestCase):
    def test_system_confirmation_uses_observed_bounds(self):
        xml = '<hierarchy><node package="com.android.systemui" text="Got it" bounds="[360,220][440,280]" /></hierarchy>'
        self.assertEqual(immersive_confirm_center(xml), (400, 250))

    def test_other_apps_and_absent_overlay_are_ignored(self):
        xml = '<hierarchy><node package="com.other.app" text="Got it" bounds="[0,0][100,100]" /></hierarchy>'
        self.assertIsNone(immersive_confirm_center(xml))
        self.assertIsNone(immersive_confirm_center('<hierarchy />'))
