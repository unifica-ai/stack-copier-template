@task
def install_all_addons(c):
    """Install all addons mentioned in addons.yaml."""
    # Read addons.yaml to get all addons
    addons_path = Path(SRC_PATH, "addons.yaml")
    with open(addons_path) as f:
        addons_config = yaml.safe_load(f)

    # Collect all addon names
    addon_list = []
    for _, addons in addons_config.items():
        addon_list.extend(addons)

    # Add base modules
    modules_str = ",".join(addon_list)

    # Build the command
    cmd = (
        f"{DOCKER_COMPOSE_CMD} run --rm odoo --stop-after-init -i {modules_str}"
    )

    with c.cd(str(PROJECT_ROOT)):
        c.run(
            cmd,
            env=UID_ENV,
            pty=True,
        )
