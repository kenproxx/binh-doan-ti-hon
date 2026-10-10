# Review — lịch sử 0.1.0 và cập nhật 0.2.0

Các nhận định về thời lượng/bản Android trong phần review cũ phía dưới thuộc 0.1.0. Kết quả hiện hành ở docs/testing.md và phần cập nhật cuối.

# Independent gameplay and persistence review

Reviewed Godot 4.4.1 source, JSON content, the executable simulation, and real `main.tscn` Controls. Reviewer changed only this report and `tests/test_acceptance.gd`.

## Evidence and scope

Run from the repository root:

```sh
/tmp/godot/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script tests/test_battle.gd
/tmp/godot/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script tests/test_profile.gd
/tmp/godot/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script tests/test_acceptance.gd
python tests/test_data.py
```

The original battle and profile tests and Python data tests pass. The latest acceptance run also passes with zero failures and no shutdown warnings after audio cleanup. Acceptance tests exercise a genuine 30-stage campaign from a fresh 200-gold profile: unlocked roster only, no more than four cards, ordinary deployment positions/resources/cooldowns, no edited HP/resources, only affordable upgrades bought with earned gold, and result settlement/reload after every victory. The initial observed campaign won all 30 stages in 27.3–51.2 simulated seconds each with three stars. This proves a reachable winning progression for the tested deterministic seeds and tactic; it does not establish adequate difficulty or 3–5-minute match duration.

The tactic checks cards every 0.5s, deploys near the forward edge of the legal base radius, uses captured-point deployment, keeps up to two medics, and targets bomb at the densest visible enemy group. It is stronger than casual play but uses actions available in the UI. Capture stages finish by actual reachable-point ownership. Many hold/survive stages finish by destroying the enemy base, which the design explicitly permits.

Real-scene acceptance exercises main menu, campaign, army, upgrade, settings, reset cancellation, help, locked stage/unit controls, the four-card selection limit, battlefield deployment, attack/defend/rally, skill targeting, background pause, resume, restart, leave, victory settlement, next-stage navigation, and stage 1–4 deploy/command/skill/capture tutorial completion. Button signals and battlefield target signals are invoked programmatically; this is not proof of physical Android touch geometry or gesture feel. Those require the separate device/emulator work.

Save tests cover locked upgrade rejection, duplicate transaction after reload, corrupt-primary and future-schema recovery from a valid backup, and failed durable upgrades/rewards rolling back both gold and token. A terminal-result fixture additionally isolates storage failure on the result screen and requires an explicit retry that commits once after storage is restored. This fixture does not replace the real battles above.

## Findings

- **High: initial balance does not deliver 3–5-minute battles.** Reproduction: run the progressive acceptance campaign. All 30 initial stages win in under one minute; no player base takes damage. `scripts/battle_sim.gd` originally deployed one AI unit per decision (`_ai`, originally lines 295–332), while rapid player spending, upgraded units, and forward deployments overwhelm the unupgraded AI. Stage `time_limit` values 180/240/300 are upper bounds, not observed match durations. A subsequent AI tuning snapshot also passes all 30 stages in 25.3–46.3 seconds; it still does not meet duration. Further measured tuning results must replace these baselines before claiming duration is met.
- **Medium, corrected during review: failed result persistence was cached as settled.** Original `scripts/main.gd:474–480` cached reward 0 even when `Profile.settle` rolled back after a failed save. Reproduction: render a won result with a nonexistent storage parent, restore the valid directory, render again; token stayed absent and coins stayed 200. The UI now caches only durable transactions and exposes `RetrySaveButton`. Acceptance regression requires a retry to produce 388 gold once.
- **Medium, corrected during review: quality applied only after later navigation.** `main.gd` `_toggle_quality` originally saved the setting without calling `Audio.apply_settings`. Acceptance now checks that pressing `QualityButton` immediately changes `Engine.max_fps` to 30.
- **Medium, corrected during review: skill audio/vibration used deployment cue.** `_world_tapped` changed the target action back to deploy before choosing its cue, preventing the skill cue and corresponding vibration. The UI now preserves the action for audio selection and routes combat effects to hit/attack cues.
- **Low: headless shutdown emits ObjectDB/resource warnings.** Original tests showed one retained resource; longer UI acceptance showed several. Test cleanup stops audio streams and waits a frame/timer; the latest acceptance run exits without these warnings. These warnings are not evidence of steady-state Android memory behavior.

## Limits and release decision

No unresolved blocking deployment, campaign unlock, reward duplication, locked-upgrade, or tutorial-action failure was found in the tested paths. The existing focused battle tests cover all timeout objectives, tie loss, simultaneous base destruction, contested capture pause, and terminal idempotence; these use isolated fixtures appropriately.

Thirty deterministic wins do not prove every loadout/seed is balanced. Touch hit areas, drag-versus-tap, safe-area geometry, real Android lifecycle, signing/installability, sustained device memory, and measured phone FPS are outside this headless review. Do not present these tests as Android 60 FPS validation or as proof the requested match duration is met.

## Final source snapshot — independent rerun

Reran all six suites after final UI/content/audio changes with Godot 4.4.1: `test_audio.gd`, `test_ui.gd`, `test_battle.gd`, `test_profile.gd`, `test_acceptance.gd`, and Python `test_data.py`. Every process returned exit 0; battle/profile/acceptance reported zero failures, audio/UI reported PASS, and Python reported two passing tests. Audio, UI, profile, and acceptance logs had no error or warning. The focused battle suite still reports an ObjectDB leak and one retained resource at shutdown, despite zero functional failures.

The final progression again wins **30/30** genuine battles, with **32.7–186.8 seconds**, **median 95.05 seconds**, and **29/30 below 180 seconds**. Stage 1–4 retain full movement speed for tutorials; later stages use movement scale 0.35 and symmetric base defenses (28 damage, 1s interval, 165 range). Income remains 8/s for each side. These explicit shared rules improve resistance without secret enemy stat boosts, but the observed distribution still does not meet the requested 3–5-minute duration. This remains a high-severity requirement gap and must be disclosed with the deliverable.

Final source inspection confirms Vietnamese locale initialization, looping menu/battle WAVs, sticky preparation start controls, the compact pause control, and clipped three-line deployment cards. `test_ui.gd` checks the four cards and pause control against the actual viewport safe edge, and the help/objective text now says hold requires both stations, matching `BattleSim._capture` and `_resolve`. The audio suite verifies looping and music/quality settings. The parent separately rendered the 480×854 game with Xvfb. This reviewer attempted an independent rendered rerun, but X11 display access failed in the review tool sandbox; the independent UI execution here was headless.

No new blocking campaign, deployment, tutorial, reward, or upgrade defect was found. One low-severity messaging issue remains: after a failed save followed by successful result retry, `Profile.notice` retains the prior failure message because successful `save_profile`/`_commit` does not clear it. The reward/token commits correctly; the remaining warning can mislead the player about whether saving succeeded.

This final review does not validate APK export/signing/installability, Android touch interaction, physical-device lifecycle, sustained memory, or measured phone FPS. In particular, the `Engine.max_fps` setting and desktop/headless tests are not measurements of 60 FPS on Android. No Android readiness claim follows from this review.

Parent final corrections: successful durable `_commit` now clears the old save-failure notice; a regression was observed red, then passed. Latest parent full six-suite run exits 0 without shutdown errors. Rendered four-card snapshot after the fix shows every card and Pause within the 480px viewport. Android source template restored and ZIP verified; final APK hash is recorded in testing.md. These checks do not close the Android install/FPS or duration gaps.


## Review độc lập bản0.2.0

Không phát hiện Critical. Ba Important: tài liệu cũ; smoke PID không chứng minh UI còn phản hồi; acceptance chưa thử Phá thành. Đã cập nhật thiết kế/báo cáo; smoke yêu cầu cảm ứng thật đổi setting và kiểm tra durable state sau lifecycle; thêm chiến dịch `--siege`,30/30 thắng với các ải thường194–300.1s. Minor catalogue English “one post” đã sửa thành “both posts”. Android CI chưa chạy lúc review, không được công nhận nghiệm thu thiết bị.
