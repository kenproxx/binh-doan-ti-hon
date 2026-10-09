import json, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class DataTests(unittest.TestCase):
 def test_complete_campaign_contract(self):
  stages=json.loads((ROOT/'data/stages.json').read_text())
  units=json.loads((ROOT/'data/units.json').read_text())
  self.assertEqual(len(stages),30)
  self.assertEqual(len(units),6)
  self.assertEqual([s['id'] for s in stages],list(range(1,31)))
  self.assertEqual({s['objective'] for s in stages},{'destroy','hold','capture','survive'})
  self.assertEqual(len({(s['chapter'],tuple(s['bridges']),s['objective'],tuple(s['enemy_roster']),s['seed']) for s in stages}),30)
  for s in stages:
   self.assertTrue(all(x in units for x in s['enemy_roster']))
   self.assertTrue(180<=s['time_limit']<=300)
   self.assertTrue(s['bridges'])
   self.assertTrue(s['income']==s['enemy_income'])
 def test_costs_roles_and_translation(self):
  units=json.loads((ROOT/'data/units.json').read_text())
  upgrades=json.loads((ROOT/'data/upgrades.json').read_text())
  self.assertEqual(len({u['role'] for u in units.values()}),6)
  for k,u in units.items():
   self.assertGreater(u['cost'],0)
   self.assertGreater(u['hp'],0)
   self.assertEqual(len(upgrades[k]),5)
  strings=json.loads((ROOT/'data/strings.json').read_text())
  self.assertEqual(set(strings['vi']),set(strings['en']))
if __name__=='__main__': unittest.main()
