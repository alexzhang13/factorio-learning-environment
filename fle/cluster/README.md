# Local Factorio Cluster

This directory contains scripts and configuration files for running and managing multiple Factorio game servers locally using Docker containers.

## Overview

The system allows you to:

- Create and manage multiple Factorio server instances using Docker
- Automatically connect to and initialize each server instance
- Configure server settings, ports, and resources for each instance
- Share scenarios across instances
- Choose between different scenarios (open_world or default_lab_scenario)

## `fle cluster`

- Main CLI for generating compose yaml
- Running and managing Factorio instances with options for scenario selection

## `run-envs.sh`

 - Legacy script for generating compose yaml
 - Prefer `fle cluster` for new local development

## Setup and Usage

### Prerequisites

- Docker installed and running
- Optional: Factorio game client installed locally

### Managing Server Instances with `fle cluster`

The `fle cluster` command provides a convenient way to start, stop, and manage Factorio server instances.

#### Basic Usage

```bash
# Start a single instance with default settings (default_lab_scenario)
fle cluster start

# Start 5 instances with default scenario
fle cluster start -n 5

# Start 3 instances with open_world scenario
fle cluster start -n 3 -s open_world

# Stop all running instances
fle cluster stop

# Restart the current cluster with the same configuration
fle cluster restart

# Show help information
fle cluster help
```

#### Command Line Options

- `-n NUMBER` - Number of Factorio instances to run (1-33, default: 1)
- `-s SCENARIO` - Scenario to run (open_world or default_lab_scenario, default: default_lab_scenario)

#### Available Commands

- `start` - Start Factorio instances (default command)
- `stop` - Stop all running instances
- `restart` - Restart the current cluster with the same configuration
- `help` - Show help information

#### Examples with Explicit Commands

```bash
# Start 10 instances with open_world scenario
fle cluster start -n 10 -s open_world

# Restart the current cluster
fle cluster restart
```


### Server Configuration

Each Factorio instance is configured with:

- Resource limits: 1 CPU core and 1024MB memory
- Shared scenarios directory
- Unique UDP port for game traffic (starting at 34197)
- Unique TCP port for RCON (starting at 27015)
- Choice of scenario (open_world or default_lab_scenario)

### Multiplayer Access Lists

Cluster startup creates a writable runtime config directory under the FLE state directory and mounts it into each container. Seed multiplayer clients and subagents with comma-separated environment variables before starting the cluster:

```bash
FLE_FACTORIO_WHITELIST="spectator,subagent-1,subagent-2" \
FLE_FACTORIO_ADMINS="admin" \
fle cluster start -n 3
```

The generated access-list files are preserved across restarts and merged with later environment-variable values instead of replaced.

## Port Mappings

- Game ports (UDP): 34197 + instance_number
- RCON ports (TCP): 27000 + instance_number

## Volume Mounts

The following directories are mounted in each container:

- Scenarios: `../scenarios/default_lab_scenario`, `../scenarios/open_world`
- Mods: `~/Applications/Factorio.app/Contents/Resources/mods`
- Runtime config: `<state_dir>/config`
- Saves: `<state_dir>/saves`
- Screenshots: `../../data/_screenshots`

## Notes

- The server instances use the `factorio:latest` Docker image (which you can build from the provided Dockerfile in the `docker` directory)
- Each instance can run with either the `default_lab_scenario` or `open_world` scenario
- RCON password is set to "factorio"
- Containers are configured to restart unless stopped manually

## Troubleshooting

If you encounter issues:

1. Ensure Docker is running and has sufficient resources
2. Check container logs using `docker logs factorio_<instance_number>`
3. Verify port availability using `netstat` or similar tools
