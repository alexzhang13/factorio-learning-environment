from fle.env.tools import Tool


class Reward(Tool):
    def __init__(self, connection, game_state):
        super().__init__(connection, game_state)
        self.name = "score"
        self.game_state = game_state
        self.load()

    def __call__(self, *args, **kwargs):
        response, execution_time = self.execute(*args)
        if isinstance(response, str):
            raise Exception("Could not get player score", response)

        # Guard the "player" key BEFORE touching it: the score Lua can return a
        # dict without it (e.g. the "player" force has no production yet), and
        # subtracting initial_score before this check raised KeyError on every
        # step, failing the whole gym step and starving the agents of obs.
        if "player" not in response:
            response["player"] = 0

        if self.game_state.instance.initial_score:
            response["player"] -= self.game_state.instance.initial_score

        # Get automated production score (excludes harvested and manually crafted items)
        automated_score = response.get("automated", 0)

        return response["player"], automated_score
