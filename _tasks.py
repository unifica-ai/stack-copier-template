@task
def install_all_addons(c, database="devel"):
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
        f"{DOCKER_COMPOSE_CMD} run --rm odoo --stop-after-init "
        f"-d {database} "
        f"-i {modules_str}"
    )

    with c.cd(str(PROJECT_ROOT)):
        c.run(
            cmd,
            env=UID_ENV,
            pty=True,
        )
        
@task(
    help={"private_key": "Path to AGE private key file or '-' to read from stdin."},
)
def decrypt_secrets(c, private_key=None):
    """Decrypt SOPS-encrypted environment files in .docker directory."""
    docker_dir = PROJECT_ROOT / ".docker"

    if not docker_dir.exists():
        raise exceptions.ParseError(f"Error: {docker_dir} directory not found")

    # Set private key environment variable if provided
    env = {}
    if private_key:
        if private_key == "-":
            # Read from stdin
            import sys

            key_content = sys.stdin.read().strip()
            env["SOPS_AGE_KEY"] = key_content
        else:
            private_key_path = Path(private_key)
            if not private_key_path.exists():
                raise exceptions.ParseError(
                    f"Private key file not found: {private_key}"
                )
            env["SOPS_AGE_KEY_FILE"] = str(private_key_path)

    _logger.info("Decrypting environment files...")

    # Find and decrypt all .env.encrypted files
    encrypted_files = list(docker_dir.glob("*.env.encrypted"))
    if not encrypted_files:
        _logger.info("No encrypted files found.")
        return

    for encrypted_file in encrypted_files:
        decrypted_file = docker_dir / encrypted_file.name.replace(".encrypted", "")
        _logger.info(f"Decrypting {encrypted_file.name} -> {decrypted_file.name}...")

        try:
            with c.cd(str(docker_dir)):
                cmd = (
                    f"sops --input-type dotenv --output-type dotenv "
                    f"-d {encrypted_file.name}"
                )
                result = c.run(cmd, env=env, hide="stdout")
            decrypted_file.write_text(result.stdout)
            _logger.info(f"✓ Successfully decrypted to {decrypted_file.name}")
        except exceptions.UnexpectedExit:
            _logger.info(f"✗ Failed to decrypt {encrypted_file.name}")
            raise

    _logger.info("\nAll files decrypted successfully!")
    _logger.info("Docker Compose can now use the standard .env files.")


@task()
def encrypt_secrets(c):
    """Encrypt environment files in .docker directory with SOPS."""
    docker_dir = PROJECT_ROOT / ".docker"

    if not docker_dir.exists():
        raise exceptions.ParseError(f"Error: {docker_dir} directory not found")

    _logger.info("Encrypting environment files...")

    # Find and encrypt all .env files
    env_files = list(docker_dir.glob("*.env"))
    if not env_files:
        _logger.info("No .env files found to encrypt.")
        return

    for env_file in env_files:
        encrypted_file = docker_dir / f"{env_file.name}.encrypted"
        _logger.info(f"Encrypting {env_file.name} -> {encrypted_file.name}...")

        try:
            # Rename to match SOPS rule, encrypt in place, then done
            env_file.rename(encrypted_file)
            with c.cd(str(docker_dir)):
                cmd = (
                    f"sops --input-type dotenv --output-type dotenv "
                    f"-e -i {encrypted_file.name}"
                )
                c.run(cmd)
            _logger.info(f"✓ Successfully encrypted to {encrypted_file.name}")
        except exceptions.UnexpectedExit:
            _logger.info(f"✗ Failed to encrypt {env_file.name}")
            # Restore original name if encryption failed
            if encrypted_file.exists():
                encrypted_file.rename(env_file)
            raise

    _logger.info("\nAll files encrypted successfully!")
    _logger.info("Remember to commit the .encrypted files to git.")
