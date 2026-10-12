# Garden Incremental Backlog

Ideas and known gaps to revisit as the game grows. Check items off when they are implemented.

## Current gaps

- [ ] **Reward crop quality or growth stage on harvest.** Harvesting currently adds one crop regardless of its growth stage, so reaching later stages does not improve the reward.
- [ ] **Make robot queues responsive to new work.** The robot currently finishes its queued work before considering new actions; allow urgent work to be added without waiting for an unnecessarily long queue.
- [ ] **Review the robot's idle/movement state.** Remove the unused `to_idle` parameter and make sure idle status stays correct when queued actions are added or discarded.
- [ ] **Finish crop inventory interactions.** Decide what selecting a crop in the inventory should do; its button callback is currently empty.
- [ ] **Display transaction feedback.** Show clear UI feedback when a purchase or sale succeeds or fails, rather than relying on errors/log output.

## Recommended additions

- [ ] **Save and load game progress.** Persist money, seeds, harvested crops, plot crops and growth stages, soil modifiers, and relevant settings.
- [ ] **Add a garden expansion upgrade.** Let players spend money to unlock additional plots, and update plot lookup, rendering, and robot movement to support a variable garden size.
- [ ] **Add automation upgrades.** Give players progression choices such as faster robot movement, shorter action time, increased growth chance, or larger seed-buy batches.
- [ ] **Add crop-specific growth and economy data.** Keep growth time, seed cost, sell value, and harvest rewards together per crop so new crops are easier to add and balance.
- [ ] **Show crop growth progress in the UI.** Make each crop's current stage and readiness clear without relying only on its garden tile.
- [ ] **Add modifier-specific visual layers.** Render wet and fertilized soil independently so plots can show any combination of modifiers and new modifiers can add their own layer.
- [ ] **Add automated tests for core actions.** Cover seed selection while actions are queued, inventory limits, duplicate soil modifiers, growth, harvesting, and buying/selling.
- [ ] **Add a settings panel.** Let players pause automation, adjust tick speed, and configure which crops and soil modifiers the robot should use.

## Design notes

- Keep inventory and plot mutations in the player action handler so queued work is checked against the state that exists when it executes.
- When adding crop types or soil modifiers, update their data, UI identification, robot action handling, rendering, and tests together.
