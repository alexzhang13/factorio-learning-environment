import json
from pathlib import Path

import pytest
import yaml

from fle.cluster.run_envs import ComposeGenerator


@pytest.fixture(autouse=True)
def _reset_between_tests():
    yield


def test_compose_generator_mounts_runtime_config_and_saves(tmp_path, monkeypatch):
    state_dir = tmp_path / "state"
    work_dir = tmp_path / "work"
    compose_path = state_dir / "docker-compose.yml"

    monkeypatch.setenv("FLE_FACTORIO_WHITELIST", "spectator,subagent-1")
    monkeypatch.setenv("FLE_FACTORIO_ADMINS", "admin,subagent-admin")

    generator = ComposeGenerator(state_dir=state_dir, work_dir=work_dir)
    generator.write(str(compose_path), 1)

    compose = yaml.safe_load(compose_path.read_text())
    service = compose["services"]["factorio_0"]
    volumes_by_target = {volume["target"]: volume for volume in service["volumes"]}

    assert volumes_by_target["/opt/factorio/config"]["source"] == str(
        state_dir / "config"
    )
    assert volumes_by_target["/opt/factorio/saves"]["source"] == str(
        state_dir / "saves"
    )
    assert (state_dir / "saves").is_dir()
    assert json.loads((state_dir / "config" / "server-whitelist.json").read_text()) == [
        "spectator",
        "subagent-1",
    ]
    assert json.loads((state_dir / "config" / "server-adminlist.json").read_text()) == [
        "admin",
        "client_master",
        "subagent-admin",
    ]
    assert json.loads((state_dir / "config" / "server-banlist.json").read_text()) == []


def test_default_lab_story_table_is_not_serialized_in_storage():
    source = Path("fle/cluster/scenarios/default_lab_scenario/freeplay.lua")
    text = source.read_text()

    assert "storage.story_table" not in text
    assert "story_init_helpers(story_table)" in text
