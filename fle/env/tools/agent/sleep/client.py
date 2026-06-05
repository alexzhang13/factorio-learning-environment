from time import sleep, perf_counter
import threading

from fle.env.tools import Tool


class Sleep(Tool):
    # Thread-local storage for tracking accumulated sleep durations per step
    _local = threading.local()

    def __init__(self, connection, game_state):
        super().__init__(connection, game_state)

    @classmethod
    def reset_step_sleep_duration(cls):
        """Reset the accumulated sleep duration for a new step. Call before each step."""
        cls._local.step_sleep_duration = 0.0

    @classmethod
    def get_step_sleep_duration(cls) -> float:
        """Get the accumulated sleep duration for the current step in seconds."""
        return getattr(cls._local, "step_sleep_duration", 0.0)

    @classmethod
    def _add_sleep_duration(cls, duration: float):
        """Add to the accumulated sleep duration for the current step."""
        if not hasattr(cls._local, "step_sleep_duration"):
            cls._local.step_sleep_duration = 0.0
        cls._local.step_sleep_duration += duration

    def _tick(self):
        r = self.game_state.instance.rcon_client.send_command(
            "/silent-command rcon.print(game.tick)"
        )
        r = (r or "").strip()
        return int(r) if r.isdigit() else None

    def __call__(self, seconds: int) -> bool:
        """
        Advance the game ``seconds`` in-game seconds and wait for it to actually
        run. Used by throughput holdouts to measure sustained production.

        The old implementation just bumped a tick counter and slept in real time
        — which advanced the factory ZERO ticks whenever the game was paused
        (FLE pauses between steps), so a 300/60s factory measured ~0. This drives
        the game deterministically: force-unpause, poll ``game.tick`` until it has
        advanced ``seconds*60`` ticks (so the factory genuinely produces for the
        whole window), then restore the prior pause state.
        :param seconds: Number of in-game seconds to run.
        :return: True if the window completed.
        """
        # Keep FLE's elapsed_ticks counter consistent (used for Response.ticks).
        self.execute(seconds)

        target = int(seconds * 60)
        if target <= 0:
            return True

        inst = self.game_state.instance
        start = self._tick()
        if start is None:
            # Can't read ticks (RCON hiccup) — fall back to the old timed sleep.
            speed = inst.get_speed() or 1
            sleep(target / 60 / speed)
            Sleep._add_sleep_duration(target / 60 / speed)
            return True

        was_paused = (
            (self.game_state.instance.rcon_client.send_command(
                "/silent-command rcon.print(tostring(game.tick_paused))"
            ) or "").strip() == "true"
        )
        speed = inst.get_speed() or 10
        rcon = inst.rcon_client
        # FORCE the real game to run, regardless of the GameControl pause flag
        # (which can desync from the actual game.tick_paused — the bug that made
        # holdouts measure ~0). Also sync the flag via the instance method so the
        # env's own pause/unpause stays coherent for later steps.
        rcon.send_command(f"/silent-command game.tick_paused=false game.speed={speed}")
        try:
            inst.set_speed_and_unpause(speed)
        except Exception:  # noqa: BLE001
            pass

        t0 = perf_counter()
        deadline = t0 + target / 60 / speed + 20.0  # expected real time + slack
        while perf_counter() < deadline:
            cur = self._tick()
            if cur is not None and cur - start >= target:
                break
            sleep(0.1)
        Sleep._add_sleep_duration(perf_counter() - t0)

        if was_paused:  # restore prior pause state (raw + flag)
            rcon.send_command("/silent-command game.tick_paused=true")
            try:
                inst.pause()
            except Exception:  # noqa: BLE001
                pass
        return True
